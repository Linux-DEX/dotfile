return {
	"nvim-telescope/telescope.nvim",
	cmd = "Telescope",
	version = false,
	dependencies = {
		{
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "make",
			config = function()
				require("telescope").load_extension("fzf")
			end,
		},
	},

	config = function()
		local telescope = require("telescope")
		local actions = require("telescope.actions")

		-- Trouble v3 compatible
		local open_with_trouble = function(prompt_bufnr)
			actions.close(prompt_bufnr)
			require("trouble").open({ mode = "telescope" })
		end

		local find_files_no_ignore = function(prompt_bufnr)
			local action_state = require("telescope.actions.state")
			local line = action_state.get_current_line()
			actions.close(prompt_bufnr)
			require("telescope.builtin").find_files({
				no_ignore = true,
				default_text = line,
			})
		end

		local find_files_with_hidden = function(prompt_bufnr)
			local action_state = require("telescope.actions.state")
			local line = action_state.get_current_line()
			actions.close(prompt_bufnr)
			require("telescope.builtin").find_files({
				hidden = true,
				default_text = line,
			})
		end

		local function find_command()
			if vim.fn.executable("rg") == 1 then
				return { "rg", "--files", "--color", "never", "-g", "!.git" }
			elseif vim.fn.executable("fd") == 1 then
				return { "fd", "--type", "f", "--color", "never", "-E", ".git" }
			elseif vim.fn.executable("fdfind") == 1 then
				return { "fdfind", "--type", "f", "--color", "never", "-E", ".git" }
			elseif vim.fn.executable("find") == 1 and vim.fn.has("win32") == 0 then
				return { "find", ".", "-type", "f" }
			elseif vim.fn.executable("where") == 1 then
				return { "where", "/r", ".", "*" }
			end
		end

		telescope.setup({
			defaults = {
        file_ignore_patterns = {
            "node_modules",
            ".venv",
            ".git", -- it's often useful to ignore .git as well
        },

				prompt_prefix = " ",
				selection_caret = " ",

				mappings = {
					i = {
						["<C-k>"] = actions.move_selection_previous, -- move to prev result
						["<C-j>"] = actions.move_selection_next, -- move to next result
						["<a-t>"] = open_with_trouble,
						["<a-i>"] = find_files_no_ignore,
						["<a-h>"] = find_files_with_hidden,
						["<C-Down>"] = actions.cycle_history_next,
						["<C-Up>"] = actions.cycle_history_prev,
						["<C-f>"] = actions.preview_scrolling_down,
						["<C-b>"] = actions.preview_scrolling_up,
					},
					n = {
						["q"] = actions.close,
					},
				},
			},

			pickers = {
				find_files = {
					find_command = find_command,
					hidden = true,
				},
			},
		})

		-- Keymaps
		local builtin = require("telescope.builtin")
		local keymap = vim.keymap.set

		keymap("n", "<leader>ff", builtin.find_files, { desc = "Find Files" })
		keymap("n", "<leader>fg", builtin.git_files, { desc = "Git Files" })
		keymap("n", "<leader>fr", builtin.oldfiles, { desc = "Recent Files" })
		keymap("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })
		keymap("n", "<leader>fs", builtin.live_grep, { desc = "Live Grep" })
		keymap("n", "<leader>fc", builtin.grep_string, { desc = "Grep String" })
		keymap("n", "<leader>fh", builtin.help_tags, { desc = "Help Tags" })
		keymap("n", "<leader>fk", builtin.keymaps, { desc = "Keymaps" })
		keymap("n", "<leader>fd", builtin.diagnostics, { desc = "Diagnostics" })
	end,
}

local telescope = require("telescope")
local actions = require("telescope.actions")

local open_with_trouble = function(prompt_bufnr)
	actions.close(prompt_bufnr)
	-- trouble.nvim is lazy-loaded: make sure it is available the first time
	local ok, trouble = pcall(require, "trouble")
	if not ok then
		pcall(vim.cmd.packadd, "trouble.nvim")
		ok, trouble = pcall(require, "trouble")
		if ok then
			pcall(trouble.setup, { focus = true })
		end
	end
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
		return {
			"rg", "--files", "--hidden", "--no-ignore-vcs",
			"--color", "never",
			"-g", "!.git",
			"-g", "!node_modules/**",
			"-g", "!.venv/**",
		}
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
		path_display = { "filename_first" },
		sorting_strategy = "ascending",
		layout_strategy = "horizontal",
		layout_config = {
			horizontal = {
				prompt_position = "top",
				preview_width = 0.55,
			},
			width = 0.87,
			height = 0.80,
			preview_cutoff = 120,
		},
		file_ignore_patterns = {
			"node_modules",
			".venv",
			".git",
		},
		prompt_prefix = "   ",
		selection_caret = "  ",
		mappings = {
			i = {
				["<C-k>"] = actions.move_selection_previous,
				["<C-j>"] = actions.move_selection_next,
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

-- Load fzf extension
pcall(telescope.load_extension, "fzf")

-- Keymaps are registered in lua/linuxdex/pack.lua (telescope is lazy-loaded
-- on first use: the keymap stubs packadd the plugin, configure it via
-- require("linuxdex.plugins.telescope"), then dispatch the command/action).

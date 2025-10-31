return {
  "nvim-telescope/telescope.nvim",
  branch = "0.1.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    "nvim-tree/nvim-web-devicons",
    "folke/todo-comments.nvim",
  },
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")
    local transform_mod = require("telescope.actions.mt").transform_mod
    local trouble = require("trouble")
    local trouble_telescope = require("trouble.sources.telescope")
    local action_set = require("telescope.actions.set")
    local action_state = require("telescope.actions.state")

    -- Custom actions
    local custom_actions = transform_mod({
      open_trouble_qflist = function(prompt_bufnr)
        trouble.toggle("quickfix")
      end,
    })

    telescope.setup({
      defaults = {
        path_display = { "smart" },
        mappings = {
          i = {
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-j>"] = actions.move_selection_next,
            ["<C-q>"] = actions.send_selected_to_qflist + custom_actions.open_trouble_qflist,
            ["<C-t>"] = trouble_telescope.open,
            -- Global <CR> mapping for other pickers
            ["<CR>"] = function(prompt_bufnr)
              local entry = action_state.get_selected_entry()
              local filepath = entry and (entry.path or entry.filename)
              actions.close(prompt_bufnr)
              if filepath then
                vim.cmd("tab drop " .. vim.fn.fnameescape(filepath))
              elseif entry and entry.bufnr then
                vim.cmd("buffer " .. entry.bufnr)
              end
            end,
          },
          n = {
            ["<CR>"] = function(prompt_bufnr)
              local entry = action_state.get_selected_entry()
              local filepath = entry and (entry.path or entry.filename)
              if vim.bo.modified then
                vim.cmd("update")  -- Save only if modified
              end
              actions.close(prompt_bufnr)
              if filepath then
                vim.cmd("tab drop " .. vim.fn.fnameescape(filepath))
              elseif entry and entry.bufnr then
                vim.cmd("buffer " .. entry.bufnr)
              end
            end,
          },
        },
      },
      pickers = {
        current_buffer_fuzzy_find = {
          mappings = {
            i = {
              ["<CR>"] = actions.select_default,
            },
            n = {
              ["<CR>"] = actions.select_default,
            },
          },
        },
      },
    })

    telescope.load_extension("fzf")

    -- Keymaps
    local keymap = vim.keymap
    keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Fuzzy find files in cwd" })
    keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Fuzzy find recent files" })
    keymap.set("n", "<leader>fs", "<cmd>Telescope live_grep<cr>", { desc = "Find string in cwd" })
    keymap.set("n", "<leader>fc", "<cmd>Telescope grep_string<cr>", { desc = "Find string under cursor in cwd" })
    keymap.set("n", "<leader>ft", "<cmd>TodoTelescope<cr>", { desc = "Find todos" })
    keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Find buffers" })
    keymap.set("n", "<leader>/", "<cmd>Telescope current_buffer_fuzzy_find<cr>", { desc = "Search in current buffer" })
    keymap.set("n", "<leader>fk", "<cmd>Telescope keymaps<cr>", { desc = "Search keymaps" })
    keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", { desc = "Search help tags" })
    keymap.set("n", "<leader>fgb", "<cmd>Telescope git_branches<cr>", { desc = "Git branches" })
  end,
}


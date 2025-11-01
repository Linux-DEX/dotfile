return {
  "nvim-telescope/telescope.nvim",
  -- branch = "0.1.x",
  branch = 'master',
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
        file_ignore_patterns = { "^node_modules/", "^.git/", "^.venv/", "^.github/" },
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
        live_grep = {
          mappings = {
            i = {
              ["<CR>"] = function(prompt_bufnr)
                local action_state = require("telescope.actions.state")
                local actions = require("telescope.actions")
                local entry = action_state.get_selected_entry()
                actions.close(prompt_bufnr)

                if entry then
                  local filename = entry.filename or entry.path
                  local bufnr = vim.fn.bufnr(filename)
                  local winid = nil

                  -- Find a window showing the buffer
                  for _, w in ipairs(vim.api.nvim_list_wins()) do
                    if vim.api.nvim_win_get_buf(w) == bufnr then
                      winid = w
                      break
                    end
                  end

                  if winid then
                    -- Switch to the window showing the file
                    vim.api.nvim_set_current_win(winid)
                  else
                    -- Otherwise open in new tab (or change to your preferred open command)
                    vim.cmd("tabedit " .. vim.fn.fnameescape(filename))
                  end

                  -- Move cursor to matched line and column
                  if entry.lnum and entry.col then
                    vim.api.nvim_win_set_cursor(0, {entry.lnum, entry.col - 1})
                  end
                end
              end,
            },
          },
        },
        grep_string = {
          mappings = {
            i = {
              ["<CR>"] = function(prompt_bufnr)
                local action_state = require("telescope.actions.state")
                local actions = require("telescope.actions")
                local entry = action_state.get_selected_entry()
                actions.close(prompt_bufnr)

                if entry then
                  local filename = entry.filename or entry.path
                  local bufnr = vim.fn.bufnr(filename)
                  local winid = nil

                  for _, w in ipairs(vim.api.nvim_list_wins()) do
                    if vim.api.nvim_win_get_buf(w) == bufnr then
                      winid = w
                      break
                    end
                  end

                  if winid then
                    vim.api.nvim_set_current_win(winid)
                  else
                    vim.cmd("tabedit " .. vim.fn.fnameescape(filename))
                  end

                  if entry.lnum and entry.col then
                    vim.api.nvim_win_set_cursor(0, {entry.lnum, entry.col - 1})
                  end
                end
              end,
            },
          },
        },
        current_buffer_fuzzy_find = {
          mappings = {
            i = {
              ["<CR>"] = function(prompt_bufnr)
                local action_state = require("telescope.actions.state")
                local actions = require("telescope.actions")
                local entry = action_state.get_selected_entry()
                actions.close(prompt_bufnr)

                if entry then
                  -- Try to get lnum/col from entry
                  local lnum = entry.lnum or entry.line or entry.value or 1
                  local col = entry.col or 1

                  vim.schedule(function()
                    vim.api.nvim_win_set_cursor(0, { lnum, col - 1 })
                  end)
                end
              end,
            },
          },
        },
      },
      find_files = {
        hidden = true,
        file_ignore_patterns = { 'node_modules/', '.git/', '.venv/' },
      },
    })

    telescope.load_extension("fzf")

    -- Keymaps
    local keymap = vim.keymap
    -- keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Fuzzy find files in cwd" })
    keymap.set("n", "<leader>ff", function()
      require("telescope.builtin").find_files({ hidden = true })
    end, { desc = "Fuzzy find files, including hidden" })
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



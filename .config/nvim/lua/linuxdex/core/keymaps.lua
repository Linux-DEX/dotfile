vim.g.mapleader = " "

local keymap = vim.keymap -- for conciseness
local opts = { noremap = true, silent = true }

keymap.set("n", "<Esc>", ":nohl<CR>", { desc = "Clear search highlights" })
keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode with Esc", noremap = true, silent = true })
keymap.set("i", "<C-BS>", "<C-w>", { noremap = true })

-- increment/decrement numbers
keymap.set("n", "<leader>+", "<C-a>", { desc = "Increment number" }) -- increment
keymap.set("n", "<leader>-", "<C-x>", { desc = "Decrement number" }) -- decrement

-- window management
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" }) -- split window vertically
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" }) -- split window horizontally
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" }) -- make split windows equal width & height
keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" }) -- close current split window

-- keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" }) -- open new tab
-- keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" }) -- close current tab
-- keymap.set("n", "<Tab>", "<cmd>tabn<CR>", { desc = "Go to next tab" }) --  go to next tab
-- keymap.set("n", "<S-Tab>", "<cmd>tabp<CR>", { desc = "Go to previous tab" }) --  go to previous tab
-- keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" }) --  move current buffer to new tab

-- stay in visual mode when shifting text left or right
keymap.set("v", "<", "<gv", opts)
keymap.set("v", ">", ">gv", opts)

keymap.set("n", "n", "nzzzv")
keymap.set("n", "N", "Nzzzv")

keymap.set("n", "<Tab>", ":bnext<CR>")
keymap.set("n", "<S-Tab>", ":bprev<CR>")

keymap.set("n", "<leader>bn", ":bnext<CR>")
keymap.set("n", "<leader>bp", ":bprev<CR>")
keymap.set("n", "<leader>bx", ":bdelete<CR>")

keymap.set("n", "*", "*zz")
keymap.set("n", "#", "#zz")
keymap.set("n", "g*", "g*zz")
keymap.set("n", "g#", "g#zz")

-- Disable vim-tmux-navigator default mappings to prevent Ctrl+\ conflict
vim.g.tmux_navigator_no_mappings = 1

-- Create custom vim-tmux-navigator mappings (without Ctrl+\ for toggleterm)
keymap.set("n", "<C-h>", ":<C-U>TmuxNavigateLeft<CR>", { silent = true, desc = "Navigate left (tmux/vim)" })
keymap.set("n", "<C-j>", ":<C-U>TmuxNavigateDown<CR>", { silent = true, desc = "Navigate down (tmux/vim)" })
keymap.set("n", "<C-k>", ":<C-U>TmuxNavigateUp<CR>", { silent = true, desc = "Navigate up (tmux/vim)" })
keymap.set("n", "<C-l>", ":<C-U>TmuxNavigateRight<CR>", { silent = true, desc = "Navigate right (tmux/vim)" })

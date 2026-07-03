local status_ok, nvimtree = pcall(require, "nvim-tree")
if not status_ok then
	return
end

-- Disable default netrw file explorer
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

nvimtree.setup({
	view = {
		width = 40,
		relativenumber = true,
		signcolumn = "yes", -- Keep signcolumn yes so git and diagnostic icons don't cause sudden shifting
		side = "right",
	},
	renderer = {
		highlight_git = true, -- Highlight file and directory names based on git status
		highlight_modified = "all", -- Visually flag files with unsaved/unstaged changes
		indent_markers = {
			enable = true,
		},
		icons = {
			show = {
				file = true,
				folder = true,
				folder_arrow = false, -- Cleanly hide folder arrows instead of setting empty strings
				git = true,
			},
			glyphs = {
				git = {
					unstaged = "✗",
					staged = "✓",
					unmerged = "",
					renamed = "➜",
					untracked = "★",
					deleted = "",
					ignored = "◌",
				},
			},
		},
	},
	diagnostics = {
		enable = true, -- Show LSP diagnostics directly in the tree explorer
		show_on_dirs = true,
		icons = {
			hint = "",
			info = "",
			warning = "",
			error = "",
		},
	},
	actions = {
		open_file = {
			window_picker = {
				enable = false, -- Disable window picker to open files instantly
			},
		},
	},
	update_focused_file = {
		enable = true, -- Automatically focus and reveal active file in the tree
	},
	filters = {
		custom = { ".DS_Store", "^.git$" }, -- Cleanly filter out .DS_Store and .git directories
		git_ignored = false, -- Keep git ignored files visible but styled differently
	},
})

-- Global Keymaps
local keymap = vim.keymap.set
local opts = { silent = true }

keymap(
	"n",
	"<leader>ee",
	"<cmd>NvimTreeFindFileToggle<CR>",
	vim.tbl_extend("force", opts, { desc = "Toggle file explorer" })
)
keymap(
	"n",
	"<leader>ec",
	"<cmd>NvimTreeCollapse<CR>",
	vim.tbl_extend("force", opts, { desc = "Collapse file explorer" })
)
keymap("n", "<leader>er", "<cmd>NvimTreeRefresh<CR>", vim.tbl_extend("force", opts, { desc = "Refresh file explorer" }))
keymap("n", "<leader>eo", "<cmd>NvimTreeOpen<CR>", vim.tbl_extend("force", opts, { desc = "Open file explorer" }))
keymap("n", "<leader>eq", "<cmd>NvimTreeClose<CR>", vim.tbl_extend("force", opts, { desc = "Close file explorer" }))
keymap(
	"n",
	"<leader>ef",
	"<cmd>NvimTreeFindFile<CR>",
	vim.tbl_extend("force", opts, { desc = "Find Current file in explorer" })
)
keymap("n", "<leader>ev", "<cmd>NvimTreeFocus<CR>", vim.tbl_extend("force", opts, { desc = "Focus on file explorer" }))
keymap(
	"n",
	"<leader>en",
	"<cmd>NvimTreeResize +10<CR>",
	vim.tbl_extend("force", opts, { desc = "Increase explorer width" })
)
keymap(
	"n",
	"<leader>em",
	"<cmd>NvimTreeResize -10<CR>",
	vim.tbl_extend("force", opts, { desc = "Decrease explorer width" })
)

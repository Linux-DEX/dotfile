return {
	"nvim-tree/nvim-tree.lua",
	dependencies = "nvim-tree/nvim-web-devicons",
	config = function()
		local nvimtree = require("nvim-tree")

		-- recommended settings from nvim-tree documentation
		vim.g.loaded_netrw = 1
		vim.g.loaded_netrwPlugin = 1

		nvimtree.setup({
			view = {
				width = 45,
				relativenumber = true,
        signcolumn = "no",
        side = "right",
			},
			-- change folder arrow icons
			renderer = {
				indent_markers = {
					enable = true,
				},
				icons = {
					glyphs = {
						folder = {
							arrow_closed = "", -- arrow when folder is closed
							arrow_open = "", -- arrow when folder is open
						},
					},
				},
			},
			-- disable window_picker for
			-- explorer to work well with
			-- window splits
			actions = {
				open_file = {
					window_picker = {
						enable = false,
					},
				},
			},
			filters = {
				custom = { ".DS_Store" },
			},
			git = {
				ignore = false,
			},
		})

		-- set keymaps
		local keymap = vim.keymap -- for conciseness

		-- keymap.set("n", "<leader>ee", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file explorer" }) -- toggle file explorer
		-- keymap.set("n", "<C-n>", "<cmd>NvimTreeFindFileToggle<CR>", { desc = "Toggle file explorer on current file" }) -- toggle file explorer on current file
		keymap.set("n", "<leader>ee", "<cmd>NvimTreeFindFileToggle<CR>", { desc = "Toggle file explorer" }) -- toggle file explorer
		keymap.set("n", "<leader>ec", "<cmd>NvimTreeCollapse<CR>", { desc = "Collapse file explorer" }) -- collapse file explorer
		keymap.set("n", "<leader>er", "<cmd>NvimTreeRefresh<CR>", { desc = "Refresh file explorer" }) -- refresh file explorer

    keymap.set("n", "<leader>eo", "<cmd>NvimTreeOpen<CR>", { desc = "Open file explorer" })
    keymap.set("n", "<leader>eq", "<cmd>NvimTreeClose<CR>", { desc = "Close file explorer" })
    keymap.set("n", "<leader>ef", "<cmd>NvimTreeFindFile<CR>", { desc = "Find Current file in explorer" })
    keymap.set("n", "<leader>ev", "<cmd>NvimTreeFocus<CR>", { desc = "Focus on file explorer" })
    keymap.set("n", "<leader>en", "<cmd>NvimTreeResize +10<CR>", { desc = "Increase explorer width" })
    keymap.set("n", "<leader>em", "<cmd>NvimTreeResize -10<CR>", { desc = "Decrease explorer width" })
	end,
}

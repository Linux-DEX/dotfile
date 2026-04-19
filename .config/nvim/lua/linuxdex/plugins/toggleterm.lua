local toggleterm = require("toggleterm")
local Terminal = require("toggleterm.terminal").Terminal

toggleterm.setup({
	size = function(term)
		if term.direction == "horizontal" then
			return 15
		elseif term.direction == "vertical" then
			return 50
		else
			return 20
		end
	end,
	open_mapping = [[<C-\>]],
	shade_filetypes = {},
	shade_terminals = true,
	shading_factor = 2,
	start_in_insert = true,
	insert_mappings = true,
	terminal_mappings = true,
	persist_size = true,
	direction = "float",
	close_on_exit = true,
	auto_scroll = true,
	float_opts = {
		border = "curved",
		width = math.floor(vim.o.columns * 0.8),
		height = math.floor(vim.o.lines * 0.8),
		row = math.floor((vim.o.lines - (vim.o.lines * 0.8)) / 2),
		col = math.floor((vim.o.columns - (vim.o.columns * 0.8)) / 2),
	},
})

local float_term = Terminal:new({ direction = "float" })
local horiz_term = Terminal:new({ direction = "horizontal", size = 15 })
local vert_term = Terminal:new({ direction = "vertical", size = 50 })

local keymap = vim.keymap

keymap.set("n", "<A-i>", function()
	float_term:toggle()
end, { desc = "Toggle floating terminal" })
keymap.set("n", "<leader>th", function()
	horiz_term:toggle()
end, { desc = "Toggle horizontal terminal" })
keymap.set("n", "<leader>tv", function()
	vert_term:toggle()
end, { desc = "Toggle vertical terminal" })

keymap.set("t", "<esc>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })
keymap.set("t", "<A-h>", [[<C-\><C-n><C-w>h]], { desc = "Move left" })
keymap.set("t", "<A-j>", [[<C-\><C-n><C-w>j]], { desc = "Move down" })
keymap.set("t", "<A-k>", [[<C-\><C-n><C-w>k]], { desc = "Move up" })
keymap.set("t", "<A-l>", [[<C-\><C-n><C-w>l]], { desc = "Move right" })

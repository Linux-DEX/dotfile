return {
	"akinsho/toggleterm.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local toggleterm = require("toggleterm")

		-- Set up ToggleTerm with desired options
		toggleterm.setup({
			size = 20,
			open_mapping = [[<A-i>]],
			hide_numbers = true,
			shade_filetypes = {},
			shade_terminals = true,
			shading_factor = 2,
			start_in_insert = true,
			insert_mappings = true,
			persist_size = true,
			direction = "horizontal", -- 'vertical' | 'horizontal' | 'float'
			close_on_exit = true,
			shell = vim.o.shell,
			float_opts = {
				border = "curved",
				winblend = 3,
			},
		})

		-- Set keymaps for opening different terminal types
		local keymap = vim.keymap -- for conciseness
	end,
}

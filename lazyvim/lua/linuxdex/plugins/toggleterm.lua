return {
	"akinsho/toggleterm.nvim",
	event = { "BufReadPre", "BufNewFile" }, -- You can change this if you want it to load on other events
	config = function()
		local toggleterm = require("toggleterm")

		-- Set up toggleterm configuration
		toggleterm.setup({
			size = 20, -- You can adjust this to the size you want
			open_mapping = [[<A-i>]], -- Key binding to toggle the terminal
			shade_filetypes = {},
			shade_terminals = true,
			shading_factor = 2, -- The degree of darkness for the shaded background
			start_in_insert = true, -- Start in insert mode when opening a new terminal
			insert_mappings = true, -- Whether or not to enable insert mode mappings
			terminal_mappings = true, -- Whether or not to enable terminal mappings
			persist_size = true, -- Whether or not to persist the size of the terminal
			direction = "float", -- The direction of the terminal: 'horizontal', 'vertical', or 'tab'
			-- Configuration specific to floating terminal
			float_opts = {
				border = "curved", -- or 'double', 'shadow', 'curved', etc.
				width = 103, -- adjust as needed
				height = 29, -- adjust as needed
				row = 2.8, -- 30% from the top of the screen; can be a number or function
				col = 18, -- 30% from the left of the screen; can be a number or function
				-- winblend = 3, -- the level of transparency
				-- zindex = 10, -- window stack order
			},
		})

		-- Key mappings for terminal navigation
		local keymap = vim.keymap -- for conciseness

		-- Toggle terminal with <c-\>
		keymap.set("n", "<A-i>", function()
			toggleterm.toggle()
		end, { desc = "Toggle terminal" })

		-- Open a floating terminal with <leader>tf
		keymap.set("n", "<A-j>", function()
			-- Command to open a floating terminal
			toggleterm.open({ direction = "float" })
		end, { desc = "Open floating terminal" })
	end,
}

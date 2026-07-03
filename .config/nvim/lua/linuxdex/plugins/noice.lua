local status_ok, noice = pcall(require, "noice")
if not status_ok then
	return
end

-- Clear messages if coming from a lazy-like state
if vim.o.filetype == "lazy" then
	vim.cmd([[messages clear]])
end

noice.setup({
	lsp = {
		-- Override markdown rendering so that cmp and other plugins use Treesitter
		override = {
			["vim.lsp.util.convert_input_to_markdown_lines"] = true,
			["vim.lsp.util.stylize_markdown"] = true,
			["cmp.entry.get_documentation"] = true,
		},
		signature = {
			enabled = true,
			auto_open = {
				enabled = true,
				trigger = true, -- Automatically show signature help when typing a trigger character from LSP
				luasnip = true, -- Open signature help when jumping to Luasnip gaps
				throttle = 50, -- Debounce signature help requests to keep typing fluid
			},
		},
		hover = {
			enabled = true,
			silent = true, -- Set to true to not show "No information available" messages when hover is empty
		},
	},
	routes = {
		-- Redirect common editor messages to the mini view (bottom right) to keep workspace clean
		{
			filter = {
				event = "msg_show",
				any = {
					{ find = "%d+L, %d+B" },
					{ find = "; after #%d+" },
					{ find = "; before #%d+" },
					{ find = "%d+ lines" },
					{ find = "%d+ fewer lines" },
					{ find = "%d+ more lines" },
					{ find = "change; before #" },
					{ find = "change; after #" },
				},
			},
			view = "mini",
		},
		-- Skip/Hide redundant or noisy messages completely
		{
			filter = {
				any = {
					-- Skip LSP progress messages (often extremely spammy)
					{ event = "lsp", kind = "progress" },
					-- Skip file save "written" confirmations
					{ event = "msg_show", kind = "", find = "written" },
					-- Skip search hit boundary wraps
					{ event = "msg_show", find = "search hit BOTTOM, continuing at TOP" },
					{ event = "msg_show", find = "search hit TOP, continuing at BOTTOM" },
					-- Skip empty LSP hover warnings
					{ event = "notify", find = "No information available" },
				},
			},
			opts = { skip = true },
		},
	},
	cmdline = {
		enabled = true,
		view = "cmdline_popup",
		format = {
			cmdline = { pattern = "^:", icon = "", lang = "vim" },
			search_down = { kind = "search", pattern = "^/", icon = " ", lang = "regex" },
			search_up = { kind = "search", pattern = "^%?", icon = " ", lang = "regex" },
			filter = { pattern = "^:%s*!", icon = "", lang = "bash" },
			lua = { pattern = { "^:%s*lua%s+", "^:%s*=%s*" }, icon = "", lang = "lua" },
			help = { pattern = "^:%s*he?l?p?%s+", icon = "" },
			input = {},
		},
	},
	views = {
		-- Style popups to use standard NormalFloat and FloatBorder highlight groups.
		-- This guarantees perfect compatibility with transparent background settings and custom colors.
		cmdline_popup = {
			position = {
				row = "40%",
				col = "50%",
			},
			size = {
				width = 60,
				height = "auto",
			},
			border = {
				style = "rounded",
				padding = { 0, 1 },
			},
			win_options = {
				winhighlight = {
					Normal = "NormalFloat",
					FloatBorder = "FloatBorder",
				},
			},
		},
		popupmenu = {
			relative = "editor",
			position = {
				row = "53%",
				col = "50%",
			},
			size = {
				width = 60,
				height = 10,
			},
			border = {
				style = "rounded",
				padding = { 0, 1 },
			},
			win_options = {
				winhighlight = {
					Normal = "NormalFloat",
					FloatBorder = "FloatBorder",
				},
			},
		},
		hover = {
			border = {
				style = "rounded",
				padding = { 0, 2 },
			},
			win_options = {
				winhighlight = {
					Normal = "NormalFloat",
					FloatBorder = "FloatBorder",
				},
			},
		},
	},
	presets = {
		bottom_search = true,
		command_palette = true,
		long_message_to_split = true,
		lsp_doc_border = true,
	},
})

-- Keymaps
local keymap = vim.keymap.set
keymap("c", "<S-Enter>", function()
	noice.redirect(vim.fn.getcmdline())
end, { desc = "Redirect Cmdline" })
keymap("n", "<leader>snl", function()
	noice.cmd("last")
end, { desc = "Noice Last Message" })
keymap("n", "<leader>snh", function()
	noice.cmd("history")
end, { desc = "Noice History" })
keymap("n", "<leader>sna", function()
	noice.cmd("all")
end, { desc = "Noice All" })
keymap("n", "<leader>snd", function()
	noice.cmd("dismiss")
end, { desc = "Dismiss All" })
keymap("n", "<leader>snt", function()
	noice.cmd("pick")
end, { desc = "Noice Picker (Telescope/FzfLua)" })
keymap({ "i", "n", "s" }, "<c-f>", function()
	if not require("noice.lsp").scroll(4) then
		return "<c-f>"
	end
end, { silent = true, expr = true, desc = "Scroll Forward" })
keymap({ "i", "n", "s" }, "<c-b>", function()
	if not require("noice.lsp").scroll(-4) then
		return "<c-b>"
	end
end, { silent = true, expr = true, desc = "Scroll Backward" })

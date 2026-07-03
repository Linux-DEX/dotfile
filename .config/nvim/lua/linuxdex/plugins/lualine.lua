local lualine = require("lualine")

local colors = {
	bg = "#1e1e2e",
	fg = "#cdd6f4",
	overlay0 = "#6c7086",
	blue = "#89b4fa",
	peach = "#fab387",
	red = "#f38ba8",
	green = "#a6e3a1",
	magenta = "#cba6f7",
	yellow = "#f9e2af",
	inactive_bg = "#2c3043",
}

local catppuccin_mocha_mode_fg_theme = {
	normal = {
		a = { fg = colors.blue, bg = colors.bg, gui = "bold" },
		b = { bg = colors.bg, fg = colors.fg },
		c = { bg = colors.bg, fg = colors.overlay0 },
	},
	insert = {
		a = { fg = colors.green, bg = colors.bg, gui = "bold" },
		b = { bg = colors.bg, fg = colors.fg },
		c = { bg = colors.bg, fg = colors.overlay0 },
	},
	visual = {
		a = { fg = colors.magenta, bg = colors.bg, gui = "bold" },
		b = { bg = colors.bg, fg = colors.fg },
		c = { bg = colors.bg, fg = colors.overlay0 },
	},
	command = {
		a = { fg = colors.yellow, bg = colors.bg, gui = "bold" },
		b = { bg = colors.bg, fg = colors.fg },
		c = { bg = colors.bg, fg = colors.overlay0 },
	},
	replace = {
		a = { fg = colors.red, bg = colors.bg, gui = "bold" },
		b = { bg = colors.bg, fg = colors.fg },
		c = { bg = colors.bg, fg = colors.overlay0 },
	},
	inactive = {
		a = { fg = colors.overlay0, bg = colors.inactive_bg, gui = "bold" },
		b = { fg = colors.overlay0, bg = colors.inactive_bg },
		c = { fg = colors.overlay0, bg = colors.inactive_bg },
	},
}

lualine.setup({
	options = {
		theme = catppuccin_mocha_mode_fg_theme,
		section_separators = { left = "", right = "" },
		component_separators = { left = "", right = "" },
		globalstatus = true,
		icons_enabled = true,
	},
	sections = {
		lualine_a = { "mode" },
		lualine_b = {
			{
				"branch",
				icon = "",
				color = { fg = "#8aadf4" },
			},
		},
		lualine_c = {
			{
				"filename",
				path = 1,
				color = { fg = "#9ca0b0" },
			},
			{
				-- Show auto-session status/name safely
				function()
					local ok, session_lib = pcall(require, "auto-session.lib")
					if ok then
						local name = session_lib.current_session_name()
						if name and name ~= "" then
							return "󰆓 " .. name
						end
					end
					return ""
				end,
				color = { fg = "#fab387" },
			},
		},
		lualine_x = {
			{
				"diagnostics",
				symbols = { error = " ", warn = " ", info = " ", hint = " " },
			},
			{
				-- Show active LSP clients
				function()
					local msg = "No LSP"
					local buf_ft = vim.bo[0].filetype
					local clients = vim.lsp.get_clients({ bufnr = 0 })
					if next(clients) == nil then
						return msg
					end
					local client_names = {}
					for _, client in ipairs(clients) do
						table.insert(client_names, client.name)
					end
					return "[" .. table.concat(client_names, ", ") .. "]"
				end,
				color = { fg = "#8aadf4", gui = "bold" },
			},
			{
				-- Show vim.pack managed plugin count
				function()
					local ok, pack_data = pcall(vim.pack.get, nil, { info = false })
					if ok and pack_data then
						return "  " .. #pack_data
					end
					return ""
				end,
				color = { fg = "#8aadf4" },
			},
		},
		lualine_y = {
			{
				"filetype",
				color = { fg = "#8aadf4" },
			},
			{
				"progress",
				color = { fg = "#8aadf4" },
			},
		},
		lualine_z = {
			{
				"location",
				color = { fg = colors.bg, bg = colors.blue, gui = "bold" },
			},
		},
	},
	inactive_sections = {
		lualine_a = { "filename" },
		lualine_b = {},
		lualine_c = {},
		lualine_x = {},
		lualine_y = {},
		lualine_z = { "location" },
	},
	tabline = {},
	extensions = {},
})

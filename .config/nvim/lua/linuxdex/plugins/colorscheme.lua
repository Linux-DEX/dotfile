local status_ok, catppuccin = pcall(require, "catppuccin")
if not status_ok then
	return
end

catppuccin.setup({
	flavour = "mocha",
	transparent_background = true,
	styles = {
		comments = { "italic" },
		keywords = { "italic" },
	},
	integrations = {
		treesitter = true,
		native_lsp = {
			enabled = true,
		},
		cmp = true,
		gitsigns = true,
		telescope = true,
		nvimtree = true,
		noice = true,
		which_key = true,
		indent_blankline = { enabled = true },
		mason = true,
		todo_comments = true,
		mini = { enabled = true },
	},
	custom_highlights = function(colors)
		return {
			-- Base/UI highlights with transparency
			Normal = { bg = "none", fg = colors.text },
			NormalNC = { bg = "none" },
			SignColumn = { bg = "none" },
			NormalFloat = { bg = "none", fg = colors.text },
			FloatBorder = { bg = "none", fg = colors.blue },
			FloatTitle = { bg = "none", fg = colors.mauve, bold = true },
			EndOfBuffer = { bg = "none", fg = "none" },
			CursorLine = { bg = "none" },

			-- Sidebar and line numbers
			CursorLineNr = { fg = colors.blue, bold = true },
			LineNr = { fg = colors.overlay0, bold = true },

			-- Completion / Popup Menu styling
			Pmenu = { bg = "none" },
			PmenuSel = { bg = colors.blue, fg = "#ffffff", bold = true },
			PmenuSbar = { bg = "none" },
			PmenuThumb = { bg = colors.red },

			-- Code highlights
			Comment = { fg = colors.overlay0, italic = true },
			String = { fg = colors.sky },
			Function = { fg = colors.blue, bold = true },
			Keyword = { fg = colors.mauve, italic = true },
			Identifier = { fg = colors.red },
			Constant = { fg = colors.sapphire },
			Type = { fg = colors.green },
			Error = { fg = colors.mauve, bold = true },

			-- Editor state / interactive highlights
			Cursor = { fg = "none", bg = colors.rosewater },
			Visual = { bg = colors.rosewater, fg = colors.crust },

			-- LSP Diagnostics
			DiagnosticError = { fg = colors.red },
			DiagnosticWarn = { fg = colors.yellow },
			DiagnosticInfo = { fg = colors.sky },
			DiagnosticHint = { fg = colors.green },

			-- Git Indicators
			GitSignsAdd = { fg = colors.green },
			GitSignsChange = { fg = colors.sky },
			GitSignsDelete = { fg = colors.red },

			-- Telescope UI overrides
			TelescopeBorder = { fg = colors.lavender, bg = "none" },
			TelescopeSelection = { fg = colors.blue, bold = true, bg = "none" },
			TelescopePromptPrefix = { fg = colors.red, bg = "none" },

			TelescopeTitle = { fg = colors.blue, bg = "none", bold = true },
			TelescopePromptTitle = { fg = colors.red, bg = "none", bold = true },
			TelescopeResultsTitle = { fg = colors.mauve, bg = "none", bold = true },
			TelescopePreviewTitle = { fg = colors.green, bg = "none", bold = true },
		}
	end,
})

vim.cmd("colorscheme catppuccin")

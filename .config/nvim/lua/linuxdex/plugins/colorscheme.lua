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
	color_overrides = {
		mocha = {
			base       = "#1E1E2E", -- same as your terminal background
			mantle     = "#181825",
			crust      = "#11111B",

			-- accent colors remapped to your blue/violet/teal palette
			rosewater  = "#DAC1FF",
			flamingo   = "#D2C2FF",
			pink       = "#C4A7FF",
			mauve      = "#B49AFF", -- was purple, now soft violet
			red        = "#7EC8FF", -- was red, now sky blue (keeps errors visible, stays in family)
			maroon     = "#7C9CFF",
			peach      = "#AEDBFF",
			yellow     = "#8CE8F5", -- warnings, shifted to cyan
			green      = "#7DE1D0", -- success/types, shifted to teal
			teal       = "#5AD1E6",
			sky        = "#5AD1E6",
			sapphire   = "#4C7CFF",
			blue       = "#7EC8FF", -- primary accent
			lavender   = "#C4A7FF",

			text       = "#CDD6F4",
			subtext1   = "#A6ADC8",
			subtext0   = "#8C93B8",
			overlay2   = "#7C8299",
			overlay1   = "#686E85",
			overlay0   = "#5C6180",
			surface2   = "#4A4F6B",
			surface1   = "#3A3F58",
			surface0   = "#313244",
		},
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
			PmenuSel = { bg = colors.blue, fg = "#1E1E2E", bold = true },
			PmenuSbar = { bg = "none" },
			PmenuThumb = { bg = colors.sapphire },

			-- Code highlights
			Comment = { fg = colors.overlay0, italic = true },
			String = { fg = colors.sky },
			Function = { fg = colors.blue, bold = true },
			Keyword = { fg = colors.mauve, italic = true },
			Identifier = { fg = colors.sapphire },
			Constant = { fg = colors.lavender },
			Type = { fg = colors.teal },
			Error = { fg = colors.red, bold = true },

			-- Editor state / interactive highlights
			Cursor = { fg = "none", bg = colors.rosewater },
			Visual = { bg = colors.surface1, fg = "none" },

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
			TelescopePromptPrefix = { fg = colors.sapphire, bg = "none" },
			TelescopeTitle = { fg = colors.blue, bg = "none", bold = true },
			TelescopePromptTitle = { fg = colors.sapphire, bg = "none", bold = true },
			TelescopeResultsTitle = { fg = colors.mauve, bg = "none", bold = true },
			TelescopePreviewTitle = { fg = colors.teal, bg = "none", bold = true },
		}
	end,
})

vim.cmd("colorscheme catppuccin")

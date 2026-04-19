local palette = {
	fg = "#CDD6F4",
	cursor = "#F5E0DC",
	sel_bg = "#F5E0DC",
	sel_fg = "#1E1E2E",
	black = "#11111B",
	violet1 = "#CBA6F7",
	violet2 = "#B4BEFE",
	violet3 = "#A6E3A1",
	blue1 = "#89B4FA",
	blue2 = "#74C7EC",
	blue3 = "#89DCEB",
	white = "#FFFFFF",
	gray = "#6C7086",
	mag1 = "#F38BA8",
	mag2 = "#F5C2E7",
	mag3 = "#CBA6F7",
	blue4 = "#89B4FA",
	blue5 = "#74C7EC",
	blue6 = "#89DCEB",
	green1 = "#A6E3A1",
	yellow1 = "#F9E2AF",
	white2 = "#FFFFFF",
}

require("catppuccin").setup({
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
	},
})

vim.cmd("colorscheme catppuccin")

vim.schedule(function()
	vim.api.nvim_set_hl(0, "Normal", { bg = "none", fg = palette.fg })
	vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
	vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none", fg = palette.fg })
	vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none", fg = palette.blue1 })
	vim.api.nvim_set_hl(0, "FloatTitle", { bg = "none", fg = palette.violet1, bold = true })
	vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none", fg = "none" })
	vim.api.nvim_set_hl(0, "CursorLine", { bg = "none" })

	vim.api.nvim_set_hl(0, "CursorLineNr", { fg = palette.blue4, bold = true })
	vim.api.nvim_set_hl(0, "LineNr", { fg = palette.gray, bold = true })

	vim.cmd("highlight Pmenu guibg=none")
	vim.cmd("highlight PmenuSel guibg=" .. palette.blue1 .. " guifg=" .. palette.white2 .. " gui=bold")
	vim.cmd("highlight PmenuSbar guibg=none")
	vim.cmd("highlight PmenuThumb guibg=" .. palette.mag1)

	vim.api.nvim_set_hl(0, "Comment", { fg = palette.gray, italic = true })
	vim.api.nvim_set_hl(0, "String", { fg = palette.blue5 })
	vim.api.nvim_set_hl(0, "Function", { fg = palette.blue1, bold = true })
	vim.api.nvim_set_hl(0, "Keyword", { fg = palette.violet1, italic = true })
	vim.api.nvim_set_hl(0, "Identifier", { fg = palette.mag1 })
	vim.api.nvim_set_hl(0, "Constant", { fg = palette.blue3 })
	vim.api.nvim_set_hl(0, "Type", { fg = palette.green1 })
	vim.api.nvim_set_hl(0, "Error", { fg = palette.mag3, bold = true })

	vim.api.nvim_set_hl(0, "Cursor", { fg = "none", bg = palette.cursor })
	vim.api.nvim_set_hl(0, "Visual", { bg = palette.sel_bg, fg = palette.sel_fg })

	vim.api.nvim_set_hl(0, "DiagnosticError", { fg = palette.mag1 })
	vim.api.nvim_set_hl(0, "DiagnosticWarn", { fg = palette.yellow1 })
	vim.api.nvim_set_hl(0, "DiagnosticInfo", { fg = palette.blue6 })
	vim.api.nvim_set_hl(0, "DiagnosticHint", { fg = palette.green1 })

	vim.api.nvim_set_hl(0, "GitSignsAdd", { fg = palette.green1 })
	vim.api.nvim_set_hl(0, "GitSignsChange", { fg = palette.blue5 })
	vim.api.nvim_set_hl(0, "GitSignsDelete", { fg = palette.mag1 })

	vim.api.nvim_set_hl(0, "TelescopeBorder", { fg = palette.violet2, bg = "none" })
	vim.api.nvim_set_hl(0, "TelescopeSelection", { fg = palette.blue1, bold = true, bg = "none" })
	vim.api.nvim_set_hl(0, "TelescopePromptPrefix", { fg = palette.mag1, bg = "none" })

	vim.api.nvim_set_hl(0, "TelescopeTitle", { fg = palette.blue1, bg = "none", bold = true })
	vim.api.nvim_set_hl(0, "TelescopePromptTitle", { fg = palette.mag1, bg = "none", bold = true })
	vim.api.nvim_set_hl(0, "TelescopeResultsTitle", { fg = palette.violet1, bg = "none", bold = true })
	vim.api.nvim_set_hl(0, "TelescopePreviewTitle", { fg = palette.green1, bg = "none", bold = true })
end)

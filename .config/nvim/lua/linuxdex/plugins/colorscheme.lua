-- == tokyonight ==
-- return {
-- 	"folke/tokyonight.nvim",
-- 	priority = 1000,
-- 	config = function()
-- 		local transparent = true -- set to true if you would like to enable transparency
--
-- 		local bg = "#011628"
-- 		local bg_dark = "#011423"
-- 		local bg_highlight = "#143652"
-- 		local bg_search = "#0A64AC"
-- 		local bg_visual = "#275378"
-- 		local fg = "#CBE0F0"
-- 		local fg_dark = "#B4D0E9"
-- 		local fg_gutter = "#627E97"
-- 		local border = "#547998"
--
-- 		require("tokyonight").setup({
-- 			style = "night",
-- 			transparent = transparent,
-- 			styles = {
-- 				sidebars = transparent and "transparent" or "dark",
-- 				floats = transparent and "transparent" or "dark",
-- 			},
-- 			on_colors = function(colors)
-- 				colors.bg = bg
-- 				colors.bg_dark = transparent and colors.none or bg_dark
-- 				colors.bg_float = transparent and colors.none or bg_dark
-- 				colors.bg_highlight = bg_highlight
-- 				colors.bg_popup = bg_dark
-- 				colors.bg_search = bg_search
-- 				colors.bg_sidebar = transparent and colors.none or bg_dark
-- 				colors.bg_statusline = transparent and colors.none or bg_dark
-- 				colors.bg_visual = bg_visual
-- 				colors.border = border
-- 				colors.fg = fg
-- 				colors.fg_dark = fg_dark
-- 				colors.fg_float = fg
-- 				colors.fg_gutter = fg_gutter
-- 				colors.fg_sidebar = fg_dark
-- 			end,
-- 		})
--
-- 		vim.cmd("colorscheme tokyonight")
--
-- 		-- Set transparency for suggestion popup
-- 		if transparent then
-- 			vim.cmd("highlight Pmenu guibg=none")
-- 			vim.cmd("highlight PmenuSel guibg=#143652")
-- 			vim.cmd("highlight PmenuSbar guibg=none")
-- 			vim.cmd("highlight PmenuThumb guibg=#547998")
-- 		end
--
-- 		vim.cmd("highlight CursorLine guibg=none guifg=none ctermbg=none ctermfg=none")
-- 	end,
-- }

-- == catppuccin theme == 
return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  config = function()
    local palette = {
      fg      = "#CDD6F4", -- text
      cursor  = "#F5E0DC", -- rosewater
      sel_bg  = "#F5E0DC",
      sel_fg  = "#1E1E2E",
      black   = "#11111B", -- mantle
      violet1 = "#CBA6F7", -- mauve
      violet2 = "#B4BEFE", -- lavender
      violet3 = "#A6E3A1", -- greenish violet for variation
      blue1   = "#89B4FA", -- blue
      blue2   = "#74C7EC", -- sapphire
      blue3   = "#89DCEB", -- sky
      white   = "#FFFFFF",
      gray    = "#6C7086", -- surface2
      mag1    = "#F38BA8", -- red
      mag2    = "#F5C2E7", -- pink
      mag3    = "#CBA6F7", -- mauve
      blue4   = "#89B4FA",
      blue5   = "#74C7EC",
      blue6   = "#89DCEB",
      green1  = "#A6E3A1", -- green
      yellow1 = "#F9E2AF", -- yellow
      white2  = "#FFFFFF",
    }

    require("catppuccin").setup({
      flavour = "mocha", -- latte, frappe, macchiato, mocha
      transparent_background = true,
      styles = {
        comments = { "italic" },
        keywords = { "italic" },
      },
      integrations = {
        telescope = true,
        gitsigns = true,
        cmp = true,
        treesitter = true,
      },
    })

    vim.cmd("colorscheme catppuccin")

    vim.schedule(function()
      -- Core editor transparency
      -- vim.api.nvim_set_hl(0, "Normal",       { bg = "none", fg = palette.fg })
      -- vim.api.nvim_set_hl(0, "NormalNC",     { bg = "none" })
      -- vim.api.nvim_set_hl(0, "SignColumn",   { bg = "none" })
      -- vim.api.nvim_set_hl(0, "NormalFloat",  { bg = "none" })
      -- vim.api.nvim_set_hl(0, "EndOfBuffer",  { bg = "none", fg = "none" })
      -- vim.api.nvim_set_hl(0, "CursorLine",   { bg = "none" })
      vim.api.nvim_set_hl(0, "Normal",       { bg = "none", fg = palette.fg })
      vim.api.nvim_set_hl(0, "NormalNC",     { bg = "none" })
      vim.api.nvim_set_hl(0, "SignColumn",   { bg = "none" })
      vim.api.nvim_set_hl(0, "NormalFloat",  { bg = "none", fg = palette.fg })
      vim.api.nvim_set_hl(0, "FloatBorder",  { bg = "none", fg = palette.blue1 })
      vim.api.nvim_set_hl(0, "FloatTitle",   { bg = "none", fg = palette.violet1, bold = true })
      vim.api.nvim_set_hl(0, "EndOfBuffer",  { bg = "none", fg = "none" })
      vim.api.nvim_set_hl(0, "CursorLine",   { bg = "none" })


      -- Line numbers
      vim.api.nvim_set_hl(0, "CursorLineNr", { fg = palette.blue4, bold = true })
      vim.api.nvim_set_hl(0, "LineNr",       { fg = palette.gray, bold = true })

      -- Popup menu
      vim.cmd("highlight Pmenu guibg=none")
      vim.cmd("highlight PmenuSel guibg=" .. palette.blue1 .. " guifg=" .. palette.white2 .. " gui=bold")
      vim.cmd("highlight PmenuSbar guibg=none")
      vim.cmd("highlight PmenuThumb guibg=" .. palette.mag1)

      -- Syntax
      vim.api.nvim_set_hl(0, "Comment",    { fg = palette.gray, italic = true })
      vim.api.nvim_set_hl(0, "String",     { fg = palette.blue5 })
      vim.api.nvim_set_hl(0, "Function",   { fg = palette.blue1, bold = true })
      vim.api.nvim_set_hl(0, "Keyword",    { fg = palette.violet1, italic = true })
      vim.api.nvim_set_hl(0, "Identifier", { fg = palette.mag1 })
      vim.api.nvim_set_hl(0, "Constant",   { fg = palette.blue3 })
      vim.api.nvim_set_hl(0, "Type",       { fg = palette.green1 })
      vim.api.nvim_set_hl(0, "Error",      { fg = palette.mag3, bold = true })

      -- Selection & Cursor
      vim.api.nvim_set_hl(0, "Cursor",     { fg = "none", bg = palette.cursor })
      vim.api.nvim_set_hl(0, "Visual",     { bg = palette.sel_bg, fg = palette.sel_fg })

      -- Diagnostics
      vim.api.nvim_set_hl(0, "DiagnosticError", { fg = palette.mag1 })
      vim.api.nvim_set_hl(0, "DiagnosticWarn",  { fg = palette.yellow1 })
      vim.api.nvim_set_hl(0, "DiagnosticInfo",  { fg = palette.blue6 })
      vim.api.nvim_set_hl(0, "DiagnosticHint",  { fg = palette.green1 })

      -- Git integration
      vim.api.nvim_set_hl(0, "GitSignsAdd",    { fg = palette.green1 })
      vim.api.nvim_set_hl(0, "GitSignsChange", { fg = palette.blue5 })
      vim.api.nvim_set_hl(0, "GitSignsDelete", { fg = palette.mag1 })

      -- Telescope
      vim.api.nvim_set_hl(0, "TelescopeBorder", { fg = palette.violet2, bg = "none" })
      vim.api.nvim_set_hl(0, "TelescopeSelection", { fg = palette.blue1, bold = true, bg = "none" })
      vim.api.nvim_set_hl(0, "TelescopePromptPrefix", { fg = palette.mag1, bg = "none" })

      -- Telescope transparency fixes
      vim.api.nvim_set_hl(0, "TelescopeTitle",        { fg = palette.blue1, bg = "none", bold = true })
      vim.api.nvim_set_hl(0, "TelescopePromptTitle",  { fg = palette.mag1,  bg = "none", bold = true })
      vim.api.nvim_set_hl(0, "TelescopeResultsTitle", { fg = palette.violet1, bg = "none", bold = true })
      vim.api.nvim_set_hl(0, "TelescopePreviewTitle", { fg = palette.green1, bg = "none", bold = true })
    end)
  end,
}



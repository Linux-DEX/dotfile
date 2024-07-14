-- This file  needs to have same structure as nvconfig.lua 
-- https://github.com/NvChad/NvChad/blob/v2.5/lua/nvconfig.lua

---@type ChadrcConfig
local M = {}

M.ui = {
	theme = "catppuccin",
  transparency = true,
  telescope = {
    style = "bordered"
  },

  statusline={
    separator_style="round",
    theme = "minimal",
  },

	hl_override = {
		Comment = { italic = true },
		["@comment"] = { italic = true },
	},

  term = {
    hl = "Normal:term,WinSeparator:WinSeparator",
    sizes = { sp = 0.6, vsp = 0.5 },
    float = {
      relative = "editor",
      row = 0.02,
      col = 0.04,
      width = 0.9,
      height = 0.83,
      border = "single",
    },
  },
}

return M

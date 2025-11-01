return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local lualine = require("lualine")
		local lazy_status = require("lazy.status")

		-- Catppuccin Mocha colors
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
            icon = "",
            color = { fg = "#8aadf4" },
          },
        },
        lualine_c = {
          {
            "filename",
            path = 1,
            color = { fg = "#9ca0b0" },
          },
        },
        lualine_x = {
          {
            lazy_status.updates,
            cond = lazy_status.has_updates,
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
  end,
}

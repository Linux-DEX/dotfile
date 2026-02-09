return {
	"echasnovski/mini.animate",
	event = "VeryLazy",
	config = function()
		local animate = require("mini.animate")
		animate.setup({
			cursor = {
				enable = false,
			},
			scroll = {
				enable = true,
				timing = animate.gen_timing.linear({ duration = 150, unit = "total" }),
			},
			resize = {
				enable = false,
			},
			open = {
				enable = false,
			},
			close = {
				enable = false,
			},
		})
	end,
}

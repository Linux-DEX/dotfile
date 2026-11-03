-- nvim-treesitter-textobjects (main-branch API).
-- The old `nvim-treesitter.configs` module is gone, so keymaps now call the
-- select/move/swap modules directly. The full keymap set from the old config
-- is preserved 1:1.
--
-- Requires treesitter highlighting to be enabled (see plugins/treesitter.lua).

require("nvim-treesitter-textobjects").setup({
	select = {
		lookahead = true,
	},
	move = {
		set_jumps = true,
	},
})

local select = require("nvim-treesitter-textobjects.select")
local swap = require("nvim-treesitter-textobjects.swap")
local move = require("nvim-treesitter-textobjects.move")

-- ---------------------------------------------------------------------------
-- Select (same keymaps as the old configs table)
-- ---------------------------------------------------------------------------
local selections = {
	{ "a=", "@assignment.outer", "Select outer part of an assignment" },
	{ "i=", "@assignment.inner", "Select inner part of an assignment" },
	{ "l=", "@assignment.lhs",   "Select left hand side of an assignment" },
	{ "r=", "@assignment.rhs",   "Select right hand side of an assignment" },

	{ "a:", "@property.outer", "Select outer part of an object property" },
	{ "i:", "@property.inner", "Select inner part of an object property" },
	{ "l:", "@property.lhs",   "Select left part of an object property" },
	{ "r:", "@property.rhs",   "Select right part of an object property" },

	{ "aa", "@parameter.outer", "Select outer part of a parameter/argument" },
	{ "ia", "@parameter.inner", "Select inner part of a parameter/argument" },

	{ "ai", "@conditional.outer", "Select outer part of a conditional" },
	{ "ii", "@conditional.inner", "Select inner part of a conditional" },

	{ "al", "@loop.outer", "Select outer part of a loop" },
	{ "il", "@loop.inner", "Select inner part of a loop" },

	{ "af", "@call.outer", "Select outer part of a function call" },
	{ "if", "@call.inner", "Select inner part of a function call" },

	{ "am", "@function.outer", "Select outer part of a method/function definition" },
	{ "im", "@function.inner", "Select inner part of a method/function definition" },

	{ "ac", "@class.outer", "Select outer part of a class" },
	{ "ic", "@class.inner", "Select inner part of a class" },
}

for _, s in ipairs(selections) do
	vim.keymap.set({ "x", "o" }, s[1], function()
		select.select_textobject(s[2], "textobjects")
	end, { desc = s[3] })
end

-- ---------------------------------------------------------------------------
-- Swap
-- ---------------------------------------------------------------------------
local swaps = {
	{ "<leader>na", "swap_next",     "@parameter.inner" },
	{ "<leader>n:", "swap_next",     "@property.outer" },
	{ "<leader>nm", "swap_next",     "@function.outer" },
	{ "<leader>pa", "swap_previous", "@parameter.inner" },
	{ "<leader>p:", "swap_previous", "@property.outer" },
	{ "<leader>pm", "swap_previous", "@function.outer" },
}

for _, s in ipairs(swaps) do
	vim.keymap.set("n", s[1], function()
		swap[s[2]](s[3])
	end, { desc = ("Swap with %s"):format(s[2] == "swap_next" and "next" or "previous") })
end

-- ---------------------------------------------------------------------------
-- Move (same keymaps/queries as the old configs table)
-- ---------------------------------------------------------------------------
local function move_keymap(key, fn, query, group, desc)
	vim.keymap.set({ "n", "x", "o" }, key, function()
		fn(query, group)
	end, { desc = desc })
end

move_keymap("]f", move.goto_next_start,        "@call.outer",       "textobjects", "Next function call start")
move_keymap("]m", move.goto_next_start,        "@function.outer",   "textobjects", "Next method/function def start")
move_keymap("]c", move.goto_next_start,        "@class.outer",      "textobjects", "Next class start")
move_keymap("]i", move.goto_next_start,        "@conditional.outer", "textobjects", "Next conditional start")
move_keymap("]l", move.goto_next_start,        "@loop.outer",       "textobjects", "Next loop start")
move_keymap("]s", move.goto_next_start,        "@scope",            "locals",      "Next scope")
move_keymap("]z", move.goto_next_start,        "@fold",             "folds",       "Next fold")

move_keymap("]F", move.goto_next_end,          "@call.outer",       "textobjects", "Next function call end")
move_keymap("]M", move.goto_next_end,          "@function.outer",   "textobjects", "Next method/function def end")
move_keymap("]C", move.goto_next_end,          "@class.outer",      "textobjects", "Next class end")
move_keymap("]I", move.goto_next_end,          "@conditional.outer", "textobjects", "Next conditional end")
move_keymap("]L", move.goto_next_end,          "@loop.outer",       "textobjects", "Next loop end")

move_keymap("[f", move.goto_previous_start,    "@call.outer",       "textobjects", "Prev function call start")
move_keymap("[m", move.goto_previous_start,    "@function.outer",   "textobjects", "Prev method/function def start")
move_keymap("[c", move.goto_previous_start,    "@class.outer",      "textobjects", "Prev class start")
move_keymap("[i", move.goto_previous_start,    "@conditional.outer", "textobjects", "Prev conditional start")
move_keymap("[l", move.goto_previous_start,    "@loop.outer",       "textobjects", "Prev loop start")

move_keymap("[F", move.goto_previous_end,      "@call.outer",       "textobjects", "Prev function call end")
move_keymap("[M", move.goto_previous_end,      "@function.outer",   "textobjects", "Prev method/function def end")
move_keymap("[C", move.goto_previous_end,      "@class.outer",      "textobjects", "Prev class end")
move_keymap("[I", move.goto_previous_end,      "@conditional.outer", "textobjects", "Prev conditional end")
move_keymap("[L", move.goto_previous_end,      "@loop.outer",       "textobjects", "Prev loop end")

-- ---------------------------------------------------------------------------
-- Repeatable movements (; forward / , backward, like "vim way" in the old config)
-- ---------------------------------------------------------------------------
local ts_repeat_move = require("nvim-treesitter-textobjects.repeatable_move")

vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move)
vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_opposite)

vim.keymap.set({ "n", "x", "o" }, "f", ts_repeat_move.builtin_f_expr, { expr = true })
vim.keymap.set({ "n", "x", "o" }, "F", ts_repeat_move.builtin_F_expr, { expr = true })
vim.keymap.set({ "n", "x", "o" }, "t", ts_repeat_move.builtin_t_expr, { expr = true })
vim.keymap.set({ "n", "x", "o" }, "T", ts_repeat_move.builtin_T_expr, { expr = true })

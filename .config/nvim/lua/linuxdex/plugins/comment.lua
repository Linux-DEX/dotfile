local comment = require("Comment")
local ts_context_commentstring = require("ts_context_commentstring.integrations.comment_nvim")

local ts_pre_hook = ts_context_commentstring.create_pre_hook()

comment.setup({
	pre_hook = function(ctx)
		-- Fall back to the buffer commentstring when treesitter has no match.
		-- Without this, Comment.nvim hits a nil treesitter parser and warns "[Comment.nvim] nil".
		return ts_pre_hook(ctx) or vim.bo.commentstring
	end,
})

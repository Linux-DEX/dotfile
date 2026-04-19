local lint = require("lint")

lint.linters_by_ft = {
	javascript = { "eslint_d" },
	typescript = { "eslint_d" },
	javascriptreact = { "eslint_d" },
	typescriptreact = { "eslint_d" },
	python = { "pylint" },
	lua = { "luacheck" },
	markdown = { "markdownlint" },
}

-- Debounce function to avoid running linters too frequently
local function debounce(ms, fn)
	local timer = vim.uv.new_timer()
	return function(...)
		local argv = { ... }
		timer:start(ms, 0, function()
			timer:stop()
			vim.schedule_wrap(fn)(unpack(argv))
		end)
	end
end

-- Smart lint function
local function lint_file()
	local names = lint._resolve_linter_by_ft(vim.bo.filetype)

	local ctx = { filename = vim.api.nvim_buf_get_name(0) }
	ctx.dirname = vim.fn.fnamemodify(ctx.filename, ":h")

	names = vim.tbl_filter(function(name)
		local linter = lint.linters[name]
		if not linter then
			vim.notify("Linter not found: " .. name, vim.log.levels.WARN)
			return false
		end
		return true
	end, names)

	if #names > 0 then
		lint.try_lint(names)
	end
end

local lint_augroup = vim.api.nvim_create_augroup("nvim-lint", { clear = true })

vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
	group = lint_augroup,
	callback = debounce(100, lint_file),
})

vim.keymap.set("n", "<leader>l", function()
	lint_file()
end, { desc = "Trigger linting for current file" })

-- Treesitter via the new nvim-treesitter (main-branch) API for Neovim 0.11/0.12+.
-- NOTE: the old `nvim-treesitter.configs` module no longer exists, so this file
-- replaces the entire old configs.setup block. Every feature it had is preserved:
--   * highlighting for the same language list        -> vim.treesitter.start() below
--   * indent = { enable = true }                     -> nvim-treesitter indentexpr below
--   * autotag                                        -> standalone nvim-ts-autotag.setup()
--   * incremental_selection (<C-space> / <bs>)       -> small custom implementation below
-- Large files are skipped via core/large-file.lua (`vim.b.large`).
--
-- Requirements for parser compilation: the `tree-sitter` CLI (>= 0.26), tar,
-- curl and a C compiler. Parsers install to stdpath('data')/site.

local ts_ok, ts = pcall(require, "nvim-treesitter")
if not ts_ok then
	return
end

-- Same languages as the old config
local languages = {
	"json",
	"javascript",
	"typescript",
	"tsx",
	"yaml",
	"html",
	"css",
	"prisma",
	"markdown",
	"markdown_inline",
	"bash",
	"lua",
	"vim",
	"dockerfile",
	"gitignore",
	"query",
	"vimdoc",
	"c",
	"go",
}

-- install() is a no-op for already-installed parsers (downloads/compiles asynchronously)
if vim.fn.executable("tree-sitter") == 1 then
	ts.install(languages)
else
	vim.defer_fn(function()
		vim.notify_once(
			"Install the 'tree-sitter' CLI (>= 0.26) to compile treesitter parsers for:\n  "
				.. table.concat(languages, ", "),
			vim.log.levels.INFO
		)
	end, 3000)
end

-- Autotag now has a standalone setup (was dead code in the old configs.setup)
do
	local autotag_ok, autotag = pcall(require, "nvim-ts-autotag")
	if autotag_ok and autotag then
		autotag.setup({})
	end
end

-- Treesitter highlighting + indentation for every filetype with a parser
-- (0.12's built-in `syntaxset` autocmd then skips legacy syntax for these buffers,
--  so there is no double highlighting)
vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("linuxdex_treesitter", { clear = true }),
	callback = function(args)
		-- large-file policy: no treesitter work on huge buffers
		if vim.b[args.buf].large then
			return
		end
		local ft = args.match
		local lang = vim.treesitter.language.get_lang(ft) or ft
		if not lang or not pcall(vim.treesitter.language.add, lang) then
			return
		end
		-- indentation (replaces the dead indent = { enable = true })
		vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
		-- highlighting
		pcall(vim.treesitter.start, args.buf, lang)
	end,
})

-- ---------------------------------------------------------------------------
-- Incremental selection: same keys as the old treesitter.configs feature
-- (init/grow on <C-space> in normal/visual, shrink on <bs> in visual mode)
-- ---------------------------------------------------------------------------
do
	local stack = nil

	local function named_node(node)
		while node and not node:named() do
			node = node:parent()
		end
		return node
	end

	local function select_node(node)
		local sr, sc, er, ec = node:range()
		vim.fn.cursor(sr + 1, sc + 1)
		vim.cmd("normal! v")
		vim.fn.cursor(er + 1, math.max(ec, 1))
	end

	vim.keymap.set("n", "<C-Space>", function()
		local ok, node = pcall(vim.treesitter.get_node)
		if not ok or not node then
			return
		end
		node = named_node(node)
		if node then
			stack = {}
			table.insert(stack, node)
			select_node(node)
		end
	end, { desc = "Init treesitter selection" })

	vim.keymap.set("x", "<C-Space>", function()
		if not stack or #stack == 0 then
			-- resume from the node under the visual start
			stack = {}
			local ok, node = pcall(vim.treesitter.get_node, { pos = { vim.fn.line("v") - 1, 0 } })
			if not ok or not node then
				return
			end
			node = named_node(node)
			if node then
				table.insert(stack, node)
				select_node(node)
			end
			return
		end
		local parent = stack[#stack]:parent()
		if not parent or parent:range() == stack[#stack]:range() then
			return
		end
		parent = named_node(parent)
		if not parent then
			return
		end
		table.insert(stack, parent)
		select_node(parent)
	end, { desc = "Grow treesitter selection" })

	vim.keymap.set("x", "<Bs>", function()
		if not stack or #stack == 0 then
			return
		end
		table.remove(stack)
		local target = named_node(stack[#stack])
		if target then
			select_node(target)
		else
			vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, true, true), "n")
			stack = nil
		end
	end, { desc = "Shrink treesitter selection" })
end

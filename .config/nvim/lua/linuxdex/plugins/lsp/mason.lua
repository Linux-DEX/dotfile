local mason = require("mason")
local mason_lspconfig = require("mason-lspconfig")
local mason_tool_installer = require("mason-tool-installer")

mason.setup({
	ui = {
		icons = {
			package_installed = "✓",
			package_pending = "➜",
			package_uninstalled = "✗",
		},
	},
})

mason_lspconfig.setup({
	ensure_installed = {
		"ts_ls",
		"html",
		"cssls",
		"tailwindcss",
		"lua_ls",
		"emmet_ls",
		"pyright",
		"ruff",
		"eslint",
		"gopls",
		"marksman",
	},
})

mason_tool_installer.setup({
	ensure_installed = {
		"prettier",
		"stylua",
		"markdownlint",
		"eslint_d",
		"clangd",
		"ruff",
		"goimports",
	},
})

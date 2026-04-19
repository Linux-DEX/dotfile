local null_ls = require("null-ls")

null_ls.setup({
	on_attach = function(client, _)
		client.server_capabilities.diagnosticProvider = false
	end,

	sources = {
		null_ls.builtins.formatting.prettier,
		null_ls.builtins.formatting.stylua,
		null_ls.builtins.formatting.black,
		null_ls.builtins.formatting.isort,
		null_ls.builtins.formatting.gofmt,
		null_ls.builtins.formatting.goimports,
		null_ls.builtins.diagnostics.markdownlint,
	},
})

return {
	"nvimtools/none-ls.nvim", -- new name of null-ls
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local null_ls = require("null-ls")

		null_ls.setup({
			-- disable diagnostics at the client level
			on_attach = function(client, _)
				client.server_capabilities.diagnosticProvider = false
			end,

			sources = {
				-- FORMATTERS ONLY 
				null_ls.builtins.formatting.prettier,
				null_ls.builtins.formatting.stylua,
				null_ls.builtins.formatting.black,
				null_ls.builtins.formatting.isort,
				null_ls.builtins.formatting.gofmt,
				null_ls.builtins.formatting.goimports,
        null_ls.builtins.diagnostics.markdownlint,
			},
		})
	end,
}

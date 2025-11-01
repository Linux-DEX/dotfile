return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		{ "antosha417/nvim-lsp-file-operations", config = true },
		{ "folke/neodev.nvim", opts = {} },
	},
	config = function()
		-- import cmp-nvim-lsp plugin
		local cmp_nvim_lsp = require("cmp_nvim_lsp")

		-- Custom goto definition that opens in new tab using 'tab drop'
		local function goto_definition_tabdrop()
			local client = vim.lsp.get_clients({ bufnr = 0 })[1]
			if not client then
				vim.notify("No active LSP client", vim.log.levels.WARN)
				return
			end

			local encoding = client.offset_encoding or "utf-16"
			local params = vim.lsp.util.make_position_params(nil, encoding)

			vim.lsp.buf_request(0, "textDocument/definition", params, function(err, result, ctx, _)
				if err then
					vim.notify("Error when finding definition: " .. err.message, vim.log.levels.ERROR)
					return
				end
				if not result or vim.tbl_isempty(result) then
					vim.notify("No definition found", vim.log.levels.INFO)
					return
				end

				-- handle multiple results
				local def = result[1] or result
				if def.uri == nil and def.targetUri then
					def.uri = def.targetUri
					def.range = def.targetSelectionRange
				end

				local filename = vim.uri_to_fname(def.uri)
				if not filename or filename == "" then
					vim.notify("No file found for definition", vim.log.levels.ERROR)
					return
				end

				vim.cmd("tab drop " .. vim.fn.fnameescape(filename))
				local row = (def.range.start.line or 0) + 1
				local col = def.range.start.character or 0
				vim.api.nvim_win_set_cursor(0, { row, col })
			end)
		end

		local keymap = vim.keymap -- for conciseness
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(ev)
				-- Buffer local mappings.
				-- See `:help vim.lsp.*` for documentation on any of the below functions
				local opts = { buffer = ev.buf, silent = true }

				-- set keybinds
				opts.desc = "Show LSP references"
				keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts) -- show definition, references

				opts.desc = "Go to declaration"
				keymap.set("n", "gD", vim.lsp.buf.declaration, opts) -- go to declaration

				-- opts.desc = "Show LSP definitions"
				-- keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts) -- show lsp definitions
				opts.desc = "Show LSP definitions"
				-- keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts) -- show lsp definitions
				keymap.set(
					"n",
					"gd",
					goto_definition_tabdrop,
					vim.tbl_extend("force", opts, { desc = "Go to definition (tab drop)" })
				)

				opts.desc = "Show LSP implementations"
				-- keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts) -- show lsp implementations
				keymap.set(
					"n",
					"gi",
					vim.lsp.buf.implementation,
					vim.tbl_extend("force", opts, { desc = "Go to implementation" })
				)

				opts.desc = "Show LSP type definitions"
				keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts) -- show lsp type definitions

				opts.desc = "See available code actions"
				keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts) -- see available code actions, in visual mode will apply to selection

				opts.desc = "Smart rename"
				keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts) -- smart rename

				opts.desc = "Show buffer diagnostics"
				keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts) -- show  diagnostics for file

				opts.desc = "Show line diagnostics"
				keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts) -- show diagnostics for line

				opts.desc = "Go to previous diagnostic"
				keymap.set("n", "[d", vim.diagnostic.goto_prev, opts) -- jump to previous diagnostic in buffer

				opts.desc = "Go to next diagnostic"
				keymap.set("n", "]d", vim.diagnostic.goto_next, opts) -- jump to next diagnostic in buffer

				opts.desc = "Show documentation for what is under cursor"
				keymap.set("n", "K", vim.lsp.buf.hover, opts) -- show documentation for what is under cursor

				opts.desc = "Restart LSP"
				keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts) -- mapping to restart lsp if necessary
			end,
		})

		-- used to enable autocompletion (assign to every lsp server config)
		local capabilities = cmp_nvim_lsp.default_capabilities()

		vim.diagnostic.config({
			signs = {
				text = {
					[vim.diagnostic.severity.ERROR] = " ",
					[vim.diagnostic.severity.WARN] = " ",
					[vim.diagnostic.severity.HINT] = "󰠠 ",
					[vim.diagnostic.severity.INFO] = " ",
				},
			},
			virtual_lines = { current_line = true },
			underline = true,
			update_in_insert = false,
		})

		vim.lsp.config("*", {
			capabilities = capabilities,
		})

		vim.lsp.config("svelte", {
			on_attach = function(client, bufnr)
				vim.api.nvim_create_autocmd("BufWritePost", {
					pattern = { "*.js", "*.ts" },
					callback = function(ctx)
						-- Here use ctx.match instead of ctx.file
						client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
					end,
				})
			end,
		})

		vim.lsp.config("graphql", {
			filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
		})

		vim.lsp.config("emmet_ls", {
			filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "svelte" },
		})

		vim.lsp.config("eslint", {
			filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "svelte" },
		})

		vim.lsp.config("lua_ls", {
			settings = {
				Lua = {
					diagnostics = {
						globals = { "vim" },
					},
					completion = {
						callSnippet = "Replace",
					},
				},
			},
		})

		vim.lsp.config("gopls", {
			settings = {
				gopls = {
					analyses = {
						unusedparams = true,
						shadow = true,
					},
					staticcheck = true,
				},
			},
		})

		vim.lsp.config("ts_ls", {
			capabilities = capabilities,
			filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
		})

		-- vim.lsp.config("pyright", {
		-- 	before_init = function(params)
		-- 		local util = require("lspconfig/util")
		-- 		local root_dir = util.find_git_ancestor(params.rootUri) or vim.fn.getcwd()
		-- 		local venv_path = root_dir .. "/.venv/bin/python"
		--
		-- 		if vim.fn.executable(venv_path) == 1 then
		-- 			-- just print for debugging
		-- 			-- print("Using python interpreter: " .. venv_path)
		--
		-- 			-- set pythonPath in settings (preferred by pyright)
		-- 			params.settings = params.settings or {}
		-- 			params.settings.python = params.settings.python or {}
		-- 			params.settings.python.pythonPath = venv_path
		-- 		end
		-- 	end,
		-- 	settings = {
		-- 		python = {
		-- 			analysis = {
		-- 				autoSearchPaths = true,
		-- 				useLibraryCodeForTypes = true,
		-- 				diagnosticMode = "workspace",
		-- 			},
		-- 		},
		-- 	},
		-- })

    vim.lsp.config("tailwindcss", {
      filetypes = {
        "html",
        "css",
        "javascript",
        "typescript",
        "javascriptreact",
        "typescriptreact",
        "vue",
        "svelte",
        "astro",
      },
    })

    vim.lsp.config("pyright", {
      settings = {
        python = {
          venvPath = ".",
          venv = ".venv",
          analysis = {
            autoSearchPaths = true,
            useLibraryCodeForTypes = true,
          },
        },
      },
    })

  end,
}

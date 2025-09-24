-- return {
--   "neovim/nvim-lspconfig",
--   event = { "BufReadPre", "BufNewFile" },
--   dependencies = {
--     "hrsh7th/cmp-nvim-lsp",
--     { "antosha417/nvim-lsp-file-operations", config = true },
--   },
--   config = function()
--     local lspconfig = require("lspconfig")
--     local cmp_nvim_lsp = require("cmp_nvim_lsp")
--     local capabilities = vim.tbl_deep_extend(
--       "force",
--       vim.lsp.protocol.make_client_capabilities(),
--       cmp_nvim_lsp.default_capabilities()
--     )
--
--     -- Custom goto definition that opens in new tab using 'tab drop'
--     local function goto_definition_tabdrop()
--       local client = vim.lsp.get_clients({ bufnr = 0 })[11]
--       local encoding = (client and (client.offset_encoding or client.offsetEncoding)) or "utf-16"
--       local params = vim.lsp.util.make_position_params(nil, encoding)
--
--       vim.lsp.buf_request(0, "textDocument/definition", params, function(err, result, ctx, config)
--         if err or not result or vim.tbl_isempty(result) then
--           vim.notify("No definition found", vim.log.levels.INFO)
--           return
--         end
--         local def = (type(result) == "table" and #result > 0) and result[1] or result
--         local uri = def.uri or def.targetUri
--         local range = def.range or def.targetSelectionRange
--         local filename = vim.uri_to_fname(uri)
--         if not filename or filename == "" then
--           vim.notify("No file found for definition", vim.log.levels.ERROR)
--           return
--         end
--         vim.cmd("tab drop " .. vim.fn.fnameescape(filename))
--         local row = (range.start.line or 0) + 1
--         local col = (range.start.character or 0)
--         vim.api.nvim_win_set_cursor(0, { row, col })
--       end)
--     end
--
--
--     vim.api.nvim_create_autocmd("LspAttach", {
--       group = vim.api.nvim_create_augroup("UserLspConfig", {}),
--       callback = function(ev)
--         local opts = { buffer = ev.buf, silent = true }
--         vim.keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", vim.tbl_extend("force", opts, { desc = "Show LSP references" }))
--         vim.keymap.set("n", "gD", vim.lsp.buf.declaration, vim.tbl_extend("force", opts, { desc = "Go to declaration" }))
--         vim.keymap.set("n", "gd", goto_definition_tabdrop, vim.tbl_extend("force", opts, { desc = "Go to definition (tab drop)" }))
--         vim.keymap.set("n", "gi", vim.lsp.buf.implementation, vim.tbl_extend("force", opts, { desc = "Go to implementation" }))
--         vim.keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", vim.tbl_extend("force", opts, { desc = "Show LSP type definitions" }))
--         vim.keymap.set({ "n", "v" }, "<leader>vca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "See available code actions" }))
--         vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Smart rename" }))
--         vim.keymap.set("n", "<leader>D>", "<cmd>Telescope diagnostics bufnr=0<CR>", vim.tbl_extend("force", opts, { desc = "Show buffer diagnostics" }))
--         vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, vim.tbl_extend("force", opts, { desc = "Show line diagnostics" }))
--         vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Show documentation under cursor" }))
--         vim.keymap.set("n", "<leader>rs", ":LspRestart<CR>", vim.tbl_extend("force", opts, { desc = "Restart LSP" }))
--         vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, vim.tbl_extend("force", opts, { desc = "Show signature help" }))
--       end,
--     })
--
--     local signs = {
--       [vim.diagnostic.severity.ERROR] = " ",
--       [vim.diagnostic.severity.WARN] = " ",
--       [vim.diagnostic.severity.HINT] = "󰠠 ",
--       [vim.diagnostic.severity.INFO] = " ",
--     }
--     vim.diagnostic.config({
--       signs = { text = signs },
--       virtual_lines = { current_line = true },
--       underline = true,
--       update_in_insert = false,
--     })
--
--     lspconfig.lua_ls.setup({
--       capabilities = capabilities,
--       settings = {
--         Lua = {
--           diagnostics = { globals = { "vim" } },
--           completion = { callSnippet = "Replace" },
--           workspace = {
--             library = {
--               [vim.fn.expand("$VIMRUNTIME/lua")] = true,
--               [vim.fn.stdpath("config") .. "/lua"] = true,
--             },
--           },
--         },
--       },
--     })
--
--     lspconfig.emmet_ls.setup({
--       capabilities = capabilities,
--       filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "svelte" },
--     })
--
--     lspconfig.emmet_language_server.setup({
--       capabilities = capabilities,
--       filetypes = {
--         "css", "eruby", "html", "javascript", "javascriptreact",
--         "less", "sass", "scss", "pug", "typescriptreact"
--       },
--       init_options = {
--         showAbbreviationSuggestions = true,
--         showExpandedAbbreviation = "always",
--         showSuggestionsAsSnippets = false,
--       },
--     })
--
--     lspconfig.ts_ls.setup({
--       capabilities = capabilities,
--       root_dir = function(fname)
--         local util = require("lspconfig.util")
--         return not util.root_pattern("deno.json", "deno.jsonc")(fname)
--           and util.root_pattern("tsconfig.json", "package.json", "jsconfig.json", ".git")(fname)
--       end,
--       single_file_support = false,
--       on_attach = function(client)
--         client.server_capabilities.documentFormattingProvider = false
--       end,
--       init_options = {
--         preferences = {
--           includeCompletionsWithSnippetText = true,
--           includeCompletionsForImportStatements = true,
--         },
--       },
--     })
--
--
--     lspconfig.tailwindcss.setup({
--       capabilities = capabilities,
--       cmd = { "tailwindcss-language-server", "--stdio" },
--       filetypes = { "html", "css", "scss", "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
--       root_dir = require("lspconfig.util").root_pattern("tailwind.config.js", "package.json"),
--     })
--
--     -- Other servers
--     lspconfig.html.setup({ capabilities = capabilities })
--     lspconfig.cssls.setup({ capabilities = capabilities })
--     lspconfig.gopls.setup({ capabilities = capabilities })
--     lspconfig.clangd.setup({ capabilities = capabilities })
--     lspconfig.pyright.setup({
--       capabilities = capabilities,
--       settings = {
--         python = {
--           analysis = {
--             typeCheckingMode = "basic",
--             autoSearchPaths = true,
--             useLibraryCodeForTypes = true,
--             diagnosticMode = "workspace",
--           },
--         },
--       },
--     })
--   end,
-- }


return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    { "antosha417/nvim-lsp-file-operations", config = true },
  },
  config = function()
    local capabilities = require("cmp_nvim_lsp").default_capabilities()

    local function goto_definition_tabdrop()
      local clients = vim.lsp.get_clients({ bufnr = 0 })
      local client = clients[1]
      local encoding = (client and (client.offset_encoding or client.offsetEncoding)) or "utf-16"
      local params = vim.lsp.util.make_position_params(nil, encoding)
      vim.lsp.buf_request(0, "textDocument/definition", params, function(err, result)
        if err or not result or vim.tbl_isempty(result) then
          vim.notify("No definition found", vim.log.levels.INFO)
          return
        end
        local def = (type(result) == "table" and #result > 0) and result[1] or result
        local uri = def.uri or def.targetUri
        local range = def.range or def.targetSelectionRange
        local filename = vim.uri_to_fname(uri)
        if not filename or filename == "" then
          vim.notify("No file found for definition", vim.log.levels.ERROR)
          return
        end
        vim.cmd("tab drop " .. vim.fn.fnameescape(filename))
        local row = (range.start.line or 0) + 1
        local col = (range.start.character or 0)
        vim.api.nvim_win_set_cursor(0, { row, col })
      end)
    end

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspConfig", {}),
      callback = function(ev)
        local opts = { buffer = ev.buf, silent = true }
        vim.keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", vim.tbl_extend("force", opts, { desc = "Show LSP references" }))
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, vim.tbl_extend("force", opts, { desc = "Go to declaration" }))
        vim.keymap.set("n", "gd", goto_definition_tabdrop, vim.tbl_extend("force", opts, { desc = "Go to definition (tab drop)" }))
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, vim.tbl_extend("force", opts, { desc = "Go to implementation" }))
        vim.keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", vim.tbl_extend("force", opts, { desc = "Show LSP type definitions" }))
        vim.keymap.set({ "n", "v" }, "<leader>vca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "See available code actions" }))
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Smart rename" }))
        vim.keymap.set("n", "<leader>D>", "<cmd>Telescope diagnostics bufnr=0<CR>", vim.tbl_extend("force", opts, { desc = "Show buffer diagnostics" }))
        vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, vim.tbl_extend("force", opts, { desc = "Show line diagnostics" }))
        vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Show documentation under cursor" }))
        vim.keymap.set("n", "<leader>rs", ":LspRestart<CR>", vim.tbl_extend("force", opts, { desc = "Restart LSP" }))
        vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, vim.tbl_extend("force", opts, { desc = "Show signature help" }))
      end,
    })

    local signs = {
      [vim.diagnostic.severity.ERROR] = " ",
      [vim.diagnostic.severity.WARN] = " ",
      [vim.diagnostic.severity.HINT] = "󰠠 ",
      [vim.diagnostic.severity.INFO] = " ",
    }
    vim.diagnostic.config({
      signs = { text = signs },
      virtual_lines = { current_line = true },
      underline = true,
      update_in_insert = false,
    })

    -- Language servers list
    local servers = {
      lua_ls = {
        capabilities = capabilities,
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            completion = { callSnippet = "Replace" },
            workspace = {
              library = {
                [vim.fn.expand("$VIMRUNTIME/lua")] = true,
                [vim.fn.stdpath("config") .. "/lua"] = true,
              },
            },
          },
        },
      },
      emmet_ls = {
        capabilities = capabilities,
        filetypes = {
          "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "svelte",
          "eruby", "pug", "typescriptreact",
        },
        init_options = {
          showAbbreviationSuggestions = true,
          showExpandedAbbreviation = "always",
          showSuggestionsAsSnippets = false,
        },
      },
      tsserver = {
        capabilities = capabilities,
        root_dir = function(fname)
          local util = require("lspconfig.util")
          return not util.root_pattern("deno.json", "deno.jsonc")(fname)
            and util.root_pattern("tsconfig.json", "package.json", "jsconfig.json", ".git")(fname)
        end,
        single_file_support = false,
        on_attach = function(client)
          client.server_capabilities.documentFormattingProvider = false
        end,
        init_options = {
          preferences = {
            includeCompletionsWithSnippetText = true,
            includeCompletionsForImportStatements = true,
          },
        },
      },
      tailwindcss = {
        capabilities = capabilities,
        cmd = { "tailwindcss-language-server", "--stdio" },
        filetypes = { "html", "css", "scss", "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
        root_dir = require("lspconfig.util").root_pattern("tailwind.config.js", "package.json"),
      },
      html = { capabilities = capabilities },
      cssls = { capabilities = capabilities },
      gopls = { capabilities = capabilities },
      clangd = { capabilities = capabilities },
      pyright = {
        capabilities = capabilities,
        settings = {
          python = {
            analysis = {
              typeCheckingMode = "basic",
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              diagnosticMode = "workspace",
            },
          },
        },
      },
    }

    -- Register and enable servers
    for name, config in pairs(servers) do
      vim.lsp.config(name, config)
      vim.lsp.enable(name)
    end
  end,
}


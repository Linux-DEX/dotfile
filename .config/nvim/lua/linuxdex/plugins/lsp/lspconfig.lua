local cmp_nvim_lsp = require("cmp_nvim_lsp")
local capabilities = cmp_nvim_lsp.default_capabilities()

-- Servers are resolved on the first FileType, which runs before formatting.lua
-- prepends Mason's bin. Put it on PATH now so `lua-language-server` et al. exist.
local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
if not vim.env.PATH:find(mason_bin, 1, true) then
    vim.env.PATH = mason_bin .. ":" .. vim.env.PATH
end

-- Disable LSP progress notifications (prevents annoying pyright/lua_ls messages)
vim.lsp.handlers["$/progress"] = function() end

-- LSP ATTACH (keymaps + inlay hints + codelens)
vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspConfig", {}),
    callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        local keymap = vim.keymap
        local opts = { buffer = ev.buf, silent = true }
        local large_buf = vim.b[ev.buf].large == true

        -- Inlay Hints (skipped on large files, toggleable manually)
        if client and not large_buf and client:supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
        end

        -- CodeLens (skipped on large files)
        if client and not large_buf and client:supports_method("textDocument/codeLens") then
            vim.lsp.codelens.enable(true, { bufnr = ev.buf })
        end

        -- Keymaps
        opts.desc = "Show LSP references"
        keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts)

        opts.desc = "Go to declaration"
        keymap.set("n", "gD", vim.lsp.buf.declaration, opts)

        opts.desc = "Show LSP definitions"
        keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)

        opts.desc = "Show LSP implementations"
        keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)

        opts.desc = "Show LSP type definitions"
        keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts)

        opts.desc = "Code actions"
        keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)

        opts.desc = "Rename symbol"
        keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

        opts.desc = "Buffer diagnostics"
        keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts)

        opts.desc = "Line diagnostics"
        keymap.set("n", "<leader>d", function()
            vim.diagnostic.open_float({ border = "rounded" })
        end, opts)

        opts.desc = "Previous diagnostic"
        keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)

        opts.desc = "Next diagnostic"
        keymap.set("n", "]d", vim.diagnostic.goto_next, opts)

        opts.desc = "Hover documentation"
        keymap.set("n", "K", function()
            vim.lsp.buf.hover({ border = "rounded" })
        end, opts)

        opts.desc = "Run CodeLens"
        keymap.set("n", "<leader>cl", vim.lsp.codelens.run, opts)

        opts.desc = "Restart LSP"
        keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts)
    end,
})

-- Auto refresh CodeLens (skipped on large files)
vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
    callback = function(args)
        if vim.b[args.buf].large then
            return
        end
        if vim.lsp.get_clients({ bufnr = args.buf })[1] then
            vim.lsp.codelens.enable(true, { bufnr = args.buf })
        end
    end,
})

-- LSP Folding: configured in core/large-file.lua
-- (expr folds on all normal files; large buffers open with manual folds
--  and can enable them on demand via :FoldAny)

-- set floating window borders

-- Diagnostics (ERROR only)
vim.diagnostic.config({
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.HINT] = "",
            [vim.diagnostic.severity.INFO] = "",
        },
    },
    virtual_lines = {
        current_line = true,
        severity = { min = vim.diagnostic.severity.WARN },
    },
    underline = {
        severity = { min = vim.diagnostic.severity.WARN },
    },
    update_in_insert = false,
    severity_sort = true,
})

vim.lsp.config("*", {
    capabilities = capabilities,
})

-- Language Servers
vim.lsp.config("lua_ls", {
    capabilities = capabilities,
    settings = {
        Lua = {
            diagnostics = { globals = { "vim" } },
            completion = { callSnippet = "Replace" },
        },
    },
})

vim.lsp.enable("lua_ls")

vim.lsp.config("gopls", {
    capabilities = capabilities,
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

vim.lsp.enable("gopls")

vim.lsp.config("ts_ls", {
    capabilities = capabilities,
    filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
    },
})

vim.lsp.enable("ts_ls")

vim.lsp.config("pyright", {
    capabilities = capabilities,
    filetypes = { "python" },
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

vim.lsp.enable("pyright")

vim.lsp.config("emmet_ls", {
    filetypes = {
        "html",
        "typescriptreact",
        "javascriptreact",
        "typescript",
        "javascript",
        "css",
        "sass",
        "scss",
        "less",
        "svelte",
    },
})

vim.lsp.enable("emmet_ls")

vim.lsp.config("tailwindcss", {
    capabilities = capabilities,
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

vim.lsp.enable("tailwindcss")

-- Files passed on the command line get FileType during init, before
-- vim.lsp.enable() installs its autocmd, so that buffer never attaches.
vim.schedule(function()
    if vim.fn.exists("#nvim.lsp.enable") == 1 then
        vim.cmd("doautoall nvim.lsp.enable FileType")
    end
end)

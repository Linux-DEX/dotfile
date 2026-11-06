local cmp = require("cmp")
local luasnip = require("luasnip")
local lspkind = require("lspkind")

-- Load vscode style snippets
require("luasnip.loaders.from_vscode").lazy_load()

cmp.setup({
    window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
    },
    completion = {
        -- `preview` makes Nvim open the native preview window and hides cmp's menu.
        completeopt = "menu,menuone,noselect",
    },
    snippet = {
        expand = function(args)
            luasnip.lsp_expand(args.body)
        end,
    },
    mapping = cmp.mapping.preset.insert({
        ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
            elseif luasnip.expand_or_locally_jumpable() then
                luasnip.expand_or_jump()
            else
                fallback()
            end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
            elseif luasnip.locally_jumpable(-1) then
                luasnip.jump(-1)
            else
                fallback()
            end
        end, { "i", "s" }),
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<C-e>"] = cmp.mapping.abort(),
        ["<CR>"] = cmp.mapping.confirm({ select = false }),
    }),
    sources = cmp.config.sources({
        { name = "nvim_lsp", priority = 1000 },
        -- snippets: language syntax (fn, if, for, ...) from friendly-snippets
        { name = "luasnip", priority = 750 },
        {
            name = "buffer",
            priority = 500,
            -- default is 3, so short words in the file never show up
            option = {
                keyword_length = 2,
                get_bufnrs = function()
                    local bufs = {}
                    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                        if vim.api.nvim_buf_is_loaded(buf) and not vim.b[buf].large then
                            bufs[#bufs + 1] = buf
                        end
                    end
                    return bufs
                end,
            },
        },
        { name = "path", priority = 250 },
    }),
    formatting = {
        format = lspkind.cmp_format({
            maxwidth = 50,
            ellipsis_char = "...",
            menu = {
                nvim_lsp = "[LSP]",
                luasnip = "[Snippet]",
                buffer = "[Buf]",
                path = "[Path]",
            },
        }),
    },
})

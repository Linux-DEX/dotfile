-- Plugin management using Neovim 0.12 built-in vim.pack
-- Replaces lazy.nvim

local gh = function(x)
    return "https://github.com/" .. x
end

-- Lazy loading helper
--- Creates a load function that defers plugin loading until a command or keymap is used.
--- @param plugin_name string
--- @param cmds string[] Commands to stub
--- @param keymaps? table[] Keymaps: { mode, lhs, rhs_cmd_string, opts }
--- @param on_load? function Called after packadd
local function lazy_load(plugin_name, cmds, keymaps, on_load)
    return function(_data)
        local loaded = false
        local function ensure_loaded()
            if loaded then
                return
            end
            loaded = true
            for _, cmd in ipairs(cmds) do
                pcall(vim.api.nvim_del_user_command, cmd)
            end
            vim.cmd.packadd(plugin_name)
            if on_load then
                on_load()
            end
        end

        for _, cmd in ipairs(cmds) do
            vim.api.nvim_create_user_command(cmd, function(args)
                ensure_loaded()
                vim.cmd(cmd .. " " .. args.args)
            end, { nargs = "*", bang = true })
        end

        if keymaps then
            for _, km in ipairs(keymaps) do
                vim.keymap.set(km[1], km[2], function()
                    ensure_loaded()
                    if type(km[3]) == "string" then
                        vim.cmd(km[3])
                    elseif type(km[3]) == "function" then
                        km[3]()
                    end
                end, km[4] or {})
            end
        end
    end
end

-- Build hooks
vim.api.nvim_create_autocmd("PackChanged", {
    callback = function(ev)
        local name = ev.data.spec.name
        local kind = ev.data.kind
        if kind ~= "install" and kind ~= "update" then
            return
        end

        if name == "nvim-treesitter" then
            if not ev.data.active then
                vim.cmd.packadd("nvim-treesitter")
            end
            vim.cmd("TSUpdate")
        elseif name == "telescope-fzf-native.nvim" then
            vim.system({ "make" }, { cwd = ev.data.path }):wait()
        elseif name == "LuaSnip" then
            vim.system({ "make", "install_jsregexp" }, { cwd = ev.data.path }):wait()
        end
    end,
})

-- Register all plugins
vim.pack.add({
    -- Core utilities
    gh("nvim-lua/plenary.nvim"),
    gh("nvim-tree/nvim-web-devicons"),
    gh("MunifTanjim/nui.nvim"),
    gh("echasnovski/mini.nvim"),

    -- Colorscheme
    { src = gh("catppuccin/nvim"), name = "catppuccin" },

    -- Navigation
    gh("christoomey/vim-tmux-navigator"),

    -- UI
    gh("goolord/alpha-nvim"),
    gh("nvim-lualine/lualine.nvim"),
    gh("folke/noice.nvim"),
    gh("stevearc/dressing.nvim"),
    gh("folke/which-key.nvim"),
    gh("lukas-reineke/indent-blankline.nvim"),

    -- File explorer
    gh("nvim-tree/nvim-tree.lua"),

    -- Treesitter
    gh("nvim-treesitter/nvim-treesitter"),
    gh("nvim-treesitter/nvim-treesitter-textobjects"),
    gh("windwp/nvim-ts-autotag"),
    gh("JoosepAlviste/nvim-ts-context-commentstring"),

    -- LSP
    gh("neovim/nvim-lspconfig"),
    gh("williamboman/mason.nvim"),
    gh("williamboman/mason-lspconfig.nvim"),
    gh("WhoIsSethDaniel/mason-tool-installer.nvim"),
    gh("hrsh7th/cmp-nvim-lsp"),
    gh("antosha417/nvim-lsp-file-operations"),
    gh("folke/neodev.nvim"),

    -- Completion
    gh("hrsh7th/nvim-cmp"),
    gh("hrsh7th/cmp-buffer"),
    gh("hrsh7th/cmp-path"),
    gh("L3MON4D3/LuaSnip"),
    gh("saadparwaiz1/cmp_luasnip"),
    gh("rafamadriz/friendly-snippets"),
    gh("onsails/lspkind.nvim"),

    -- Editing
    gh("numToStr/Comment.nvim"),
    gh("windwp/nvim-autopairs"),
    gh("kylechui/nvim-surround"),

    -- Git
    gh("lewis6991/gitsigns.nvim"),

    -- Formatting & Linting
    gh("stevearc/conform.nvim"),
    gh("mfussenegger/nvim-lint"),
    gh("nvimtools/none-ls.nvim"),

    -- Search
    gh("nvim-telescope/telescope.nvim"),
    gh("nvim-telescope/telescope-fzf-native.nvim"),

    -- Misc
    gh("folke/todo-comments.nvim"),
    gh("akinsho/toggleterm.nvim"),
    gh("rmagatti/auto-session"),
    gh("MeanderingProgrammer/render-markdown.nvim"),

    -- Lazy-loaded plugins (only loaded on demand)
    {
        src = gh("kdheepak/lazygit.nvim"),
        load = lazy_load("lazygit.nvim", {
            "LazyGit",
            "LazyGitConfig",
            "LazyGitCurrentFile",
            "LazyGitFilter",
            "LazyGitFilterCurrentFile",
        }, {
            { "n", "<leader>lg", "LazyGit", { desc = "Open lazy git" } },
        }),
    },
    {
        src = gh("szw/vim-maximizer"),
        load = lazy_load("vim-maximizer", { "MaximizerToggle" }, {
            { "n", "<leader>sm", "MaximizerToggle", { desc = "Maximize/minimize a split" } },
        }),
    },
    {
        src = gh("folke/trouble.nvim"),
        load = lazy_load("trouble.nvim", { "Trouble" }, {
            { "n", "<leader>xw", "Trouble diagnostics toggle",              { desc = "Open trouble workspace diagnostics" } },
            { "n", "<leader>xd", "Trouble diagnostics toggle filter.buf=0", { desc = "Open trouble document diagnostics" } },
            { "n", "<leader>xq", "Trouble quickfix toggle",                 { desc = "Open trouble quickfix list" } },
            { "n", "<leader>xl", "Trouble loclist toggle",                  { desc = "Open trouble location list" } },
            { "n", "<leader>xt", "Trouble todo toggle",                     { desc = "Open todos in trouble" } },
        }, function()
            require("trouble").setup({ focus = true })
        end),
    },
})

-- Helper to safely require plugin configurations
local function safe_require(module, setup_fn)
    local ok, result = pcall(require, module)
    if not ok then
        -- Silently fail - plugin might be lazy-loaded or not needed yet
        return false
    end
    if setup_fn and type(result) == "table" and result.setup then
        pcall(result.setup, setup_fn)
    end
    return true
end

-- Configure plugins (order: dependencies first)

-- 1. Colorscheme (must be first)
safe_require("linuxdex.plugins.colorscheme")

-- 2. Core UI
safe_require("linuxdex.plugins.lualine")
safe_require("linuxdex.plugins.which-key")
safe_require("linuxdex.plugins.indent-blankline")

-- 3. Noice (deferred slightly for snappier startup)
vim.schedule(function()
    safe_require("linuxdex.plugins.noice")
end)

-- 4. File explorer
safe_require("linuxdex.plugins.nvim-tree")

-- 5. Treesitter (before LSP)
safe_require("linuxdex.plugins.treesitter")
safe_require("linuxdex.plugins.nvim-treesitter-text-objects")

-- 6. LSP + Completion (neodev before lspconfig)
safe_require("neodev", {})
safe_require("lsp-file-operations", {})
safe_require("linuxdex.plugins.lsp.mason")
safe_require("linuxdex.plugins.lsp.lspconfig")
safe_require("linuxdex.plugins.nvim-cmp")
safe_require("linuxdex.plugins.autopairs")

-- 7. Editing helpers
safe_require("linuxdex.plugins.comment")
safe_require("nvim-surround", {})
safe_require("linuxdex.plugins.formatting")
safe_require("linuxdex.plugins.linting")
safe_require("linuxdex.plugins.null-ls")

-- 8. Git
safe_require("linuxdex.plugins.gitsigns")

-- 9. Search
safe_require("linuxdex.plugins.telescope")

-- 10. Misc
safe_require("linuxdex.plugins.todo-comments")
safe_require("linuxdex.plugins.toggleterm")
safe_require("linuxdex.plugins.auto-session")
safe_require("linuxdex.plugins.render-markdown")

-- 11. Dashboard (on VimEnter for proper timing)
vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
        safe_require("linuxdex.plugins.alpha")
    end,
})

-- Check if plugins are actually installed
local function check_plugins_installed()
    local pack_path = vim.fn.stdpath("data") .. "/site/pack/core/opt"
    if vim.fn.isdirectory(pack_path) == 0 then
        return false
    end

    local handle = vim.loop.fs_scandir(pack_path)
    if not handle then
        return false
    end

    local count = 0
    while true do
        local name, type = vim.loop.fs_scandir_next(handle)
        if not name then break end
        if type == "directory" then
            count = count + 1
        end
    end

    return count > 0
end

-- Show helpful message if plugins are missing
if not check_plugins_installed() then
    vim.notify(
        "\n" .. string.rep("=", 60) .. "\n" ..
        "⚠️  PLUGINS NOT INSTALLED\n" ..
        string.rep("=", 60) .. "\n\n" ..
        "Some or all plugins are missing. To install them:\n\n" ..
        "  :PackUpdate\n\n" ..
        "Then restart Neovim after installation completes.\n" ..
        string.rep("=", 60),
        vim.log.levels.WARN
    )
end

-- User commands for plugin management
vim.api.nvim_create_user_command("PackUpdate", function()
    vim.pack.update()
end, { desc = "Update/install all plugins" })

vim.api.nvim_create_user_command("PackClean", function()
    vim.pack.clean()
end, { desc = "Remove unused plugins" })

vim.api.nvim_create_user_command("PackStatus", function()
    local pack_path = vim.fn.stdpath("data") .. "/site/pack/core/opt"
    local installed = {}

    -- Check if directory exists
    if vim.fn.isdirectory(pack_path) == 1 then
        local handle = vim.loop.fs_scandir(pack_path)
        if handle then
            while true do
                local name, type = vim.loop.fs_scandir_next(handle)
                if not name then break end
                if type == "directory" then
                    table.insert(installed, name)
                end
            end
        end
    end

    table.sort(installed)

    if #installed > 0 then
        vim.notify(
            string.format("Installed plugins (%d):\n• %s", #installed, table.concat(installed, "\n• ")),
            vim.log.levels.INFO
        )
    else
        vim.notify("No plugins installed yet. Run :PackUpdate to install.", vim.log.levels.WARN)
    end
end, { desc = "Show installed plugins" })

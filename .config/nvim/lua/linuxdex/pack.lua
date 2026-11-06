-- Plugin management using Neovim 0.12 built-in vim.pack (replaces lazy.nvim)
--
-- HOW LOADING WORKS (vim.pack.add semantics on 0.12):
--   * The real loading hook is the SECOND ARGUMENT of vim.pack.add(list, { load = fn }).
--     The callback is invoked once per plugin at add time and is then *fully responsible*
--     for loading it (no implicit :packadd executes). The per-spec `load` field is
--     ignored by vim.pack.
--   * Eager plugins are :packadd'ed right here inside the callback (that sources their
--     plugin/ scripts, like lazy.nvim would at startup).
--   * Lazy plugins (lazy_specs) stay OFF 'runtimepath'. Command/keymap stubs are
--     registered immediately and :packadd them on first use.
--   * Deferred plugins stay OFF 'runtimepath' until their trigger event fires. Their
--     after/plugin/*.lua scripts must not be sourced at startup (nvim sources
--     after/plugin for every rtp dir once at startup), which is exactly why the
--     directory has to stay off rtp until then.

local gh = function(x)
    return "https://github.com/" .. x
end

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local function safe_require(module, setup_fn)
    local ok, result = pcall(require, module)
    if not ok then
        -- plugin not on rtp (still lazy/deferred) or misconfigured: fail silently
        return false
    end
    if setup_fn and type(result) == "table" and result.setup then
        pcall(result.setup, setup_fn)
    end
    return true
end

--- Specs for plugins loaded on first use of a stubbed command or keymap.
--- @param plugin_name string pack directory name (e.g. "telescope.nvim")
--- @param cmds string[] user commands to stub until the plugin loads
--- @param keymaps table[] stub keymaps: {mode, lhs, rhs_cmd_or_fn, opts}
--- @param on_load? function runs after the plugin was packadded
local function register_lazy(plugin_name, cmds, keymaps, on_load)
    local registered, loaded = false, false

    return function()
        if registered then
            return
        end
        registered = true

        local function ensure_loaded()
            if loaded then
                return
            end
            loaded = true
            for _, cmd in ipairs(cmds) do
                pcall(vim.api.nvim_del_user_command, cmd)
            end
            local ok, err = pcall(vim.cmd.packadd, vim.fn.escape(plugin_name, " "))
            if not ok then
                vim.notify(
                    string.format("Cannot lazy-load '%s': %s", plugin_name, tostring(err)),
                    vim.log.levels.ERROR
                )
                return
            end
            if on_load then
                pcall(on_load)
            end
        end

        for _, cmd in ipairs(cmds) do
            vim.api.nvim_create_user_command(cmd, function(args)
                ensure_loaded()
                -- re-dispatch through the real command the plugin just defined
                local real = vim.api.nvim_get_commands({ builtin = false })[cmd]
                if not real then
                    return
                end
                local suffix = args.bang and "!" or ""
                if vim.trim(args.args) ~= "" then
                    suffix = suffix .. " " .. args.args
                end
                vim.cmd(cmd .. suffix)
            end, { nargs = "*", bang = true, desc = "Lazy stub for :" .. cmd })
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
                end, vim.tbl_extend("force", { silent = true }, km[4] or {}))
            end
        end
    end
end

--- Group of plugins that together stay off rtp until one of `events` fires.
--- Returns a registrar (idempotent): the first plug callback registers the
--- autocmd, every later one is a no-op.
--- @param plugins string[] pack directory names, packadded together
--- @param events string[] trigger events (once each)
--- @param on_load? function runs after all plugins were packadded
local function make_deferred(plugins, events, on_load)
    local registered, loaded = false, false

    return function()
        if registered then
            return
        end
        registered = true

        local function load_all()
            if loaded then
                return
            end
            loaded = true
            for _, p in ipairs(plugins) do
                local ok = pcall(vim.cmd.packadd, vim.fn.escape(p, " "))
                -- ponytail: packadd during VimEnter does not source after/plugin
                -- (that phase already ran). Source it here so cmp sources register.
                -- Ceiling: if a future nvim starts sourcing these itself, this
                -- double-loads after scripts; drop this loop when that happens.
                if ok then
                    local dir = vim.fn.stdpath("data") .. "/site/pack/core/opt/" .. p .. "/after/plugin"
                    local files = vim.fn.glob(dir .. "/*.{lua,vim}", false, true)
                    table.sort(files)
                    for _, file in ipairs(files) do
                        pcall(vim.cmd.source, file)
                    end
                end
            end
            if on_load then
                pcall(on_load)
            end
        end

        for _, ev in ipairs(events) do
            vim.api.nvim_create_autocmd(ev, {
                callback = load_all,
                desc = "Deferred load: " .. table.concat(plugins, ", "),
            })
        end
    end
end

---------------------------------------------------------------------------
-- Lazy specs (stubbed until first use)
---------------------------------------------------------------------------

-- telescope helper used by other keymaps that go through telescope at runtime
local function ensure_telescope_loaded()
    pcall(vim.cmd.packadd, "telescope.nvim")
    safe_require("linuxdex.plugins.telescope")
end

local lazy_specs = {
    -- Search: loaded on first <leader>f* / <leader>/ use
    ["telescope.nvim"] = register_lazy("telescope.nvim", { "Telescope" }, {
        { "n", "<leader>ff", "Telescope find_files",     { desc = "Find Files" } },
        { "n", "<leader>fg", "Telescope git_files",      { desc = "Git Files" } },
        { "n", "<leader>fr", "Telescope oldfiles",       { desc = "Recent Files" } },
        { "n", "<leader>fb", "Telescope buffers",        { desc = "Buffers" } },
        { "n", "<leader>fs", "Telescope live_grep",      { desc = "Live Grep" } },
        { "n", "<leader>fc", "Telescope grep_string",    { desc = "Grep String" } },
        { "n", "<leader>fh", "Telescope help_tags",      { desc = "Help Tags" } },
        { "n", "<leader>fk", "Telescope keymaps",        { desc = "Keymaps" } },
        { "n", "<leader>fd", "Telescope diagnostics",    { desc = "Diagnostics" } },
        { "n", "<leader>fgc", "Telescope git_commits",   { desc = "Find Git Commits" } },
        { "n", "<leader>fgs", "Telescope git_status",    { desc = "Find Git Status" } },
        { "n", "<leader>f<Enter>", "Telescope resume",   { desc = "Resume Last Search" } },
        { "n", "<leader>/", function()
            require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
                winblend = 10,
                previewer = false,
            }))
        end, { desc = "Fuzzy search in current buffer" } },
    }, function()
        safe_require("linuxdex.plugins.telescope")
    end),

    -- File explorer: loaded on first use of any NvimTree command/keymap
    ["nvim-tree.lua"] = register_lazy("nvim-tree.lua", {
        "NvimTreeOpen",
        "NvimTreeClose",
        "NvimTreeToggle",
        "NvimTreeFocus",
        "NvimTreeRefresh",
        "NvimTreeResize",
        "NvimTreeCollapse",
        "NvimTreeFindFile",
        "NvimTreeFindFileToggle",
    }, {
        { "n", "<leader>ee", "NvimTreeFindFileToggle", { desc = "Toggle file explorer" } },
        { "n", "<leader>ec", "NvimTreeCollapse",       { desc = "Collapse file explorer" } },
        { "n", "<leader>er", "NvimTreeRefresh",        { desc = "Refresh file explorer" } },
        { "n", "<leader>eo", "NvimTreeOpen",           { desc = "Open file explorer" } },
        { "n", "<leader>eq", "NvimTreeClose",          { desc = "Close file explorer" } },
        { "n", "<leader>ef", "NvimTreeFindFile",       { desc = "Find Current file in explorer" } },
        { "n", "<leader>ev", "NvimTreeFocus",          { desc = "Focus on file explorer" } },
        { "n", "<leader>en", "NvimTreeResize +10",     { desc = "Increase explorer width" } },
        { "n", "<leader>em", "NvimTreeResize -10",     { desc = "Decrease explorer width" } },
    }, function()
        safe_require("linuxdex.plugins.nvim-tree")
    end),

    ["lazygit.nvim"] = register_lazy("lazygit.nvim", {
        "LazyGit",
        "LazyGitConfig",
        "LazyGitCurrentFile",
        "LazyGitFilter",
        "LazyGitFilterCurrentFile",
    }, {
        { "n", "<leader>lg", "LazyGit", { desc = "Open lazy git" } },
    }),

    ["vim-maximizer"] = register_lazy("vim-maximizer", { "MaximizerToggle" }, {
        { "n", "<leader>sm", "MaximizerToggle", { desc = "Maximize/minimize a split" } },
    }),

    ["trouble.nvim"] = register_lazy("trouble.nvim", { "Trouble" }, {
        { "n", "<leader>xw", "Trouble diagnostics toggle",              { desc = "Open trouble workspace diagnostics" } },
        { "n", "<leader>xd", "Trouble diagnostics toggle filter.buf=0", { desc = "Open trouble document diagnostics" } },
        { "n", "<leader>xq", "Trouble quickfix toggle",                 { desc = "Open trouble quickfix list" } },
        { "n", "<leader>xl", "Trouble loclist toggle",                  { desc = "Open trouble location list" } },
        { "n", "<leader>xt", "Trouble todo toggle",                     { desc = "Open todos in trouble" } },
    }, function()
        require("trouble").setup({ focus = true })
    end),
}

---------------------------------------------------------------------------
-- Deferred groups (inert until their event fires)
---------------------------------------------------------------------------

-- Completion chain: cmp + sources + snippets + snippets engine + icons +
-- autopairs (auto-pairs needs cmp). All off rtp until VimEnter so completion
-- is ready immediately when you start typing (no 15–20s freeze on InsertEnter).
-- NOTE: autocmds intentionally stay registered (no `once = true`): the internal
-- `loaded` guard makes re-fires a no-op, and `once` autocmds are skipped by
-- synthetic execs / some headless scenarios.
local cmp_deferred = make_deferred({
    "nvim-cmp",
    "cmp-buffer",
    "cmp-path",
    "LuaSnip",
    "cmp_luasnip",
    "friendly-snippets",
    "lspkind.nvim",
    "nvim-autopairs",
}, { "VimEnter" }, function()
    safe_require("linuxdex.plugins.nvim-cmp")
    safe_require("linuxdex.plugins.autopairs")
end)

-- Indent guides: VimEnter in terminals, BufWinEnter covers first-buffer/open
-- and headless sessions (where nvim never fires VimEnter).
local ibl_deferred = make_deferred({ "indent-blankline.nvim" }, { "VimEnter", "BufWinEnter" }, function()
    safe_require("linuxdex.plugins.indent-blankline")
end)

local deferred_by_name = {
    ["nvim-cmp"] = cmp_deferred,
    ["cmp-buffer"] = cmp_deferred,
    ["cmp-path"] = cmp_deferred,
    ["LuaSnip"] = cmp_deferred,
    ["cmp_luasnip"] = cmp_deferred,
    ["friendly-snippets"] = cmp_deferred,
    ["lspkind.nvim"] = cmp_deferred,
    ["nvim-autopairs"] = cmp_deferred,
    ["indent-blankline.nvim"] = ibl_deferred,
}

---------------------------------------------------------------------------
-- Build hooks (run on install/update)
---------------------------------------------------------------------------
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

---------------------------------------------------------------------------
-- nvim-tree wants netrw off before startup plugin compilation kicks in
---------------------------------------------------------------------------
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

---------------------------------------------------------------------------
-- The one true loading hook for vim.pack.add
---------------------------------------------------------------------------
local function opts_load(plug_data)
    local name = plug_data.spec.name

    local lazy = lazy_specs[name]
    if lazy then
        lazy()
        return
    end

    local deferred = deferred_by_name[name]
    if deferred then
        deferred()
        return
    end

    -- default: load eagerly at startup (sources plugin/ scripts)
    vim.cmd.packadd(vim.fn.escape(name, " "))
end

---------------------------------------------------------------------------
-- Register all plugins
---------------------------------------------------------------------------
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

    -- File explorer (lazy, see lazy_specs)
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
    -- stays eager: LSP capabilities are built from it at startup
    -- (requires cmp only inside functions, never at module load)
    gh("hrsh7th/cmp-nvim-lsp"),
    gh("antosha417/nvim-lsp-file-operations"),
    gh("folke/neodev.nvim"),

    -- Completion (deferred until first InsertEnter)
    gh("hrsh7th/nvim-cmp"),
    gh("hrsh7th/cmp-buffer"),
    gh("hrsh7th/cmp-path"),
    gh("L3MON4D3/LuaSnip"),
    gh("saadparwaiz1/cmp_luasnip"),
    gh("rafamadriz/friendly-snippets"),
    gh("onsails/lspkind.nvim"),
    gh("windwp/nvim-autopairs"),

    -- Editing
    gh("numToStr/Comment.nvim"),
    gh("kylechui/nvim-surround"),

    -- Git
    gh("lewis6991/gitsigns.nvim"),

    -- Formatting & Linting (conform + nvim-lint cover what null-ls provided)
    gh("stevearc/conform.nvim"),
    gh("mfussenegger/nvim-lint"),

    -- Search (telescope deferred to first use; fzf-native stays on rtp so the
    -- PackChanged hook can (re)build it, and it has no plugin/ scripts)
    gh("nvim-telescope/telescope-fzf-native.nvim"),
    gh("nvim-telescope/telescope.nvim"),

    -- Indent guides (deferred to VimEnter)
    gh("lukas-reineke/indent-blankline.nvim"),

    -- Misc
    gh("folke/todo-comments.nvim"),
    gh("akinsho/toggleterm.nvim"),
    gh("rmagatti/auto-session"),
    gh("MeanderingProgrammer/render-markdown.nvim"),

    -- Lazy-loaded plugins (stubbed commands/keymaps, see lazy_specs)
    gh("kdheepak/lazygit.nvim"),
    gh("szw/vim-maximizer"),
    gh("folke/trouble.nvim"),
}, { load = opts_load })

---------------------------------------------------------------------------
-- Configure plugins (order: dependencies first)
---------------------------------------------------------------------------

-- 1. Colorscheme (must be first)
safe_require("linuxdex.plugins.colorscheme")

-- 2. Core UI
safe_require("linuxdex.plugins.lualine")
safe_require("linuxdex.plugins.which-key")

-- 3. Noice (deferred slightly for snappier startup)
vim.schedule(function()
    safe_require("linuxdex.plugins.noice")
end)

-- 4. Treesitter (new API; see plugins/treesitter.lua. Lazy/deferred plugins
--    are configured inside their load hooks above)
safe_require("linuxdex.plugins.treesitter")
safe_require("linuxdex.plugins.nvim-treesitter-text-objects")

-- 5. LSP (neodev before lspconfig; completion loads on first insert)
safe_require("neodev", {})
safe_require("lsp-file-operations", {})
safe_require("linuxdex.plugins.lsp.mason")
safe_require("linuxdex.plugins.lsp.lspconfig")

-- 6. Editing helpers
safe_require("linuxdex.plugins.comment")
safe_require("nvim-surround", {})
safe_require("linuxdex.plugins.formatting")
safe_require("linuxdex.plugins.linting")

-- 7. Git
safe_require("linuxdex.plugins.gitsigns")

-- 8. Misc
safe_require("linuxdex.plugins.todo-comments")

-- <leader>ft shows TODOs through telescope: make sure telescope is there first
vim.keymap.set("n", "<leader>ft", function()
    ensure_telescope_loaded()
    vim.cmd("TodoTelescope")
end, { desc = "Find TODOs", silent = true })

safe_require("linuxdex.plugins.toggleterm")
safe_require("linuxdex.plugins.auto-session")
safe_require("linuxdex.plugins.render-markdown")

-- 9. Dashboard: configured before alpha's own VimEnter autocmd runs
--    (alpha's plugin file is sourced during vim.pack.add above)
safe_require("linuxdex.plugins.alpha")

---------------------------------------------------------------------------
-- Diagnostics / maintenance
---------------------------------------------------------------------------

-- Check if plugins are actually installed
local function check_plugins_installed()
    local pack_path = vim.fn.stdpath("data") .. "/site/pack/core/opt"
    if vim.fn.isdirectory(pack_path) == 0 then
        return false
    end

    local handle = vim.uv.fs_scandir(pack_path)
    if not handle then
        return false
    end

    local count = 0
    while true do
        local name, type = vim.uv.fs_scandir_next(handle)
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
        local handle = vim.uv.fs_scandir(pack_path)
        if handle then
            while true do
                local name, type = vim.uv.fs_scandir_next(handle)
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

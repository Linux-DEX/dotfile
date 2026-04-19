local noice = require("noice")

-- Clear messages if coming from a lazy-like state
if vim.o.filetype == "lazy" then
    vim.cmd([[messages clear]])
end

noice.setup({
    lsp = {
        override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
            ["cmp.entry.get_documentation"] = true,
        },
        signature = {
            enabled = true,
        },
    },
    routes = {
        {
            filter = {
                event = "msg_show",
                any = {
                    { find = "%d+L, %d+B" },
                    { find = "; after #%d+" },
                    { find = "; before #%d+" },
                },
            },
            view = "mini",
        },
        -- Hide LSP progress messages (pyright, etc.)
        {
            filter = {
                event = "lsp",
                kind = "progress",
                cond = function(message)
                    local client = message.opts and message.opts.progress and message.opts.progress.client
                    return client == "pyright" or client == "lua_ls"
                end,
            },
            opts = { skip = true },
        },
        -- Hide all LSP progress messages
        {
            filter = {
                event = "lsp",
                kind = "progress",
            },
            opts = { skip = true },
        },
        -- Hide "written" messages
        {
            filter = {
                event = "msg_show",
                kind = "",
                find = "written",
            },
            opts = { skip = true },
        },
    },
    presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
        lsp_doc_border = true,
    },
})

-- Keymaps
local keymap = vim.keymap.set
keymap("c", "<S-Enter>", function()
    noice.redirect(vim.fn.getcmdline())
end, { desc = "Redirect Cmdline" })
keymap("n", "<leader>snl", function()
    noice.cmd("last")
end, { desc = "Noice Last Message" })
keymap("n", "<leader>snh", function()
    noice.cmd("history")
end, { desc = "Noice History" })
keymap("n", "<leader>sna", function()
    noice.cmd("all")
end, { desc = "Noice All" })
keymap("n", "<leader>snd", function()
    noice.cmd("dismiss")
end, { desc = "Dismiss All" })
keymap("n", "<leader>snt", function()
    noice.cmd("pick")
end, { desc = "Noice Picker (Telescope/FzfLua)" })
keymap({ "i", "n", "s" }, "<c-f>", function()
    if not require("noice.lsp").scroll(4) then
        return "<c-f>"
    end
end, { silent = true, expr = true, desc = "Scroll Forward" })
keymap({ "i", "n", "s" }, "<c-b>", function()
    if not require("noice.lsp").scroll(-4) then
        return "<c-b>"
    end
end, { silent = true, expr = true, desc = "Scroll Backward" })

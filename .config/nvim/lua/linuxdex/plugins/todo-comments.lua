local todo_comments = require("todo-comments")

local keymap = vim.keymap

keymap.set("n", "]t", function()
    todo_comments.jump_next()
end, { desc = "Next todo comment" })

keymap.set("n", "[t", function()
    todo_comments.jump_prev()
end, { desc = "Previous todo comment" })

todo_comments.setup({
    highlight = {
        before = "",
        keyword = "fg",
        after = "",
        -- Allow matching keywords outside of standard Neovim comment syntax (necessary for Markdown text)
        comments_only = false,
        -- Pattern matching keywords anywhere on the line followed by a colon
        pattern = [[.*<(KEYWORDS)\s*:]],
    },
    keywords = {
        -- Default Keywords
        FIX = {
            icon = " ",
            color = "error",
            alt = { "FIXME", "BUG", "FIXIT", "ISSUE" },
        },
        TODO = { icon = " ", color = "info" },
        HACK = { icon = " ", color = "warning" },
        WARN = {
            icon = " ",
            color = "warning",
            alt = { "WARNING", "XXX" },
        },
        PERF = {
            icon = " ",
            color = "default",
            alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" },
        },
        NOTE = {
            icon = " ",
            color = "hint",
            alt = { "INFO" },
        },

        -- Custom / Extra Keywords
        DONE = {
            icon = " ",
            color = "hint",
            alt = { "COMPLETED", "PASSED" },
        },
        IN_PROGRESS = {
            icon = "⏳",
            color = "warning",
            alt = { "DOING", "WIP" },
        },
        CANCELLED = {
            icon = "🚫",
            color = "error",
            alt = { "CANCELED", "SKIP", "SKIPPED" },
        },
        TEST = {
            icon = "⏲ ",
            color = "test",
            alt = { "TESTING", "PASSED" },
        },
    },
    -- Built-in color definitions
    colors = {
        error = { "DiagnosticError", "ErrorMsg", "#DC2626" },
        warning = { "DiagnosticWarn", "WarningMsg", "#FBBF24" },
        info = { "DiagnosticInfo", "#2563EB" },
        hint = { "DiagnosticHint", "#10B981" },
        default = { "Identifier", "#7C3AED" },
        test = { "Identifier", "#FF00FF" },
    },
})

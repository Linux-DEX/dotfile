local conform = require("conform")

-- Add Mason bin directory to PATH for formatters
local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
vim.env.PATH = mason_bin .. ":" .. vim.env.PATH

conform.setup({
    formatters_by_ft = {
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        css = { "prettier" },
        html = { "prettier" },
        json = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        graphql = { "prettier" },
        liquid = { "prettier" },
        lua = { "stylua" },
        python = { "ruff_format" },
        go = { "goimports" },
    },
    format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
    },
})

vim.keymap.set({ "n", "v" }, "<leader>mp", function()
    conform.format({
        lsp_fallback = true,
        async = false,
        timeout_ms = 1000,
    })
end, { desc = "Format file or range (in visual mode)" })

vim.keymap.set("v", "<leader>ms", function()
    conform.format({
        lsp_fallback = true,
        async = false,
        timeout_ms = 1000,
    })
end, { desc = "Format selected text" })

-- Diagnostic commands
vim.api.nvim_create_user_command("FormatInfo", function()
    local ft = vim.bo.filetype
    local formatters = conform.list_formatters(0)
    local available = {}
    local unavailable = {}

    for _, formatter in ipairs(formatters) do
        if formatter.available then
            table.insert(available, formatter.name)
        else
            table.insert(unavailable, formatter.name .. " (not found)")
        end
    end

    local msg = string.format(
        "Filetype: %s\nAvailable formatters: %s\nUnavailable: %s",
        ft,
        #available > 0 and table.concat(available, ", ") or "none",
        #unavailable > 0 and table.concat(unavailable, ", ") or "none"
    )
    vim.notify(msg, vim.log.levels.INFO)
end, { desc = "Show formatter info for current buffer" })

vim.api.nvim_create_user_command("FormatCheck", function()
    local mason_path = vim.fn.stdpath("data") .. "/mason/bin"
    local formatters = { "prettier", "stylua", "ruff", "goimports" }
    local results = {}

    for _, formatter in ipairs(formatters) do
        local full_path = mason_path .. "/" .. formatter
        if vim.fn.executable(full_path) == 1 then
            table.insert(results, "✓ " .. formatter .. " (" .. full_path .. ")")
        else
            table.insert(results, "✗ " .. formatter .. " (not found)")
        end
    end

    vim.notify("Formatter Check:\n" .. table.concat(results, "\n"), vim.log.levels.INFO)
end, { desc = "Check if formatters are installed" })

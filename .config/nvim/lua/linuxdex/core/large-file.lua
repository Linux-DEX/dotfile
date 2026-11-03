-- Large file policy (same idea as Zed's large_file handling: heavy features
-- step down on big buffers, everything stays on for normal files).
--
-- Buffers above the threshold open in "large mode":
--   * expr folding off  (measured : the single cause of ~26s opens on a 43MB file)
--   * soft wrap off     (huge single-line/minified buffers, ~2.9s -> ~0.17s)
--   * treesitter highlighting/indent skipped (see plugins/treesitter.lua)
--   * diagnostics / inlay hints / codelens / document-highlight skipped
--
-- Every feature is re-enableable on demand:
--   <leader>tw   toggle soft wrap
--   :FoldAny     enable expr folding on the current window
--   <leader>td   toggle diagnostics (already existed)

local M = {}

M.threshold = 1024 * 1024 -- bytes

local group = vim.api.nvim_create_augroup("large_files", { clear = true })

--- Returns true when `path` exceeds the large-file threshold
---@param path? string
---@return boolean
function M.is_large_path(path)
    if not path or path == "" then
        return false
    end
    local size = vim.fn.getfsize(path)
    return type(size) == "number" and size > M.threshold
end

--- Returns true when the given buffer is in large mode
---@param bufnr? integer
---@return boolean
function M.is_large(bufnr)
    bufnr = bufnr or 0
    return vim.b[bufnr].large == true
end

--- Enable expr folding on the current window manually (used for huge files)
function M.enable_folds()
    local lang = (vim.treesitter.language.get_lang(vim.bo.filetype) or vim.bo.filetype)
    local ts_ok = (lang ~= "" and lang ~= nil) and pcall(vim.treesitter.language.add, lang)
    if ts_ok then
        vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    else
        vim.wo.foldexpr = "v:lua.vim.lsp.foldexpr()"
    end
    vim.wo.foldmethod = "expr"
    vim.wo.foldlevel = 99
    vim.cmd("silent! normal! zx")
    vim.notify("Expr folds enabled for this window", vim.log.levels.INFO)
end

-- Flag large buffers as early as possible (before the file is read)
vim.api.nvim_create_autocmd("BufReadPre", {
    group = group,
    desc = "Flag buffers above the size threshold",
    callback = function(args)
        if M.is_large_path(args.file) then
            vim.b[args.buf].large = true
        end
    end,
})

-- Apply the light-weight large-mode window options when the buffer is shown
vim.api.nvim_create_autocmd("BufWinEnter", {
    group = group,
    desc = "Apply large-mode window options",
    callback = function(args)
        if not (vim.b[args.buf].large == true) then
            return
        end
        local win = vim.api.nvim_get_current_win()
        vim.wo[win].wrap = false
        vim.wo[win].list = false
        vim.wo[win].signcolumn = "no"
        vim.wo[win].foldmethod = "manual"
        vim.wo[win].foldlevel = 0
        pcall(vim.diagnostic.enable, false, { bufnr = args.buf })
    end,
})

vim.api.nvim_create_user_command("FoldAny", function()
    M.enable_folds()
end, { desc = "Enable expr folds on the current window (may be slow on huge files)" })

return M

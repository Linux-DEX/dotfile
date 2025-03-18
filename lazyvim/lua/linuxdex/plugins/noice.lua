return {
  "folke/noice.nvim",
  event = "VeryLazy",
  opts = {
    -- add any options here
    messages = {
      enabled = false, -- Completely disables messages UI
    },
    lsp = {
      progress = {
        enabled = true, -- Disables LSP progress messages
      },
      signature = {
        enabled = false, -- Disables signature help popups in insert mode
      },
      override = {
        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
        ["vim.lsp.util.stylize_markdown"] = true,
      },
    },
    views = {
      mini = {
        win_options = {
          winblend = 100, -- Makes popups fully transparent
        },
      },
    },
  },
  dependencies = {
    -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
    "MunifTanjim/nui.nvim",
    -- OPTIONAL:
    --   `nvim-notify` is only needed, if you want to use the notification view.
    --   If not available, we use `mini` as the fallback
    "rcarriga/nvim-notify",
  }
}

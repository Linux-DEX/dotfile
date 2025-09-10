return {
  "williamboman/mason.nvim",
  lazy = false,
  dependencies = {
    "williamboman/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    "hrsh7th/cmp-nvim-lsp",
    "neovim/nvim-lspconfig",
  },
  config = function()
    require("mason").setup({
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    })

    require("mason-lspconfig").setup({
      ensure_installed = {
        "lua_ls",
        "html",
        "cssls",
        "tailwindcss",
        "gopls",
        "emmet_ls",
        "emmet_language_server",
        "marksman",
      },
      -- automatic_enable is true by default, so installed LSPs are automatically enabled
    })

    require("mason-tool-installer").setup({
      ensure_installed = {
        "prettier",
        "stylua",
        "isort",
        "pylint",
        "clangd",
      },
    })
  end,
}


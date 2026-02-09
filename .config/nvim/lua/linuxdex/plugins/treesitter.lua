return {
  "nvim-treesitter/nvim-treesitter",
  event = { "BufReadPre", "BufNewFile" },
  build = ":TSUpdate",
  dependencies = {
    "windwp/nvim-ts-autotag",
  },
  config = function()
    -- import nvim-treesitter plugin
    local treesitter = require("nvim-treesitter.configs")

    -- configure treesitter
    treesitter.setup({ -- enable syntax highlighting
      highlight = {
        enable = true,
      },
      -- enable indentation
      indent = { enable = true },
      -- enable autotagging (w/ nvim-ts-autotag plugin)
      autotag = {
        enable = true,
      },
      -- ensure these language parsers are installed
      ensure_installed = {
        "json",
        "javascript",
        "typescript",
        "tsx",
        "yaml",
        "html",
        "css",
        "prisma",
        "markdown",
        "markdown_inline",
        "bash",
        "lua",
        "vim",
        "dockerfile",
        "gitignore",
        "query",
        "vimdoc",
        "c",
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          scope_incremental = false,
          node_decremental = "<bs>",
        },
      },
    })
  end,
}

-- return {
-- 	"nvim-treesitter/nvim-treesitter",
-- 	branch = "main",
-- 	build = ":TSUpdate",
-- 	event = { "BufReadPre", "BufNewFile", "VeryLazy" },
-- 	cmd = { "TSUpdate", "TSInstall", "TSUninstall" },
-- 	dependencies = {
-- 		"windwp/nvim-ts-autotag",
-- 	},
-- 	opts = {
-- 		highlight = {
-- 			enable = true,
-- 			additional_vim_regex_highlighting = false,
-- 		},
-- 		indent = { enable = true },
-- 		autotag = {
-- 			enable = true,
-- 			enable_rename = true,
-- 			enable_close = true,
-- 			enable_close_on_slash = true,
-- 		},
-- 		ensure_installed = {
-- 			"bash",
-- 			"c",
-- 			"css",
-- 			"diff",
-- 			"html",
-- 			"javascript",
-- 			"jsdoc",
-- 			"json",
-- 			"jsonc",
-- 			"lua",
-- 			"luadoc",
-- 			"luap",
-- 			"markdown",
-- 			"markdown_inline",
-- 			"printf",
-- 			"python",
-- 			"query",
-- 			"regex",
-- 			"toml",
-- 			"tsx",
-- 			"typescript",
-- 			"vim",
-- 			"vimdoc",
-- 			"xml",
-- 			"yaml",
-- 		},
-- 		auto_install = true,
-- 		sync_install = false,
-- 		incremental_selection = {
-- 			enable = true,
-- 			keymaps = {
-- 				init_selection = "<C-space>",
-- 				node_incremental = "<C-space>",
-- 				scope_incremental = false,
-- 				node_decremental = "<bs>",
-- 			},
-- 		},
-- 	},
-- 	config = function(_, opts)
-- 		-- Setup treesitter
-- 		require("nvim-treesitter.config").setup(opts)
--
-- 		-- Enable treesitter-based folding
-- 		vim.opt.foldmethod = "expr"
-- 		vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
-- 		vim.opt.foldenable = false -- Don't fold by default
--
-- 		-- Auto-enable highlighting for supported filetypes
-- 		vim.api.nvim_create_autocmd("FileType", {
-- 			group = vim.api.nvim_create_augroup("treesitter_highlight", { clear = true }),
-- 			pattern = {
-- 				"javascript",
-- 				"typescript",
-- 				"tsx",
-- 				"jsx",
-- 				"html",
-- 				"css",
-- 				"lua",
-- 				"python",
-- 				"bash",
-- 				"json",
-- 				"yaml",
-- 				"markdown",
-- 			},
-- 			callback = function(ev)
-- 				-- Ensure treesitter highlighting is enabled
-- 				pcall(vim.treesitter.start, ev.buf)
-- 			end,
-- 		})
-- 	end,
-- }

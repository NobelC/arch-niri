return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    opts = require "configs.conform",
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "vim",
        "lua",
        "vimdoc",
        "bash",
        "rust",
        "c",
        "cpp",
        "python",
        "go",
        "html",
        "css",
        "dockerfile",
        "json",
        "toml",
        "yaml",
        "markdown",
        "markdown_inline",
      },
    },
  },

  {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    lazy = true,
    ft = "markdown",
    cmd = { "Obsidian" },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = {
      legacy_commands = false,
      workspaces = {
        {
          name = "notes",
          path = vim.fn.expand "~/Notes",
        },
      },
      notes_subdir = "inbox",
      new_notes_location = "notes_subdir",
      daily_notes = {
        folder = "daily",
        date_format = "%Y-%m-%d",
        template = "daily.md",
      },
      templates = {
        folder = "templates",
        date_format = "%Y-%m-%d",
        time_format = "%H:%M",
      },
      attachments = {
        folder = "attachments",
      },
      picker = {
        name = "telescope.nvim",
      },
      ui = {
        enable = false,
      },
    },
  },

  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = "markdown",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {},
  },
}

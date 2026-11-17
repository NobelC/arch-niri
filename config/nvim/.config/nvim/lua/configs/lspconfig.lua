require("nvchad.configs.lspconfig").defaults()

local servers = {
  "html",
  "cssls",
  "bashls",
  "rust_analyzer",
  "clangd",
  "pyright",
  "gopls",
  "dockerls",
  "docker_compose_language_service",
  "lua_ls",
}

vim.lsp.enable(servers)

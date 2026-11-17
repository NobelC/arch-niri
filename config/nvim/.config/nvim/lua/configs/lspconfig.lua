require("nvchad.configs.lspconfig").defaults()

local servers = { "html", "cssls", "bashls" }
vim.lsp.enable(servers)

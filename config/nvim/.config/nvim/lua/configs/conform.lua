local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    rust = { "rustfmt" },
    cpp = { "clang-format" },
    c = { "clang-format" },
    python = { "black" },
    go = { "gofmt" },
  },
}

return options

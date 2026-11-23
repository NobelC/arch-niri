require "nvchad.mappings"

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- Obsidian (notas en Neovim)
map("n", "<leader>oo", "<cmd>Obsidian quick_switch<cr>", { desc = "Obsidian: abrir nota" })
map("n", "<leader>os", "<cmd>Obsidian search<cr>",       { desc = "Obsidian: buscar texto" })
map("n", "<leader>on", "<cmd>Obsidian new<cr>",          { desc = "Obsidian: nueva nota" })
map("n", "<leader>od", "<cmd>Obsidian today<cr>",        { desc = "Obsidian: nota diaria" })
map("n", "<leader>ob", "<cmd>Obsidian backlinks<cr>",    { desc = "Obsidian: backlinks" })
map("n", "<leader>ot", "<cmd>Obsidian tags<cr>",         { desc = "Obsidian: etiquetas" })
map("n", "<leader>oc", "<cmd>Obsidian toggle_checkbox<cr>", { desc = "Obsidian: alternar checkbox" })

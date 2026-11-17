local theme_file = vim.fn.expand("~/.config/nvim/current-theme")

local function apply_nvchad_theme()
  if vim.fn.filereadable(theme_file) == 1 then
    local lines = vim.fn.readfile(theme_file)
    local theme_name = lines[1] and vim.trim(lines[1]) or ""
    if theme_name ~= "" then
      vim.schedule(function()
        require("nvconfig").base46.theme = theme_name
        require("base46").load_all_highlights()
      end)
    end
  end
end

-- Aplica el tema guardado al abrir Neovim
apply_nvchad_theme()

-- Vigila cambios en vivo cuando ejecutes theme-switch
local watcher = vim.uv.new_fs_event()
if watcher then
  watcher:start(theme_file, {}, function(err)
    if not err then
      watcher:stop()
      apply_nvchad_theme()
      vim.defer_fn(function()
        package.loaded["theme-sync"] = nil
        require("theme-sync")
      end, 100)
    end
  end)
end

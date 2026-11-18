local palette_file = vim.fn.expand("~/.local/state/matugen/nvchad-colors.lua")

local function apply_matugen_theme()
  if vim.fn.filereadable(palette_file) ~= 1 then
    return
  end

  local ok_load, palette = pcall(dofile, palette_file)
  if not ok_load or type(palette) ~= "table" then
    return
  end

  vim.schedule(function()
    local ok_cfg, nvconfig = pcall(require, "nvconfig")
    local ok_b46, base46 = pcall(require, "base46")
    if not ok_cfg or not ok_b46 then
      return
    end

    local current = nvconfig.base46.theme
    nvconfig.base46.changed_themes = nvconfig.base46.changed_themes or {}
    nvconfig.base46.changed_themes[current] = palette
    base46.load_all_highlights()
  end)
end

-- Aplica los colores al abrir Neovim
apply_matugen_theme()

-- Vigila cambios en vivo cuando matugen regenera el archivo
local watcher = vim.uv.new_fs_event()
if watcher then
  local function start_watch()
    if vim.fn.filereadable(palette_file) == 1 then
      watcher:start(palette_file, {}, function(err)
        if not err then
          watcher:stop()
          apply_matugen_theme()
          vim.defer_fn(start_watch, 150)
        end
      end)
    else
      vim.defer_fn(start_watch, 1000)
    end
  end
  start_watch()
end

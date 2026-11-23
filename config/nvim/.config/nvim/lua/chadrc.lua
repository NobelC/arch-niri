---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "catppuccin",

  hl_override = {
    Pmenu = { bg = "one_bg", fg = "white" },
    PmenuSel = { bg = "pmenu_bg", fg = "darker_black", bold = true },
    PmenuSbar = { bg = "one_bg2" },
    PmenuThumb = { bg = "grey_fg" },
    NormalFloat = { bg = "darker_black", fg = "white" },
    FloatBorder = { fg = "nord_blue", bg = "darker_black" },
  },
}

return M

-- NvChad configuration. Same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
---@type ChadrcConfig
local M = {}

-- Tema: antes usabas catppuccin-mocha (LazyVim). base46 trae la misma paleta.
M.base46 = {
  theme = "tokyonight",

  hl_override = {
    Comment = { italic = true },
    ["@comment"] = { italic = true },
  },
}

-- Dashboard de inicio: se conserva el dashboard de snacks.nvim (ver plugins/snacks.lua)
M.nvdash = { load_on_startup = false }

local function custom_modules()
  local function updates()
    local ok, status = pcall(require, "lazy.status")
    if ok and status.has_updates() then
      return "%#St_Lsp#" .. status.updates()
    end
    return ""
  end

  return {
    updates = updates,
    noice_cmd = function()
      if package.loaded["noice"] and require("noice").api.status.command.has() then
        return "%#St_Lsp#" .. require("noice").api.status.command.get()
      end
      return ""
    end,
    noice_mode = function()
      if package.loaded["noice"] and require("noice").api.status.mode.has() then
        return "%#St_Lsp#" .. require("noice").api.status.mode.get()
      end
      return ""
    end,
    dap = function()
      if package.loaded["dap"] and require("dap").status() ~= "" then
        return "%#St_Lsp#" .. require("dap").status()
      end
      return ""
    end,
    wakatime = function()
      if vim.fn.exists("*wakatime#GetIniTimeString") == 1 then
        local ok, value = pcall(vim.fn["wakatime#GetIniTimeString"])
        if ok and value and value ~= "" then
          return "%#St_Lsp#" .. value
        end
      end
      return ""
    end,
    clock = function()
      return "%#St_pos_text# " .. os.date("%H:%M") .. " "
    end,
  }
end

M.ui = {
  cmp = {
    style = "atom_colored",
    icons_left = false,
  },

  statusline = {
    enabled = true,
    theme = "default",
    separator_style = "round",
    order = {
      "mode",
      "file",
      "git",
      "%=",
      "lsp_msg",
      "%=",
      "diagnostics",
      "lsp",
      "updates",
      "noice_cmd",
      "noice_mode",
      "dap",
      "wakatime",
      "cwd",
      "cursor",
      "clock",
    },
    modules = custom_modules(),
  },

  tabufline = {
    enabled = true,
    lazyload = true,
    order = { "treeOffset", "buffers", "tabs", "btns" },
    bufwidth = 21,
  },

  telescope = { style = "borderless" },

  -- Integración con snacks (thresholds/colores de nvchad)
  term = {
    startinsert = true,
    base46_colors = true,
    winopts = { number = false, relativenumber = false },
  },
}

M.lsp = { signature = true }

M.mason = { pkgs = {}, skip = {} }

M.colorify = { enabled = true }

return M

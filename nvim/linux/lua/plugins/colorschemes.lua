return {
  -- Los 4 plugins de temas
  { "folke/tokyonight.nvim" },
  { "rebelot/kanagawa.nvim" },
  { "catppuccin/nvim", name = "catppuccin" },
  { "EdenEast/nightfox.nvim" },

  -- Themery: ahora con lista autogenerada de TODOS los colorschemes instalados
  {
    "zaldih/themery.nvim",
    lazy = false,
    config = function()
      -- Igual que hace <leader>uC internamente: pide a Neovim todos los
      -- colorschemes disponibles (incluye variantes: catppuccin-mocha,
      -- tokyonight-storm, nightfox, duskfox, terafox, etc.)
      local all_colors = vim.fn.getcompletion("", "color")

      -- Convertimos cada nombre en el formato que Themery espera
      local themes = {}
      for _, color in ipairs(all_colors) do
        table.insert(themes, { name = color, colorscheme = color })
      end

      -- Themery tiene un bug en su release donde constants.DEFAULT_SETTINGS no define
      -- themeConfigFile pero checkDeprecatedConfig corre fnamemodify("") -> ruta actual.
      -- Parcheamos la función interna de checkDeprecatedConfig para silenciar el print.
      local themery_constants = require("themery.constants")
      themery_constants.MSG_INFO.THEME_CONFIG_FILE_DEPRECATED = ""

      local orig_print = print
      print = function(...)
        local msg = select(1, ...)
        if type(msg) == "string" and msg:match("Themery: The") then
          return
        end
        orig_print(...)
      end

      require("themery").setup({
        themes = themes,
        livePreview = true,
      })

      print = orig_print
    end,
  },

  {
    "LazyVim/LazyVim",
    keys = {
      { "<leader>ut", "<cmd>Themery<cr>", desc = "Elegir tema (persistente)" },
    },
  },
}

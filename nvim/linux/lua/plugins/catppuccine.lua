return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000, -- Asegura que se cargue al inicio
    config = function()
      require("catppuccin").setup({
        flavour = "mocha", -- opciones: latte, frappe, macchiato, mocha
        transparent_background = false,
        term_colors = true,
        custom_highlights = function(colors)
          return {
            SnacksDashboardHeader = { fg = colors.green },
          }
        end,
      })
    end,
  },
}

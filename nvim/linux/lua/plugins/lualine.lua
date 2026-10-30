return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.options.theme = "auto"
      opts.options.component_separators = { left = "", right = "" }
      opts.options.section_separators = { left = "", right = "" }

      -- Restablecer la sección X original de LazyVim
      opts.sections.lualine_x = {
        Snacks.profiler.status(),
        -- Icono actualizaciones Lazy.nvim
        {
          require("lazy.status").updates,
          cond = require("lazy.status").has_updates,
          color = function() return { fg = Snacks.util.color("Special") } end,
        },
        -- diff / diagnostics si los hay
        {
          function()
            return vim.fn["wakatime#GetIniTimeString"]()
          end,
          cond = function()
            return vim.fn.exists("*wakatime#GetIniTimeString") == 1
          end,
        },
        {
          function()
            return require("noice").api.status.command.get()
          end,
          cond = function()
            return package.loaded["noice"] and require("noice").api.status.command.has()
          end,
        },
        {
          function()
            return require("noice").api.status.mode.get()
          end,
          cond = function()
            return package.loaded["noice"] and require("noice").api.status.mode.has()
          end,
        },
      }

      -- Sección Y: Porcentaje del archivo + formato de cursor personalizado
      opts.sections.lualine_y = {
        "progress",
        {
          function()
            local line = vim.fn.line(".")
            local col = vim.fn.col(".")
            return string.format("󰉸 %d 󱞅 %d", line, col)
          end,
        },
      }

      -- Sección Z: Hora
      opts.sections.lualine_z = {
        {
          function()
            return " " .. os.date("%H:%M")
          end,
        },
      }
    end,
  },
}

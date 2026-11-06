return {
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = function(_, opts)
      opts.lsp = opts.lsp or {}
      opts.lsp.progress = opts.lsp.progress or {}
      opts.lsp.progress.enabled = false

      opts.routes = opts.routes or {}
      table.insert(opts.routes, {
        -- Warning inofensivo: el proceso "adapter" de debugpy (no tu script)
        -- sale con código 1 al cerrarse. No afecta tu programa.
        filter = {
          event = "notify",
          find = "of adapter",
        },
        opts = { skip = true },
      })

      -- Neovide 0.17 reporta ext_cmdline/ext_messages en los primeros ms del
      -- arranque y luego los apaga. El health-check de noice corre en esa
      -- ventana y avisa "You're using a GUI that uses ext_cmdline/ext_messages".
      -- Es un falso positivo: se evita el chequeo periódico bajo Neovide.
      if vim.g.neovide then
        opts.health = opts.health or {}
        opts.health.checker = false
      end
    end,
    config = function(_, opts)
      -- noice ejecuta su health-check al hacer setup y avisa si la UI tiene
      -- ext_cmdline/ext_messages activos. Neovide 0.17 los reporta como true
      -- durante ~800 ms del arranque y luego los apaga; se espera a que la UI
      -- reporte los flags definitivos antes de inicializar noice.
      local function ui_ready()
        local ui = vim.api.nvim_list_uis()[1]
        return not ui or (not ui.ext_cmdline and not ui.ext_messages)
      end

      if not vim.g.neovide then
        require("noice").setup(opts)
        return
      end

      local function setup_when_ready(attempt)
        if ui_ready() or attempt >= 60 then
          require("noice").setup(opts)
          return
        end
        vim.defer_fn(function()
          setup_when_ready(attempt + 1)
        end, 50)
      end
      setup_when_ready(0)
    end,
    dependencies = {
      -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
      "MunifTanjim/nui.nvim",
      -- OPTIONAL:
      --   `nvim-notify` is only needed, if you want to use the notification view.
      --   If not available, we use `mini` as the fallback
      "rcarriga/nvim-notify",
    },
  },
}

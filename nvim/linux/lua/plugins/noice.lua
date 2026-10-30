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

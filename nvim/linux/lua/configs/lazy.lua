return {
  -- Igual que tu config LazyVim: los plugins propios cargan al inicio salvo que
  -- definan event/cmd/keys (antes `defaults.lazy = false`).
  defaults = { lazy = false },
  install = { colorscheme = { "nvchad", "habamax" } },

  checker = {
    enabled = true,
    notify = false,
  },

  ui = {
    icons = {
      ft = "",
      lazy = "󰂠 ",
      loaded = "",
      not_loaded = "",
    },
  },

  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
}

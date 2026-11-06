return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
    bigfile = { enabled = true },
    dashboard = {
      preset = {
        --        header = [[
        --██████╗ ███████╗██╗     ███╗   ███╗ █████╗ ███╗   ██╗
        --██╔══██╗██╔════╝██║     ████╗ ████║██╔══██╗████╗  ██║
        --██████╔╝█████╗  ██║     ██╔████╔██║███████║██╔██╗ ██║
        --██╔══██╗██╔══╝  ██║     ██║╚██╔╝██║██╔══██║██║╚██╗██║
        --██████╔╝███████╗███████╗██║ ╚═╝ ██║██║  ██║██║ ╚████║
        --╚═════╝ ╚══════╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝]],
        header = [[
╔═══════╗  ██████╗ ███████╗██╗     ███╗   ███╗ █████╗ ███╗   ██╗
║ >_    ║  ██╔══██╗██╔════╝██║     ████╗ ████║██╔══██╗████╗  ██║
║       ║  ██████╔╝█████╗  ██║     ██╔████╔██║███████║██╔██╗ ██║
║       ║  ██╔══██╗██╔══╝  ██║     ██║╚██╔╝██║██╔══██║██║╚██╗██║
║       ║  ██████╔╝███████╗███████╗██║ ╚═╝ ██║██║  ██║██║ ╚████║
╚═══════╝  ╚═════╝ ╚══════╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝]],
        keys = {
          { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
          { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
          { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
          { icon = " ", key = "p", desc = "Projects", action = ":lua Snacks.picker.projects()" },
          { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
          {
            icon = " ",
            key = "c",
            desc = "Config",
            action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
          },
          { icon = " ", key = "s", desc = "Restore Session", section = "session" },
          { icon = " ", key = "l", desc = "Lazy", action = ":Lazy" },
          { icon = " ", key = "q", desc = "Quit", action = ":qa" },
        },
      },
    },
    explorer = { enabled = true },
    indent = { enabled = true },
    input = { enabled = true },
    picker = {
      enabled = true,
      sources = {
        explorer = {
          auto_close = true,
        },
      },
    },
    notifier = { enabled = true },
    quickfile = { enabled = true },
    terminal = {
      win = {
        keys = {
          nav_h = { "<C-h>", "<c-w>h", desc = "Go to Left Window", mode = "t" },
          nav_j = { "<C-j>", "<c-w>j", desc = "Go to Lower Window", mode = "t" },
          nav_k = { "<C-k>", "<c-w>k", desc = "Go to Upper Window", mode = "t" },
          nav_l = { "<C-l>", "<c-w>l", desc = "Go to Right Window", mode = "t" },
          hide_slash = { "<C-/>", "hide", desc = "Hide Terminal", mode = "t" },
        },
      },
    },
    scope = { enabled = true },
    scroll = { enabled = true },
    statuscolumn = { enabled = true },
    words = { enabled = true },
  },
}

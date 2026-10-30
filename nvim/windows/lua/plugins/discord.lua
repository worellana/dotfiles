return {
  {
    "vyfor/cord.nvim",
    build = vim.fn.has("win32") == 1 and "powershell -ExecutionPolicy Bypass -File build.ps1" or "./build",
    event = "VeryLazy",
    opts = {},
  },
}

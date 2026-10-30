return {
  "MonsieurTib/neonuget",
  enabled = false, -- Deshabilitado temporalmente
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  cmd = { "NuGet" },
  keys = {
    { "<leader>dnn", "<cmd>NuGet<cr>", desc = ".NET: Abrir NeoNuGet" },
  },
  opts = {},
}

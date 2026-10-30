return {
  {
    "NMAC427/guess-indent.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      auto_cmd = true,
      override_editorconfig = false, -- Si ya existe un .editorconfig, tiene prioridad
    },
  },
}

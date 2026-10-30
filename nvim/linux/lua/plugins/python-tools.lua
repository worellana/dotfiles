return {
  -- Formateo: solo ruff (black queda de más)
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        python = { "ruff_format" },
      },
    },
  },

  -- Linting: NO agregamos ruff aquí a propósito.
  -- El LSP de ruff (ya activo vía el extra lang.python) ya lint-ea en
  -- vivo; agregarlo también en nvim-lint duplica cada diagnóstico.
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        python = {},
      },
    },
  },
}

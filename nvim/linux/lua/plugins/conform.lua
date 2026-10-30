return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "isort", "black" },
      javascript = { { "prettierd", "prettier" } },
      markdown = { { "prettierd", "prettier" } },
      typescript = { "eslint_d" },
      sh = { "shfmt" },
      bash = { "shfmt" },
      cs = { "csharpier" },
      c = { "clang-format" },
      cpp = { "clang-format" },
    },
    formatters = {
      stylua = {
        command = "stylua",
      },
    },
  },

  -- Formatters externos que conform necesita y Mason puede instalar.
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "prettier", "eslint_d", "csharpier" })
    end,
  },
}

return {
  default_format_opts = {
    timeout_ms = 3000,
    async = false,
    quiet = false,
    lsp_format = "fallback",
  },

  formatters_by_ft = {
    lua = { "stylua" },
    python = { "ruff_format" },
    javascript = { { "prettierd", "prettier" } },
    markdown = { { "prettierd", "prettier" } },
    typescript = { "eslint_d" },
    sh = { "shfmt" },
    bash = { "shfmt" },
    cs = { "csharpier" },
    c = { "clang-format" },
    cpp = { "clang-format" },
    gdscript = { "gdformat" },
    kotlin = { "ktlint" },
    sql = { "sqlfluff" },
  },

  formatters = {
    -- En Windows, los shims .CMD de Mason se rompen cuando la ruta del
    -- archivo contiene espacios ("Williams Orellana"). Se usa el .exe real.
    stylua = {
      command = vim.uv.fs_stat("C:/tools/nvim-mason/packages/stylua/stylua.exe")
          and "C:/tools/nvim-mason/packages/stylua/stylua.exe"
        or "stylua",
    },
    shfmt = {
      command = vim.uv.fs_stat("C:/tools/nvim-mason/packages/shfmt/shfmt_v3.14.1_windows_amd64.exe")
          and "C:/tools/nvim-mason/packages/shfmt/shfmt_v3.14.1_windows_amd64.exe"
        or "shfmt",
    },
    csharpier = {
      command = vim.uv.fs_stat("C:/tools/nvim-mason/packages/csharpier/csharpier.exe")
          and "C:/tools/nvim-mason/packages/csharpier/csharpier.exe"
        or "csharpier",
    },
    injected = { options = { ignore_errors = true } },
  },
}

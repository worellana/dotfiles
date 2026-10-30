return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        virtual_text = {
          spacing = 4,
          prefix = "●",
          severity = { min = vim.diagnostic.severity.WARN },
          format = function(diagnostic)
            return diagnostic.message:gsub("\n.*", "")
          end,
        },
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      },
    },
  },
}

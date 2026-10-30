return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed or {}, { "powershell" })
    end,
    {
      "mason-org/mason.nvim",
      opts = function(_, opts)
        vim.list_extend(opts.ensure_installed or {}, { "powershell-editor-services" })
      end,
    },
    {
      "TheLeoP/powershell.nvim",
      ft = "ps1",
      config = function()
        require("powershell").setup({
          bundle_path = "C:/tools/nvim-mason/packages/powershell-editor-services",
        })
      end,
    },
  },
}

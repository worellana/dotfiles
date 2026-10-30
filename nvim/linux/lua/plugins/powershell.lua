-- Soporte PowerShell.
-- En Linux/WSL PSES necesita `pwsh` (PowerShell 7), que no viene instalado
-- por defecto en Fedora. Si no existe, no instalamos nada ni activamos el LSP.
local has_pwsh = vim.fn.executable("pwsh") == 1

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed or {}, { "powershell" })
    end,
  },
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      if has_pwsh then
        vim.list_extend(opts.ensure_installed or {}, { "powershell-editor-services" })
      end
    end,
  },
  {
    "TheLeoP/powershell.nvim",
    ft = "ps1",
    cond = has_pwsh,
    config = function()
      require("powershell").setup({
        bundle_path = vim.fn.stdpath("data") .. "/mason/packages/powershell-editor-services",
      })
    end,
  },
}

-- PowerShell: powershell.nvim trae su propio servidor (PowerShell Editor Services)
return {
  {
    "TheLeoP/powershell.nvim",
    ft = "ps1",
    config = function()
      local root = vim.fn.has("win32") == 1 and "C:/tools/nvim-mason" or (vim.fn.stdpath("data") .. "/mason")
      local bundle = root .. "/packages/powershell-editor-services"
      require("powershell").setup({
        bundle_path = vim.uv.fs_stat(bundle) and bundle or nil,
      })
    end,
  },
}

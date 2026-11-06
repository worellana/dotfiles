-- C# / .NET: Roslyn (mismo motor que VS/VS Code) en lugar de OmniSharp
if vim.fn.has("win32") == 1 then
  vim.env.MASON = "C:/tools/nvim-mason"
end
vim.env.DOTNET_CLI_UI_LANGUAGE = "en-US"
vim.env.VSLANG = "1033"

return {
  {
    "seblyng/roslyn.nvim",
    ft = "cs",
    lazy = false,
    opts = {
      broad_search = true,
    },
    init = function()
      -- El servidor se cierra al salir de Neovim
      vim.env.ROSLYN_LANGUAGE_SERVER_DAEMON_KEEPALIVE = "0"

      vim.lsp.config("roslyn", {
        cmd_env = {
          DOTNET_SYSTEM_GLOBALIZATION_INVARIANT = "1",
        },
      })
    end,
    config = function()
      -- El registro de Mason provee el paquete "roslyn" (ver plugins/lsp.lua);
      -- habilitamos el servidor explícitamente porque no está en mason-lspconfig.
      vim.lsp.enable("roslyn")
    end,
  },

  -- El registro comunitario + install_root_dir ya se configuran en plugins/lsp.lua
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = { "roslyn" },
    },
  },

  -- Apagar OmniSharp para que no compita por el mismo archivo .cs
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        omnisharp = { enabled = false },
      },
    },
  },
}

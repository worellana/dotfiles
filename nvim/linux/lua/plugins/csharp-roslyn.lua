-- Migración de omnisharp -> Roslyn (el mismo motor de VS/VS Code)
-- Analogía: omnisharp es como un traductor que le hace un resumen del código
-- a Neovim; Roslyn es el autor original del texto hablando directamente
-- contigo, sin intermediario. Por eso es más preciso y más rápido.

-- Linux/WSL: Mason usa su ruta por defecto (~/.local/share/nvim/mason).
vim.env.DOTNET_CLI_UI_LANGUAGE = "en-US"
vim.env.VSLANG = "1033"

return {
  -- 1) Le decimos a mason dónde buscar el paquete de Roslyn.
  -- Roslyn todavía no está en el registro oficial de Mason, así que
  -- sumamos el registro comunitario que lo provee (Crashdummyy).
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      -- IMPORTANTE: hay que incluir el registro oficial explícitamente,
      -- si no, Mason se queda ciego a todo lo que no sea Roslyn.
      opts.registries = {
        "github:mason-org/mason-registry",
        "github:Crashdummyy/mason-registry",
      }

      -- En Linux/WSL la ruta por defecto no tiene espacios, así que no
      -- hace falta install_root_dir.

      if type(opts.ensure_installed) == "table" then
        table.insert(opts.ensure_installed, "roslyn")
      else
        opts.ensure_installed = { "roslyn" }
      end
    end,
  },

  -- 2) Apagamos el servidor omnisharp que trae el extra lang.dotnet,
  -- para que no queden los dos LSPs peleando por el mismo archivo .cs
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        omnisharp = { enabled = false },
      },
    },
  },

  {
    "seblyng/roslyn.nvim",
    ft = "cs",
    opts = {
      broad_search = true,
    },
    init = function()
      -- Solo mientras pruebas: el servidor se cierra al salir de Neovim
      vim.env.ROSLYN_LANGUAGE_SERVER_DAEMON_KEEPALIVE = "0"

      vim.lsp.config("roslyn", {
        cmd_env = {
          DOTNET_SYSTEM_GLOBALIZATION_INVARIANT = "1",
        },
      })
    end,
  },
  -- 3) El plugin de Roslyn en sí
  --[[  {
    "seblyng/roslyn.nvim",
    ft = "cs",
    config = true,
    opts = {
      -- Deja vacío para defaults razonables; opciones útiles:
      broad_search = true, -- busca el .sln en carpetas padre (monorepos)
      -- lock_target = true,   -- no te pregunta qué solución usar cada vez
      cmd_env = {
        DOTNET_CLI_UI_LANGUAGE = "en-US",
        VSLANG = "1033",
      },
    }, ]]
  -- },
}

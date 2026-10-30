-- Soporte para GDScript
-- Diferencia clave vs C#/C++: aquí NO instalas un servidor con Mason.
-- Godot YA trae su propio LSP integrado (como un servidor que "vive" dentro
-- del editor de Godot); Neovim solo se conecta a él por TCP, como un cliente
-- de chat conectándose a un servidor que ya está corriendo.
return {
  -- 1) Treesitter: para que resalte sintaxis, indente y entienda el código
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, { "gdscript", "godot-resource" })
    end,
  },

  -- 2) LSP: se conecta al servidor de Godot (Editor > Editor Settings >
  -- Network > Language Server debe estar habilitado, puerto 6005 por defecto)
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        gdscript = {
          -- nvim-lspconfig ya trae la configuración base para gdscript,
          -- solo la activamos aquí.
        },
      },
    },
  },

  -- 3) Formateo con gdformat (parte de gdtoolkit, instálalo con pipx/pip:
  -- `pip install gdtoolkit --break-system-packages` o `pipx install gdtoolkit`)
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        gdscript = { "gdformat" },
      },
      formatters = {
        gdformat = {
          command = "gdformat",
          args = { "-" },
          stdin = true,
        },
      },
    },
  },

  -- 4) Debugger (nvim-dap) para Godot GDScript
  {
    "mfussenegger/nvim-dap",
    optional = true,
    opts = function()
      local dap = require("dap")
      dap.adapters.godot = {
        type = "server",
        host = "127.0.0.1",
        port = 6006,
      }

      dap.configurations.gdscript = {
        {
          type = "godot",
          request = "launch",
          name = "Launch scene",
          project = "${workspaceFolder}",
          launch_scene = true,
        },
      }
    end,
  },
}

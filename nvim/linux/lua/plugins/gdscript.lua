-- Godot / GDScript
-- El LSP lo provee el editor de Godot por TCP (puerto 6005); aquí solo se
-- declara el debugger y el formateo (gdformat).
return {
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

local M = {}

-- Función compartida para restaurar dependencias y sincronizar diagnósticos de Roslyn
function M.restore_and_refresh(opts)
  opts = opts or {}
  local silent = opts.silent or false
  local notifier = Snacks and Snacks.notifier or nil

  if not silent then
    if notifier then
      notifier.notify("Ejecutando dotnet restore...", "info", { title = ".NET Restore", id = "dotnet_restore" })
    else
      vim.notify("Ejecutando dotnet restore...", vim.log.levels.INFO)
    end
  end

  -- Ejecutar dotnet restore en el directorio de trabajo del buffer actual
  local cwd = vim.fn.expand("%:p:h")
  if cwd == "" then
    cwd = vim.fn.getcwd()
  end

  vim.system({ "dotnet", "restore" }, { cwd = cwd }, function(obj)
    vim.schedule(function()
      if obj.code == 0 then
        -- Recargar buffers abiertos para refrescar cambios de disco
        vim.cmd("checktime")

        -- Reiniciar Roslyn LSP para que lea el .csproj actualizado y cargue los assemblies del nuget
        local clients = vim.lsp.get_clients({ name = "roslyn" })
        for _, client in ipairs(clients) do
          vim.lsp.stop_client(client.id)
        end
        -- Dejar que Neovim / roslyn.nvim vuelva a levantar el LSP automáticamente
        vim.defer_fn(function()
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "cs" then
              pcall(vim.api.nvim_buf_call, buf, function()
                vim.cmd("edit")
              end)
            end
          end
        end, 400)

        if notifier then
          notifier.notify("✓ Paquetes restaurados y servidor Roslyn sincronizado", "info", { id = "dotnet_restore" })
        else
          vim.notify("✓ Paquetes restaurados y servidor Roslyn sincronizado", vim.log.levels.INFO)
        end
      else
        local err_msg = (obj.stderr and obj.stderr ~= "") and obj.stderr or obj.stdout
        if notifier then
          notifier.notify("✗ Error en restore:\n" .. (err_msg or ""), "error", { id = "dotnet_restore" })
        else
          vim.notify("✗ Error en restore:\n" .. (err_msg or ""), vim.log.levels.ERROR)
        end
      end
    end)
  end)
end

return {
  {
    "d7omdev/nuget.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
    },
    cmd = { "NuGetInstall", "NuGetRemove", "NuGetClearCache" },
    keys = {
      { "<leader>dni", "<cmd>NuGetInstall<cr>", desc = ".NET: Instalar paquete NuGet" },
      { "<leader>dnx", "<cmd>NuGetRemove<cr>", desc = ".NET: Remover paquete NuGet" },
      { "<leader>dnc", "<cmd>NuGetClearCache<cr>", desc = ".NET: Limpiar caché NuGet" },
      {
        "<leader>dnr",
        function()
          M.restore_and_refresh({ silent = false })
        end,
        desc = ".NET: Restore y sincronizar LSP",
      },
    },
    config = function(_, opts)
      local nuget = require("nuget")
      nuget.setup(opts)

      -- Interceptar instalación y remoción de paquetes para auto-restaurar y refrescar
      local dotnet = require("nuget.dotnet")
      local orig_install = dotnet.install_package
      dotnet.install_package = function(target, id, version, d_opts, callback)
        orig_install(target, id, version, d_opts, function(ok, stdout, stderr)
          if ok then
            M.restore_and_refresh({ silent = false })
          end
          if callback then
            callback(ok, stdout, stderr)
          end
        end)
      end

      local orig_remove = dotnet.remove_package
      dotnet.remove_package = function(target, id, d_opts, callback)
        orig_remove(target, id, d_opts, function(ok, stdout, stderr)
          if ok then
            M.restore_and_refresh({ silent = false })
          end
          if callback then
            callback(ok, stdout, stderr)
          end
        end)
      end
    end,
    opts = {},
  },
}

-- Debugging para C#/.NET usando netcoredbg
-- Es el mismo adaptador que ya te funcionó en Zed, así que el comportamiento
-- te va a resultar familiar: netcoredbg habla el protocolo DAP directamente.
return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "mason-org/mason.nvim",
    },
    config = function()
      local dap = require("dap")

      -- Interceptar dap.run para compilar antes de cualquier inicio de depuración de C#
      local original_run = dap.run
      dap.run = function(config, opts)
        if config and (config.type == "coreclr" or config.type == "netcoredbg") then
          local notify_id = "dotnet_build_progress"
          local notifier = Snacks and Snacks.notifier or nil

          if notifier then
            notifier.notify("Compilando proyecto (dotnet build)...", "info", {
              title = ".NET Build",
              id = notify_id,
            })
          else
            vim.notify("Compilando proyecto (dotnet build)...", vim.log.levels.INFO)
          end

          vim.system({ "dotnet", "build" }, {}, function(obj)
            vim.schedule(function()
              if obj.code == 0 then
                if notifier then
                  notifier.notify("Compilación exitosa", "info", { id = notify_id })
                else
                  vim.notify("Compilación exitosa", vim.log.levels.INFO)
                end
                original_run(config, opts)
              else
                if notifier then
                  notifier.notify(
                    "Error de compilación:\n" .. (obj.stderr ~= "" and obj.stderr or obj.stdout),
                    "error",
                    { id = notify_id }
                  )
                else
                  vim.notify("Error de compilación:\n" .. obj.stderr, vim.log.levels.ERROR)
                end
              end
            end)
          end)
          return
        end
        original_run(config, opts)
      end

      -- Forzar a DAP a abrir terminales de depuración dentro de un panel en Neovim
      dap.defaults.fallback.terminal_win_cmd = "botright 12split new"

      dap.adapters.coreclr = {
        type = "executable",
        command = "C:/tools/nvim-mason/packages/netcoredbg/netcoredbg/netcoredbg.exe",
        args = { "--interpreter=vscode" },
      }
      dap.adapters.netcoredbg = dap.adapters.coreclr
      local function get_dll_path()
        local cwd = vim.fn.getcwd()
        -- Obtener el nombre del proyecto a partir del .csproj en el cwd o el nombre del directorio
        local csproj_files = vim.fn.globpath(cwd, "*.csproj", false, true)
        local project_name = ""
        if #csproj_files > 0 then
          project_name = vim.fn.fnamemodify(csproj_files[1], ":t:r")
        else
          project_name = vim.fn.fnamemodify(cwd, ":t")
        end

        -- 1. Intentar encontrar directamente la DLL exacta del proyecto en bin/Debug/
        local exact_matches = vim.fn.globpath(cwd, "**/bin/Debug/**/" .. project_name .. ".dll", false, true)
        local function normalize(p)
          return (p:gsub("\\", "/"))
        end

        if #exact_matches > 0 then
          return normalize(exact_matches[1])
        end

        -- 2. Si no coincide exactamente el nombre, filtrar dlls excluyendo dependencias/nativas
        local all_dlls = vim.fn.globpath(cwd, "**/bin/Debug/**/*.dll", false, true)
        if #all_dlls == 0 then
          all_dlls = vim.fn.globpath(cwd, "**/bin/**/*.dll", false, true)
        end

        local candidates = {}
        for _, path in ipairs(all_dlls) do
          local fname = vim.fn.fnamemodify(path, ":t")
          local is_third_party = fname:match("^lib")
            or fname:match("^runtimes")
            or fname:match("%.resources%.dll$")
            or fname:match("^System%.")
            or fname:match("^Microsoft%.")
            or fname:match("^Raylib")
            or fname:match("^raylib")
            or fname:match("^YoutubeExplode")
            or fname:match("^LibVLC")

          if not is_third_party then
            table.insert(candidates, normalize(path))
          end
        end

        if #candidates == 1 then
          return candidates[1]
        end

        if #candidates > 1 then
          local co = coroutine.running()
          if co then
            vim.ui.select(candidates, {
              prompt = "Selecciona la DLL principal a ejecutar:",
              format_item = function(item)
                return vim.fn.fnamemodify(item, ":.")
              end,
            }, function(choice)
              coroutine.resume(co, choice)
            end)
            return coroutine.yield()
          end
        end

        return vim.fn.input("Ruta al .dll: ", cwd .. "/bin/Debug/", "file")
      end

      dap.configurations.cs = {
        {
          type = "coreclr",
          name = "Lanzar .NET DLL",
          request = "launch",
          program = get_dll_path,
          cwd = "${workspaceFolder}",
          console = "integratedTerminal",
          internalConsoleOptions = "neverOpen",
          externalConsole = false,
        },
      }
    end,
  },
  {
    "jay-babu/mason-nvim-dap.nvim",
    opts = function(_, opts)
      opts.handlers = opts.handlers or {}
      opts.handlers.netcoredbg = function() end
      opts.handlers.coreclr = function() end
      -- Función fallback si intenta registrar cualquiera
      table.insert(opts.ensure_installed or {}, "netcoredbg")
    end,
  },
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "netcoredbg" } },
  },
}

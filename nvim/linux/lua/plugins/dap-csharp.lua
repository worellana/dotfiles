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

      -- Estado de la selección (DLL + argumentos + entorno) resuelta al lanzar.
      -- nvim-dap evalúa las funciones de la configuración en orden arbitrario,
      -- por eso todos los campos se resuelven una sola vez desde aquí.
      local launch_selection = { done = false, args = {}, env = {}, cwd = nil }
      local last_launch_args = {}

      local function reset_launch_selection()
        launch_selection.done = false
        launch_selection.dll = nil
        launch_selection.args = {}
        launch_selection.env = {}
        launch_selection.cwd = nil
      end

      -- Interceptar dap.run para compilar antes de cualquier inicio de depuración de C#
      local original_run = dap.run
      dap.run = function(config, opts)
        if config and (config.type == "coreclr" or config.type == "netcoredbg") then
          reset_launch_selection()
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

      -- Linux/WSL: el netcoredbg de Mason vive en libexec; en Windows estaba
      -- en la ruta sin espacios de C:/tools. Resolvemos ambos casos.
      local function netcoredbg_command()
        if vim.fn.has("win32") == 1 then
          return "C:/tools/nvim-mason/packages/netcoredbg/netcoredbg/netcoredbg.exe"
        end
        local mason_bin = vim.fn.stdpath("data") .. "/mason/packages/netcoredbg/libexec/netcoredbg/netcoredbg"
        if vim.fn.executable(mason_bin) == 1 then
          return mason_bin
        end
        local found = vim.fn.exepath("netcoredbg")
        return found ~= "" and found or "netcoredbg"
      end

      dap.adapters.coreclr = {
        type = "executable",
        command = netcoredbg_command(),
        args = { "--interpreter=vscode" },
      }
      dap.adapters.netcoredbg = dap.adapters.coreclr

      -- netcoredbg arranca el debuggee con dbgshim (CreateProcessForLaunch), que en
      -- Windows pasa CREATE_NEW_CONSOLE: se abre una ventana con la misma salida
      -- que ya llega al panel de nvim-dap. netcoredbg ignora `console` y
      -- `externalConsole`, así que ocultamos esa ventana al nacer el proceso.
      -- Se oculta con FFI si Neovim no tiene consola (Neovide/GUI) o, si la
      -- tiene, con un PowerShell oculto (`vim.system` usa CREATE_NO_WINDOW).
      local ps_hide_console = [[
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class NCBConsole {
  [DllImport("kernel32.dll", SetLastError = true)] public static extern bool AttachConsole(uint pid);
  [DllImport("kernel32.dll")] public static extern bool FreeConsole();
  [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int cmd);
}
'@
$targetPid = %d
$deadline = (Get-Date).AddSeconds(5)
while ((Get-Date) -lt $deadline) {
  [void][NCBConsole]::FreeConsole()
  if ([NCBConsole]::AttachConsole($targetPid)) {
    $hwnd = [NCBConsole]::GetConsoleWindow()
    if ($hwnd -ne [IntPtr]::Zero) {
      [void][NCBConsole]::ShowWindow($hwnd, 0)
      break
    }
    [void][NCBConsole]::FreeConsole()
  }
  Start-Sleep -Milliseconds 100
}
]]

      -- Camino rápido: solo si Neovim no tiene consola propia (Neovide/GUI).
      -- Con consola (nvim en una terminal) FreeConsole desconectaría el
      -- terminal del editor, así que ese caso lo resuelve el PowerShell.
      local function hide_console_in_process(pid)
        if vim.fn.has("win32") ~= 1 then
          return false
        end
        local ok, ffi = pcall(require, "ffi")
        if not ok then
          return false
        end
        pcall(
          ffi.cdef,
          [[
          typedef unsigned long DWORD;
          typedef int BOOL;
          void *GetConsoleWindow(void);
          BOOL FreeConsole(void);
          BOOL AttachConsole(DWORD dwProcessId);
          BOOL ShowWindow(void *hWnd, int nCmdShow);
          DWORD GetConsoleProcessList(DWORD *list, DWORD count);
        ]]
        )
        local C = ffi.C
        if
          not (C.GetConsoleWindow and C.FreeConsole and C.AttachConsole and C.ShowWindow and C.GetConsoleProcessList)
        then
          return false
        end
        if tonumber(C.GetConsoleProcessList(ffi.new("DWORD[2]"), 2)) ~= 0 then
          return false
        end
        C.FreeConsole()
        if C.AttachConsole(pid) == 0 then
          return false
        end
        local hwnd = C.GetConsoleWindow()
        if hwnd ~= ffi.NULL then
          C.ShowWindow(hwnd, 0) -- SW_HIDE
        end
        C.FreeConsole()
        return hwnd ~= ffi.NULL
      end

      local function hide_console_window(pid)
        local target = tonumber(pid)
        if not target or target <= 0 then
          return
        end
        if hide_console_in_process(target) then
          return
        end
        if vim.fn.has("win32") ~= 1 then
          return
        end
        vim.system({
          "powershell",
          "-NoProfile",
          "-NonInteractive",
          "-ExecutionPolicy",
          "Bypass",
          "-WindowStyle",
          "Hidden",
          "-Command",
          string.format(ps_hide_console, target),
        }, { hide = true }, function() end)
      end

      dap.listeners.after.event_process["netcoredbg_hide_console"] = function(session, body)
        if not session or not session.config or session.config.type ~= "coreclr" then
          return
        end
        local pid = type(body) == "table" and body.systemProcessId or nil
        if pid then
          hide_console_window(pid)
        end
      end

      -- Separa una línea de argumentos respetando comillas: -a "b c" -> { "-a", "b c" }
      local function split_args(str)
        local args, current, quote, started = {}, {}, nil, false
        for i = 1, #str do
          local c = str:sub(i, i)
          if quote then
            if c == quote then
              quote = nil
            else
              current[#current + 1] = c
            end
          elseif c == '"' or c == "'" then
            quote, started = c, true
          elseif c:match("%s") then
            if started then
              args[#args + 1] = table.concat(current)
              current, started = {}, false
            end
          else
            current[#current + 1] = c
            started = true
          end
        end
        if started then
          args[#args + 1] = table.concat(current)
        end
        return args
      end

      -- Esperan la respuesta de la UI sin bloquear: nvim-dap resuelve la
      -- configuración dentro de una corrutina (mismo patrón que el picker viejo).
      local function ui_select(items, prompt, format_item)
        local co = coroutine.running()
        if not co then
          return nil
        end
        local choice
        vim.ui.select(items, { prompt = prompt, format_item = format_item }, function(item)
          if coroutine.status(co) == "suspended" then
            choice = item
            coroutine.resume(co)
          end
        end)
        coroutine.yield()
        return choice
      end

      local function ui_input(prompt, default)
        local co = coroutine.running()
        if not co then
          return vim.fn.input(prompt, default)
        end
        local value
        vim.ui.input({ prompt = prompt, default = default }, function(input)
          if coroutine.status(co) == "suspended" then
            value = input
            coroutine.resume(co)
          end
        end)
        coroutine.yield()
        return value
      end

      -- Mapa nombre_de_ensamblado -> directorio del .csproj (ignora bin/ y obj/)
      local function discover_projects(cwd)
        local projects = {}
        for _, csproj in ipairs(vim.fn.globpath(cwd, "**/*.csproj", false, true)) do
          local path = (csproj:gsub("\\", "/"))
          if not path:find("/bin/", 1, true) and not path:find("/obj/", 1, true) then
            local name = vim.fn.fnamemodify(csproj, ":t:r")
            local fh = io.open(csproj, "r")
            if fh then
              local content = fh:read("*a") or ""
              fh:close()
              local asm = content:match("<AssemblyName>%s*([^<]-)%s*</AssemblyName>")
              if asm and asm ~= "" then
                name = asm
              end
            end
            projects[name] = (vim.fn.fnamemodify(csproj, ":h"):gsub("\\", "/"))
          end
        end
        return projects
      end

      -- Perfiles ejecutables de Properties/launchSettings.json (equivalente a --launch-profile)
      local function read_launch_settings(project_dir)
        local file = project_dir .. "/Properties/launchSettings.json"
        if vim.fn.filereadable(file) == 0 then
          return {}
        end
        local content = table.concat(vim.fn.readfile(file), "\n")
        if content:sub(1, 3) == "\239\187\191" then
          content = content:sub(4)
        end
        local ok, data = pcall(vim.json.decode, content)
        if not ok or type(data) ~= "table" or type(data.profiles) ~= "table" then
          return {}
        end
        local profiles = {}
        for name, prof in pairs(data.profiles) do
          if type(prof) == "table" and (prof.commandName == nil or prof.commandName == "Project") then
            profiles[#profiles + 1] = {
              name = name,
              args = prof.commandLineArgs or "",
              env = prof.environmentVariables,
              urls = prof.applicationUrl,
            }
          end
        end
        table.sort(profiles, function(a, b)
          return a.name < b.name
        end)
        return profiles
      end

      -- Solo ensamblados generados por los .csproj del workspace: nada de
      -- paquetes NuGet ni librerías nativas copiadas al output.
      local function find_project_dlls(cwd, projects, preferred)
        local found, order = {}, {}
        for _, pattern in ipairs({ "**/bin/Debug/**/*.dll", "**/bin/**/*.dll" }) do
          for _, path in ipairs(vim.fn.globpath(cwd, pattern, false, true)) do
            local norm = (path:gsub("\\", "/"))
            local asm = vim.fn.fnamemodify(norm, ":t:r")
            local project_dir = projects[asm]
            if project_dir and not norm:match("/obj/") and not norm:match("/ref/") and not norm:match("/runtimes/") then
              local own = norm:find(project_dir .. "/bin/", 1, true) ~= nil
              local previous = found[asm]
              if not previous then
                order[#order + 1] = asm
                found[asm] = { path = norm, own = own }
              elseif own and not previous.own then
                found[asm] = { path = norm, own = true }
              end
            end
          end
        end

        local candidates = {}
        for _, asm in ipairs(order) do
          candidates[#candidates + 1] = { asm = asm, path = found[asm].path }
        end
        table.sort(candidates, function(a, b)
          if (a.asm == preferred) ~= (b.asm == preferred) then
            return a.asm == preferred
          end
          return a.asm < b.asm
        end)

        if #candidates == 0 then
          return nil
        end
        if #candidates == 1 or candidates[1].asm == preferred then
          return candidates[1].path
        end

        local choice = ui_select(candidates, "Selecciona el ensamblado a ejecutar:", function(item)
          return vim.fn.fnamemodify(item.path, ":.")
        end)
        if choice == nil then
          return false -- cancelado por el usuario
        end
        return choice.path
      end

      -- Pregunta ensamblado -> perfil de lanzamiento -> argumentos, una sola vez.
      local function resolve_launch_selection()
        if launch_selection.done then
          return
        end
        launch_selection.done = true
        launch_selection.dll, launch_selection.args, launch_selection.env = nil, {}, {}
        launch_selection.cwd = nil

        local cwd = vim.fn.getcwd()
        local projects = discover_projects(cwd)

        -- Proyecto principal: el .csproj del cwd o, si no hay, el nombre de la carpeta
        local local_csproj = vim.fn.globpath(cwd, "*.csproj", false, true)
        local main_name = #local_csproj > 0 and vim.fn.fnamemodify(local_csproj[1], ":t:r")
          or vim.fn.fnamemodify(cwd, ":t")

        local dll = find_project_dlls(cwd, projects, main_name)
        if dll == false then
          launch_selection.dll = dap.ABORT
          return
        end
        if not dll then
          local typed = vim.fn.input("Ruta al .dll: ", cwd .. "/bin/Debug/", "file")
          if typed == "" then
            launch_selection.dll = dap.ABORT
            return
          end
          dll = (typed:gsub("\\", "/"))
        end
        launch_selection.dll = dll

        local asm = vim.fn.fnamemodify(dll, ":t:r")
        -- El content root de una app ASP.NET es su cwd: debe ser el directorio del
        -- proyecto (donde viven appsettings*.json), no la raiz del workspace.
        local project_dir = projects[asm] or vim.fn.fnamemodify(dll, ":h")
        local profiles = projects[asm] and read_launch_settings(projects[asm]) or {}
        local profile
        if #profiles > 0 then
          local items = { { name = "(sin perfil)" } }
          vim.list_extend(items, profiles)
          profile = ui_select(items, "Perfil de lanzamiento:", function(item)
            return item.name
          end)
          if not profile then
            launch_selection.dll = dap.ABORT
            return
          end
        end

        local env = {}
        if profile and profile.env then
          for k, v in pairs(profile.env) do
            if type(v) == "string" and v ~= "" then
              env[k] = v
            end
          end
        end
        if profile and profile.urls and profile.urls ~= "" and not env.ASPNETCORE_URLS then
          env.ASPNETCORE_URLS = profile.urls
        end

        -- 'dotnet run' aplica launchSettings.json; al lanzar la DLL hay que
        -- replicarlo. Sin Development no se cargan appsettings.Development.json
        -- ni los user-secrets (Jwt:SigningKey) y la app muere al arrancar.
        env.ASPNETCORE_ENVIRONMENT = env.ASPNETCORE_ENVIRONMENT or "Development"
        env.DOTNET_ENVIRONMENT = env.DOTNET_ENVIRONMENT or "Development"
        launch_selection.cwd = project_dir

        local default_args = last_launch_args[asm] or (profile and profile.args) or ""
        local extra = ui_input("Argumentos de arranque para " .. asm .. ": ", default_args)
        local args = {}
        if extra and extra ~= "" then
          args = split_args(extra)
          last_launch_args[asm] = extra
        end

        launch_selection.args = args
        -- netcoredbg espera un objeto JSON; una tabla vacía se serializa como []
        launch_selection.env = next(env) and env or nil
      end

      dap.configurations.cs = {
        {
          type = "coreclr",
          name = "Lanzar .NET DLL",
          request = "launch",
          program = function()
            resolve_launch_selection()
            return launch_selection.dll
          end,
          args = function()
            resolve_launch_selection()
            return launch_selection.args
          end,
          env = function()
            resolve_launch_selection()
            return launch_selection.env
          end,
          cwd = function()
            resolve_launch_selection()
            return launch_selection.cwd
          end,
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

-- Debugging para C/C++ usando CodeLLDB (via Mason)
return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "mason-org/mason.nvim",
    },
    opts = function()
      local dap = require("dap")

      local codelldb_path = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/adapter/codelldb.exe"
      local is_win = vim.fn.has("win32") == 1
      if not is_win then
        codelldb_path = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/adapter/codelldb"
      end

      -- En Linux/WSL los ejecutables no llevan extensión.
      local exe_ext = is_win and ".exe" or ""

      -- Lista ejecutables directos de un directorio según la plataforma.
      local function executables_in(dir)
        if is_win then
          return vim.fn.glob(dir .. "/*.exe", false, true)
        end
        local out = {}
        for _, f in ipairs(vim.fn.glob(dir .. "/*", false, true)) do
          if vim.fn.isdirectory(f) == 0 and vim.fn.executable(f) == 1 then
            table.insert(out, f)
          end
        end
        return out
      end

      -- Flags del proyecto para no duplicar configuración entre clangd/cmake y DAP
      local function normalize_path(p)
        return (p:gsub("\\", "/"):lower())
      end

      -- ponytail: split mínimo; soporta comillas dobles (rutas con espacios de CMake)
      local function split_quoted(s)
        local out, i = {}, 1
        while i <= #s do
          local c = s:sub(i, i)
          if c:match("%s") then
            i = i + 1
          elseif c == '"' then
            local j = s:find('"', i + 1, true)
            if not j then
              break
            end
            table.insert(out, s:sub(i + 1, j - 1))
            i = j + 1
          else
            local j = s:find("%s", i)
            table.insert(out, j and s:sub(i, j - 1) or s:sub(i))
            i = j or (#s + 1)
          end
        end
        return out
      end

      -- ponytail: YAML a mano. Solo entiende CompileFlags.Add como lista de flujo o de bloque.
      local function clangd_flags(file)
        local dir = vim.fn.fnamemodify(file, ":h")
        while true do
          local cfg = dir .. "/.clangd"
          if vim.fn.filereadable(cfg) == 1 then
            local flags, in_add, add_indent = {}, false, 0
            for _, line in ipairs(vim.fn.readfile(cfg)) do
              local indent = #(line:match("^%s*") or "")
              local body = line:match("^%s*(.-)%s*$")
              local flow = body:match("^Add:%s*%[(.*)%]")
              if flow then
                for tok in flow:gmatch("[^,%s]+") do
                  table.insert(flags, tok)
                end
                in_add = false
              elseif body:match("^Add:%s*$") then
                in_add, add_indent = true, indent
              elseif in_add then
                local item = body:match("^%-%s*(.+)$")
                if item and indent >= add_indent then
                  table.insert(flags, item)
                elseif body ~= "" then
                  in_add = false
                end
              end
            end
            if #flags > 0 then
              return flags
            end
          end
          local parent = vim.fn.fnamemodify(dir, ":h")
          if parent == dir then
            return {}
          end
          dir = parent
        end
      end

      -- Flags reales de compilación del archivo según compile_commands.json (CMake)
      local function compile_db_flags(file)
        local target = normalize_path(file)
        for _, db_path in ipairs({ vim.fn.getcwd() .. "/build/compile_commands.json", vim.fn.getcwd() .. "/compile_commands.json" }) do
          if vim.fn.filereadable(db_path) == 1 then
            local ok, db = pcall(function()
              return vim.json.decode(table.concat(vim.fn.readfile(db_path), "\n"))
            end)
            if ok and type(db) == "table" then
              for _, entry in ipairs(db) do
                if entry.file and normalize_path(entry.file) == target then
                  local args = entry.arguments
                  if not args and entry.command then
                    args = split_quoted(entry.command)
                  end
                  if args then
                    local fname_l = vim.fn.fnamemodify(file, ":t"):lower()
                    local flags, i = {}, 2 -- se salta el compilador
                    while i <= #args do
                      local a = args[i]
                      local base = vim.fn.fnamemodify(a:gsub("\\", "/"), ":t"):lower()
                      if a == "-o" or a == "-MF" or a == "-MT" then
                        i = i + 2
                      elseif a == "-c" or a == "-MD" or a == "-MMD" or normalize_path(a) == target or base == fname_l then
                        i = i + 1
                      else
                        table.insert(flags, a)
                        i = i + 1
                      end
                    end
                    return flags
                  end
                end
              end
            end
          end
        end
        return {}
      end

      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          command = codelldb_path,
          args = { "--port", "${port}" },
        },
      }

      local compile_single_file = function(ask_flags)
        local co = coroutine.running()
        local cwd = vim.fn.getcwd()
        local build_dir = cwd .. "/build"
        if vim.fn.isdirectory(build_dir) == 0 then
          vim.fn.mkdir(build_dir, "p")
        end

        local file = vim.fn.expand("%:p")
        local fname = vim.fn.expand("%:t:r")
        local output = build_dir .. "/" .. fname .. exe_ext
        local ft = vim.bo.filetype

        local compiler = (ft == "cpp") and "clang++" or "clang"
        if vim.fn.executable(compiler) == 0 then
          error("No se encontró " .. compiler .. " en el PATH")
        end

        local custom_flags = {}
        if ask_flags then
          local raw_flags = vim.fn.input("Argumentos del compilador (ej. -std=c11 -Wall): ")
          if vim.fn.has("win32") == 1 then
            raw_flags = raw_flags:gsub("%s*-lm%s*", " ")
          end
          for flag in raw_flags:gmatch("%S+") do
            table.insert(custom_flags, flag)
          end
        end

        local notify_id = "cpp_compile_" .. fname
        local notifier = Snacks and Snacks.notifier or nil
        if notifier then
          notifier.notify("Compilando " .. fname .. " con " .. compiler .. "...", "info", {
            title = "Compilador C/C++",
            id = notify_id,
          })
        else
          vim.notify("Compilando " .. fname .. "...", vim.log.levels.INFO)
        end

        -- Fuente única de flags: compile_commands.json (CMake) > .clangd > default
        local project_flags = compile_db_flags(file)
        if #project_flags == 0 then
          project_flags = clangd_flags(file)
        end
        local has_std = false
        for _, flag in ipairs(project_flags) do
          if flag:match("^%-std=") then
            has_std = true
          end
        end
        if not has_std and ft == "cpp" then
          -- sin -std, clang cae a C++17 y <print>/std::println no existen
          table.insert(project_flags, "-std=c++23")
        end

        local cmd = { compiler, "-g" }
        vim.list_extend(cmd, project_flags)
        for _, flag in ipairs(custom_flags) do
          table.insert(cmd, flag)
        end
        table.insert(cmd, file)
        table.insert(cmd, "-o")
        table.insert(cmd, output)

        if co then
          vim.system(cmd, {}, function(obj)
            vim.schedule(function()
              if obj.code ~= 0 then
                local err_msg = (obj.stderr and obj.stderr ~= "") and obj.stderr or obj.stdout
                err_msg = err_msg or ""

                -- Limpiar caracteres ^M (\r)
                local lines = {}
                for line in err_msg:gsub("\r", ""):gmatch("[^\r\n]+") do
                  table.insert(lines, line)
                end

                -- Cargar errores en Quickfix List y abrir ventana
                vim.fn.setqflist({}, "r", { title = "Compilación C/C++", lines = lines })
                vim.cmd("copen")

                if notifier then
                  notifier.notify("Error de compilación. Ver Quickfix list.", "error", { id = notify_id })
                else
                  vim.notify("Error de compilación. Ver Quickfix list.", vim.log.levels.ERROR)
                end
                coroutine.resume(co, nil)
              else
                vim.cmd("cclose")
                if notifier then
                  notifier.notify("Compilación finalizada exitosamente", "info", { id = notify_id })
                else
                  vim.notify("Compilación exitosa", vim.log.levels.INFO)
                end
                coroutine.resume(co, output)
              end
            end)
          end)
          local res = coroutine.yield()
          if not res then
            error("Compilación fallida.")
          end
          return res
        else
          local res = vim.fn.system(cmd)
          if vim.v.shell_error ~= 0 then
            local lines = {}
            for line in res:gsub("\r", ""):gmatch("[^\r\n]+") do
              table.insert(lines, line)
            end
            vim.fn.setqflist({}, "r", { title = "Compilación C/C++", lines = lines })
            vim.cmd("copen")
            error("Error de compilación.")
          end
          return output
        end
      end

      local auto_config = {
        {
          name = "Compilar y Lanzar (Auto)",
          type = "codelldb",
          request = "launch",
          program = function()
            local cwd = vim.fn.getcwd()
            local cmakelists = cwd .. "/CMakeLists.txt"

            if vim.fn.filereadable(cmakelists) == 1 then
              print("CMakeLists.txt detectado. Compilando con CMake...")
              local build_dir = cwd .. "/build"

              -- Exportamos compile_commands.json automáticamente para clangd/LSP
              local res =
                vim.fn.system({ "cmake", "-B", build_dir, "-DCMAKE_BUILD_TYPE=Debug", "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON" })
              if vim.v.shell_error ~= 0 then
                error("Error al configurar con CMake:\n" .. res)
              end
              res = vim.fn.system({ "cmake", "--build", build_dir })
              if vim.v.shell_error ~= 0 then
                error("Error al compilar con CMake:\n" .. res)
              end

              -- Buscar ejecutables válidos ignorando carpetas de Build internas y dependencias
              local all_exes
              if is_win then
                all_exes = vim.fn.glob(build_dir .. "/**/*.exe", false, true)
              else
                all_exes = {}
                for _, p in ipairs(vim.fn.glob(build_dir .. "/**/*", false, true)) do
                  if vim.fn.isdirectory(p) == 0 and vim.fn.executable(p) == 1 then
                    table.insert(all_exes, p)
                  end
                end
              end
              local exes = {}
              for _, exe in ipairs(all_exes) do
                local normalized = exe:gsub("\\", "/")
                if
                  not normalized:find("CMakeFiles")
                  and not normalized:find("CompilerId")
                  and not normalized:find("external")
                then
                  table.insert(exes, exe)
                end
              end

              if #exes == 1 then
                return exes[1]
              elseif #exes > 1 then
                -- Si hay varios (ej. pruebas o utilidades), permite seleccionar cuál depurar
                return vim.fn.input("Selecciona ejecutable: ", exes[1], "file")
              else
                error("No se encontró ningún ejecutable del proyecto generado en build/")
              end
            end

            -- Makefile: compila con make/mingw32-make y busca el .exe generado
            for _, name in ipairs({ "Makefile", "makefile", "GNUmakefile" }) do
              if vim.fn.filereadable(cwd .. "/" .. name) == 1 then
                local make = (vim.fn.executable("make") == 1) and "make" or "mingw32-make"
                if vim.fn.executable(make) == 0 then
                  error("Hay " .. name .. " pero no encontré 'make' ni 'mingw32-make' en el PATH")
                end
                print(name .. " detectado. Compilando con " .. make .. "...")
                local res = vim.fn.system({ make, "-C", cwd })
                if vim.v.shell_error ~= 0 then
                  error("Error al compilar con Makefile:\n" .. res)
                end

                local patterns
                if is_win then
                  patterns = { cwd .. "/*.exe", cwd .. "/build/*.exe", cwd .. "/bin/*.exe" }
                else
                  patterns = { cwd .. "/*", cwd .. "/build/*", cwd .. "/bin/*" }
                end
                local exes = {}
                for _, pattern in ipairs(patterns) do
                  for _, exe in ipairs(vim.fn.glob(pattern, false, true)) do
                    local normalized = exe:gsub("\\", "/")
                    local is_executable = is_win or (vim.fn.isdirectory(exe) == 0 and vim.fn.executable(exe) == 1)
                    if
                      is_executable
                      and not normalized:find("CMakeFiles")
                      and not normalized:find("CompilerId")
                    then
                      table.insert(exes, exe)
                    end
                  end
                end

                if #exes == 0 then
                  error("Makefile compiló, pero no encontré ningún ejecutable en cwd, build/ ni bin/")
                elseif #exes == 1 then
                  return exes[1]
                else
                  return vim.fn.input("Selecciona ejecutable: ", exes[1], "file")
                end
              end
            end

            return compile_single_file(false)
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
          -- codelldb >= 1.11.6 lanza su helper `codelldb-launch` para
          -- integratedTerminal, que espera el JSON de VS Code por stdin y
          -- con nvim-dap muere con "EOF while parsing a value".
          console = "internalConsole",
          args = {},
        },
        {
          name = "Compilar con Argumentos y Lanzar",
          type = "codelldb",
          request = "launch",
          program = function()
            return compile_single_file(true)
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
          -- codelldb >= 1.11.6 lanza su helper `codelldb-launch` para
          -- integratedTerminal, que espera el JSON de VS Code por stdin y
          -- con nvim-dap muere con "EOF while parsing a value".
          console = "internalConsole",
          args = {},
        },
      }

      local rust_config = {
        {
          name = "Cargo Build & Run",
          type = "codelldb",
          request = "launch",
          program = function()
            local co = coroutine.running()
            local cwd = vim.fn.getcwd()
            local cargotoml = cwd .. "/Cargo.toml"
            local notifier = Snacks and Snacks.notifier or nil
            local notify_id = "rust_compile"

            if vim.fn.filereadable(cargotoml) == 1 then
              if notifier then
                notifier.notify("Compilando proyecto Cargo (cargo build)...", "info", {
                  title = "Rust Compiler",
                  id = notify_id,
                })
              else
                vim.notify("Compilando proyecto Cargo...", vim.log.levels.INFO)
              end

              if co then
                vim.system({ "cargo", "build" }, {}, function(obj)
                  vim.schedule(function()
                    if obj.code ~= 0 then
                      if notifier then
                        notifier.notify(
                          "Error de compilación en Cargo:\n" .. (obj.stderr or ""),
                          "error",
                          { id = notify_id }
                        )
                      else
                        vim.notify("Error en Cargo", vim.log.levels.ERROR)
                      end
                      coroutine.resume(co, nil)
                    else
                      if notifier then
                        notifier.notify("Compilación Cargo exitosa", "info", { id = notify_id })
                      else
                        vim.notify("Cargo build exitoso", vim.log.levels.INFO)
                      end

                      local target_debug = cwd .. "/target/debug"
                      local exes = executables_in(target_debug)
                      if #exes >= 1 then
                        coroutine.resume(co, exes[1])
                      else
                        coroutine.resume(co, nil)
                      end
                    end
                  end)
                end)
                local res = coroutine.yield()
                if not res then
                  error("Error al compilar con Cargo")
                end
                return res
              else
                local res = vim.fn.system("cargo build")
                if vim.v.shell_error ~= 0 then
                  error("Error al compilar con Cargo:\n" .. res)
                end
                local target_debug = cwd .. "/target/debug"
                local exes = executables_in(target_debug)
                if #exes >= 1 then
                  return exes[1]
                end
              end
            end

            local build_dir = cwd .. "/build"
            if vim.fn.isdirectory(build_dir) == 0 then
              vim.fn.mkdir(build_dir, "p")
            end

            local file = vim.fn.expand("%:p")
            local fname = vim.fn.expand("%:t:r")
            local output = build_dir .. "/" .. fname .. exe_ext

            if notifier then
              notifier.notify("Compilando con rustc: " .. fname .. "...", "info", {
                title = "Rust Compiler",
                id = notify_id,
              })
            else
              vim.notify("Compilando con rustc: " .. file .. "...", vim.log.levels.INFO)
            end

            local cmd = { "rustc", "-g", file, "-o", output }

            if co then
              vim.system(cmd, {}, function(obj)
                vim.schedule(function()
                  if obj.code ~= 0 then
                    if notifier then
                      notifier.notify(
                        "Error de compilación rustc:\n" .. (obj.stderr or ""),
                        "error",
                        { id = notify_id }
                      )
                    else
                      vim.notify("Error de compilación con rustc", vim.log.levels.ERROR)
                    end
                    coroutine.resume(co, nil)
                  else
                    if notifier then
                      notifier.notify("Compilación rustc exitosa", "info", { id = notify_id })
                    else
                      vim.notify("Compilación rustc exitosa", vim.log.levels.INFO)
                    end
                    coroutine.resume(co, output)
                  end
                end)
              end)
              local res = coroutine.yield()
              if not res then
                error("Error de compilación con rustc")
              end
              return res
            else
              local res = vim.fn.system(table.concat(cmd, " "))
              if vim.v.shell_error ~= 0 then
                error("Error de compilación con rustc:\n" .. res)
              end
              return output
            end
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
          -- codelldb >= 1.11.6 lanza su helper `codelldb-launch` para
          -- integratedTerminal, que espera el JSON de VS Code por stdin y
          -- con nvim-dap muere con "EOF while parsing a value".
          console = "internalConsole",
          args = {},
        },
      }

      dap.configurations.cpp = auto_config
      dap.configurations.c = auto_config
      dap.configurations.rust = rust_config
    end,
  },
  {
    "jay-babu/mason-nvim-dap.nvim",
    opts = {
      automatic_installation = false,
      handlers = {
        codelldb = function() end,
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "codelldb" } },
  },
}

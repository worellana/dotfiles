return {
  {
    "mfussenegger/nvim-dap",
    opts = function()
      local dap = require("dap")

      local js_debug_path = vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js"

      dap.adapters["pwa-node"] = {
        type = "server",
        host = "localhost",
        port = "${port}",
        executable = {
          command = "node",
          args = { js_debug_path, "${port}" },
        },
      }

      -- Función para compilar asíncronamente y obtener la ruta del archivo en dist
      local function get_compiled_file()
        local co = coroutine.running()
        local notify_id = "ts_compile_progress"
        local notifier = Snacks and Snacks.notifier or nil

        if notifier then
          notifier.notify("Compilando TypeScript (tsc)...", "info", {
            title = "TypeScript Compiler",
            id = notify_id,
          })
        else
          vim.notify("Compilando TypeScript...", vim.log.levels.INFO)
        end

        local cmd = { "pnpm", "exec", "tsc", "-p", "tsconfig.json", "--pretty", "false" }

        if co then
          vim.system(cmd, {}, function(obj)
            vim.schedule(function()
              if obj.code ~= 0 then
                local err = (obj.stderr and obj.stderr ~= "") and obj.stderr or obj.stdout
                if notifier then
                  notifier.notify("Error al compilar TypeScript:\n" .. (err or ""), "error", { id = notify_id })
                else
                  vim.notify("Error al compilar TypeScript:\n" .. (err or ""), vim.log.levels.ERROR)
                end
                coroutine.resume(co, nil)
              else
                if notifier then
                  notifier.notify("TypeScript compilado exitosamente", "info", { id = notify_id })
                else
                  vim.notify("TypeScript compilado exitosamente", vim.log.levels.INFO)
                end

                local current = vim.fn.expand("%:p")
                local compiled = current:gsub("[/\\]src[/\\]", "/dist/"):gsub("%.ts$", ".js")

                if vim.fn.filereadable(compiled) == 0 then
                  if notifier then
                    notifier.notify("No se encontró el archivo compilado:\n" .. compiled, "error", { id = notify_id })
                  else
                    vim.notify("No se encontró el archivo compilado:\n" .. compiled, vim.log.levels.ERROR)
                  end
                  coroutine.resume(co, nil)
                else
                  coroutine.resume(co, compiled)
                end
              end
            end)
          end)
          local res = coroutine.yield()
          if not res then
            error("Falló la compilación de TypeScript.")
          end
          return res
        else
          local result = vim.fn.system("pnpm exec tsc -p tsconfig.json --pretty false")
          if vim.v.shell_error ~= 0 then
            vim.notify("Error al compilar TypeScript:\n" .. result, vim.log.levels.ERROR)
            return nil
          end

          local current = vim.fn.expand("%:p")
          local compiled = current:gsub("[/\\]src[/\\]", "/dist/"):gsub("%.ts$", ".js")

          if vim.fn.filereadable(compiled) == 0 then
            vim.notify("No se encontró el archivo compilado:\n" .. compiled, vim.log.levels.ERROR)
            return nil
          end

          return compiled
        end
      end

      local configs = {
        -- Opción 1: Desarrollo rápido (recomendado día a día)
        {
          type = "pwa-node",
          request = "launch",
          name = "Desarrollo (tsx) - NVIM",
          runtimeExecutable = "pnpm",
          runtimeArgs = { "exec", "tsx", "${file}" },
          cwd = "${workspaceFolder}",
          console = "internalConsole",
          skipFiles = {
            "<node_internals>/**",
            "node_modules/**",
          },
        },

        -- Opción 2: Compilar + Ejecutar (para probar el build de producción)
        {
          type = "pwa-node",
          request = "launch",
          name = "Producción (compilar a dist) - NVIM",
          program = get_compiled_file,
          cwd = "${workspaceFolder}",
          sourceMaps = true,
          outFiles = { "${workspaceFolder}/dist/**/*.js" },
          console = "internalConsole",
          skipFiles = {
            "<node_internals>/**",
            "node_modules/**",
          },
        },
      }

      dap.configurations.typescript = configs
      dap.configurations.javascript = configs
    end,
  },
}

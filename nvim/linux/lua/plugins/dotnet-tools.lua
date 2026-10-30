local M = {}

-- Ejecutar el archivo C# actual directamente (File-based apps: dotnet run <archivo.cs>)
function M.run_current_file()
  local file = vim.fn.expand("%:p")
  if file == "" or vim.fn.expand("%:e") ~= "cs" then
    vim.notify("El archivo actual no es un archivo .cs válido.", vim.log.levels.WARN)
    return
  end

  -- Guardar archivo si tiene cambios pendientes
  if vim.bo.modified then
    vim.cmd("write")
  end

  local filename = vim.fn.expand("%:t")
  local cmd = string.format("dotnet run %s", vim.fn.shellescape(file))

  -- Si ToggleTerm está instalado, ejecutarlo en una terminal flotante interactiva
  local has_toggleterm, toggleterm = pcall(require, "toggleterm.terminal")
  if has_toggleterm then
    local term = toggleterm.Terminal:new({
      cmd = cmd,
      direction = "float",
      close_on_exit = false,
      float_opts = {
        border = "curved",
        title = " .NET Run (" .. filename .. ") ",
      },
    })
    term:toggle()
  else
    -- Fallback con terminal nativa
    vim.cmd("split | terminal " .. cmd)
  end
end

-- Función para deducir el namespace a partir del directorio y del .csproj más cercano
function M.infer_namespace(target_dir)
  target_dir = target_dir or vim.fn.expand("%:p:h")
  if target_dir == "" then
    target_dir = vim.fn.getcwd()
  end

  -- Buscar .csproj hacia arriba
  local current = target_dir
  local csproj_path = nil
  local project_root = nil

  while current and current ~= "" do
    local csprojs = vim.fn.glob(current .. "/*.csproj", false, true)
    if #csprojs > 0 then
      csproj_path = csprojs[1]
      project_root = current
      break
    end
    local parent = vim.fn.fnamemodify(current, ":h")
    if parent == current then
      break
    end
    current = parent
  end

  if not csproj_path then
    return "App"
  end

  local project_name = vim.fn.fnamemodify(csproj_path, ":t:r")

  -- Obtener subcarpetas relativas a la raíz del proyecto
  local rel_path = target_dir:sub(#project_root + 2)
  if rel_path == "" then
    return project_name
  end

  -- Reemplazar separadores de ruta por '.'
  local sub_ns = rel_path:gsub("[/\\]", ".")
  return project_name .. "." .. sub_ns
end

-- Plantillas de archivos individuales estilo Visual Studio + Script C#
local ITEM_TEMPLATES = {
  {
    label = "Script C# / File-based App (C# 14 / .NET 10+)",
    desc = "Directivas #:package y top-level statements sin .csproj",
    ext = ".cs",
    generate = function(ns, name)
      return [[// #:package Spectre.Console
// #:property Nullable=enable

using System;

Console.WriteLine("¡Hola desde C# File-based App!");
]]
    end,
  },
  {
    label = "Clase (Class)",
    desc = "public class",
    ext = ".cs",
    generate = function(ns, name)
      return string.format(
        [[namespace %s;

public class %s
{

}
]],
        ns,
        name
      )
    end,
  },
  {
    label = "Interfaz (Interface)",
    desc = "public interface",
    ext = ".cs",
    generate = function(ns, name)
      if not name:match("^I[A-Z]") then
        name = "I" .. name
      end
      return string.format(
        [[namespace %s;

public interface %s
{

}
]],
        ns,
        name
      )
    end,
  },
  {
    label = "Registro (Record / DTO)",
    desc = "public record",
    ext = ".cs",
    generate = function(ns, name)
      return string.format(
        [[namespace %s;

public record %s();
]],
        ns,
        name
      )
    end,
  },
  {
    label = "Enumeración (Enum)",
    desc = "public enum",
    ext = ".cs",
    generate = function(ns, name)
      return string.format(
        [[namespace %s;

public enum %s
{

}
]],
        ns,
        name
      )
    end,
  },
  {
    label = "Estructura (Struct)",
    desc = "public struct",
    ext = ".cs",
    generate = function(ns, name)
      return string.format(
        [[namespace %s;

public struct %s
{

}
]],
        ns,
        name
      )
    end,
  },
  {
    label = "Clase Estática (Static Class / Extension)",
    desc = "public static class",
    ext = ".cs",
    generate = function(ns, name)
      return string.format(
        [[namespace %s;

public static class %s
{

}
]],
        ns,
        name
      )
    end,
  },
  {
    label = "Controlador API (ASP.NET Core ApiController)",
    desc = "ApiController con ControllerBase",
    ext = ".cs",
    generate = function(ns, name)
      if not name:match("Controller$") then
        name = name .. "Controller"
      end
      return string.format(
        [[using Microsoft.AspNetCore.Mvc;

namespace %s;

[ApiController]
[Route("api/[controller]")]
public class %s : ControllerBase
{
    [HttpGet]
    public IActionResult Get()
    {
        return Ok();
    }
}
]],
        ns,
        name
      )
    end,
  },
}

-- Función para agregar un nuevo elemento / clase al proyecto
function M.create_new_item()
  local current_dir = vim.fn.expand("%:p:h")
  if current_dir == "" or not vim.fn.isdirectory(current_dir) then
    current_dir = vim.fn.getcwd()
  end

  local items = {}
  for _, tmpl in ipairs(ITEM_TEMPLATES) do
    table.insert(items, string.format("%-25s │ %s", tmpl.label, tmpl.desc))
  end

  vim.ui.select(items, { prompt = "Selecciona el tipo de elemento a crear:" }, function(choice, idx)
    if not choice or not idx then
      return
    end

    local selected_tmpl = ITEM_TEMPLATES[idx]

    vim.ui.input({ prompt = "Nombre del archivo / tipo (ej: script, PlayerController): " }, function(name)
      if not name or name:match("^%s*$") then
        vim.notify("Creación cancelada.", vim.log.levels.WARN)
        return
      end

      name = vim.trim(name)
      name = name:gsub("%.cs$", "")

      local target_file = current_dir .. "/" .. name .. selected_tmpl.ext

      if vim.fn.filereadable(target_file) == 1 then
        vim.notify("El archivo ya existe: " .. target_file, vim.log.levels.ERROR)
        return
      end

      local ns = M.infer_namespace(current_dir)
      local content = selected_tmpl.generate(ns, name)

      local f = io.open(target_file, "w")
      if not f then
        vim.notify("No se pudo crear el archivo: " .. target_file, vim.log.levels.ERROR)
        return
      end
      f:write(content)
      f:close()

      vim.cmd("edit " .. vim.fn.fnameescape(target_file))

      vim.notify("✓ " .. selected_tmpl.label .. " creada: " .. name .. selected_tmpl.ext, vim.log.levels.INFO)
    end)
  end)
end

-- Función para parsear la lista de plantillas de `dotnet new list`
function M.get_dotnet_templates(callback)
  vim.system({ "dotnet", "new", "list" }, {}, function(obj)
    vim.schedule(function()
      if obj.code ~= 0 or not obj.stdout then
        vim.notify("Error al obtener plantillas de dotnet: " .. (obj.stderr or ""), vim.log.levels.ERROR)
        callback({})
        return
      end

      local lines = vim.split(obj.stdout, "\n", { plain = true })
      local templates = {}
      local start_parsing = false

      for _, line in ipairs(lines) do
        if line:match("^%-%-%-%-") then
          start_parsing = true
        elseif start_parsing and line:match("%S") then
          local parts = vim.split(line, "%s%s+", { trimempty = true })
          if #parts >= 2 then
            local desc = parts[1]
            local short_names = vim.split(parts[2], ",", { trimempty = true })
            local short_name = short_names[1]
            local tags = parts[4] or (parts[3] or "")
            table.insert(templates, {
              short_name = short_name,
              name = desc,
              display = string.format("%-22s │ %s", short_name, desc),
              tags = tags,
            })
          end
        end
      end

      callback(templates)
    end)
  end)
end

-- Función para crear proyecto y adjuntarlo a la solución activa si existe
function M.create_new_project()
  local notifier = Snacks and Snacks.notifier or nil

  M.get_dotnet_templates(function(templates)
    if #templates == 0 then
      vim.notify("No se encontraron plantillas instaladas en dotnet SDK.", vim.log.levels.WARN)
      return
    end

    local items = {}
    for _, t in ipairs(templates) do
      table.insert(items, t.display)
    end

    vim.ui.select(items, { prompt = "Selecciona la plantilla de .NET a crear:" }, function(choice, idx)
      if not choice or not idx then
        return
      end

      local selected_template = templates[idx]

      vim.ui.input({ prompt = "Nombre del proyecto (ej: MiApi, Core.Utils): " }, function(proj_name)
        if not proj_name or proj_name:match("^%s*$") then
          vim.notify("Creación de proyecto cancelada (nombre vacío).", vim.log.levels.WARN)
          return
        end

        proj_name = vim.trim(proj_name)

        if notifier then
          notifier.notify("Creando proyecto '" .. proj_name .. "' (" .. selected_template.short_name .. ")...", "info", {
            title = ".NET New",
            id = "dotnet_new",
          })
        else
          vim.notify("Creando proyecto '" .. proj_name .. "'...", vim.log.levels.INFO)
        end

        vim.system({ "dotnet", "new", selected_template.short_name, "-n", proj_name, "-o", proj_name }, {}, function(res_new)
          vim.schedule(function()
            if res_new.code ~= 0 then
              local err_msg = res_new.stderr ~= "" and res_new.stderr or res_new.stdout
              if notifier then
                notifier.notify("✗ Error creando proyecto:\n" .. err_msg, "error", { id = "dotnet_new" })
              else
                vim.notify("✗ Error creando proyecto:\n" .. err_msg, vim.log.levels.ERROR)
              end
              return
            end

            local sln_files = vim.fn.glob("**/*.sln*", false, true)
            local csproj_path = proj_name .. "/" .. proj_name .. ".csproj"

            if #sln_files > 0 then
              local function attach_to_sln(sln_path)
                vim.system({ "dotnet", "sln", sln_path, "add", csproj_path }, {}, function(res_sln)
                  vim.schedule(function()
                    if res_sln.code == 0 then
                      if notifier then
                        notifier.notify(
                          "✓ Proyecto '" .. proj_name .. "' creado y agregado a " .. sln_path,
                          "info",
                          { id = "dotnet_new" }
                        )
                      else
                        vim.notify("✓ Proyecto '" .. proj_name .. "' creado y agregado a " .. sln_path, vim.log.levels.INFO)
                      end
                    else
                      vim.notify("✓ Proyecto creado. Aviso al agregar a solución:\n" .. res_sln.stderr, vim.log.levels.WARN)
                    end
                  end)
                end)
              end

              if #sln_files == 1 then
                attach_to_sln(sln_files[1])
              else
                vim.ui.select(sln_files, { prompt = "Selecciona la solución (.sln/.slnx) a la que agregar el proyecto:" }, function(chosen_sln)
                  if chosen_sln then
                    attach_to_sln(chosen_sln)
                  else
                    vim.notify("✓ Proyecto '" .. proj_name .. "' creado (sin vincular a solución).", vim.log.levels.INFO)
                  end
                end)
              end
            else
              if notifier then
                notifier.notify("✓ Proyecto '" .. proj_name .. "' creado exitosamente", "info", { id = "dotnet_new" })
              else
                vim.notify("✓ Proyecto '" .. proj_name .. "' creado exitosamente", vim.log.levels.INFO)
              end
            end
          end)
        end)
      end)
    end)
  end)
end

return {
  {
    "seblyng/roslyn.nvim",
    keys = {
      { "<leader>dnx", M.run_current_file, desc = ".NET: Ejecutar archivo actual (dotnet run file.cs)" },
      { "<leader>dnf", M.create_new_item, desc = ".NET: Nuevo Archivo / Script (Template)" },
      { "<leader>dnp", M.create_new_project, desc = ".NET: Nuevo Proyecto (Plantillas)" },
      { "<leader>dns", "<cmd>Roslyn target<cr>", desc = ".NET: Seleccionar Solución (.sln)" },
      {
        "<leader>dnr",
        function()
          local notifier = Snacks and Snacks.notifier or nil
          if notifier then
            notifier.notify("Ejecutando dotnet restore...", "info", { title = ".NET Restore", id = "dotnet_restore" })
          else
            vim.notify("Ejecutando dotnet restore...", vim.log.levels.INFO)
          end

          vim.system({ "dotnet", "restore" }, {}, function(obj)
            vim.schedule(function()
              if obj.code == 0 then
                vim.diagnostic.reset(nil, 0)
                vim.cmd("edit!")

                if notifier then
                  notifier.notify("✓ Paquetes restaurados y buffer actualizado", "info", { id = "dotnet_restore" })
                else
                  vim.notify("✓ Paquetes restaurados y buffer actualizado", vim.log.levels.INFO)
                end
              else
                local err_msg = obj.stderr ~= "" and obj.stderr or obj.stdout
                if notifier then
                  notifier.notify("✗ Error en restore:\n" .. err_msg, "error", { id = "dotnet_restore" })
                else
                  vim.notify("✗ Error en restore:\n" .. err_msg, vim.log.levels.ERROR)
                end
              end
            end)
          end)
        end,
        desc = ".NET: Restaurar paquetes y refrescar buffer",
      },
      {
        "<leader>dnb",
        function()
          local notifier = Snacks and Snacks.notifier or nil
          if notifier then
            notifier.notify("Compilando solución / proyecto...", "info", { title = ".NET Build", id = "dotnet_build" })
          end
          vim.system({ "dotnet", "build" }, {}, function(obj)
            vim.schedule(function()
              if obj.code == 0 then
                vim.notify("✓ Compilación exitosa", vim.log.levels.INFO)
              else
                vim.notify("✗ Error en compilación:\n" .. (obj.stderr ~= "" and obj.stderr or obj.stdout), vim.log.levels.ERROR)
              end
            end)
          end)
        end,
        desc = ".NET: Build Solución",
      },
      {
        "<leader>dna",
        function()
          local files = vim.fn.glob("**/*.csproj", false, true)
          if #files == 0 then
            vim.notify("No se encontraron archivos .csproj", vim.log.levels.WARN)
            return
          end
          vim.ui.select(files, { prompt = "Selecciona el .csproj a agregar al .sln:" }, function(choice)
            if choice then
              vim.system({ "dotnet", "sln", "add", choice }, {}, function(obj)
                vim.schedule(function()
                  if obj.code == 0 then
                    vim.notify("✓ Proyecto agregado a la solución: " .. choice, vim.log.levels.INFO)
                  else
                    vim.notify("✗ Error: " .. obj.stderr, vim.log.levels.ERROR)
                  end
                end)
              end)
            end
          end)
        end,
        desc = ".NET: Agregar .csproj a .sln",
      },
      {
        "<leader>dnl",
        function()
          vim.system({ "dotnet", "sln", "list" }, {}, function(obj)
            vim.schedule(function()
              if obj.code == 0 then
                vim.notify(obj.stdout, vim.log.levels.INFO, { title = "Proyectos en la Solución" })
              else
                vim.notify("✗ Error al listar proyectos: " .. obj.stderr, vim.log.levels.ERROR)
              end
            end)
          end)
        end,
        desc = ".NET: Listar proyectos en .sln",
      },
    },
  },
}

-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

vim.api.nvim_create_user_command("Reformat", function(args)
  local range = nil
  if args.count ~= -1 then
    local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
    range = {
      start = { args.line1, 0 },
      ["end"] = { args.line2, end_line:len() },
    }
  end
  require("conform").format({ async = true, lsp_fallback = true, range = range })
end, { range = true })

-- ====================================================================
-- Defaults por lenguaje
-- ====================================================================
local function set_indent(tabstop, expandtab)
  vim.opt_local.tabstop = tabstop
  vim.opt_local.shiftwidth = tabstop
  vim.opt_local.softtabstop = tabstop
  vim.opt_local.expandtab = expandtab
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "cs", "python", "c", "cpp", "rust", "java", "xml" },
  callback = function()
    set_indent(4, true)
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = {
    "javascript",
    "typescript",
    "javascriptreact",
    "typescriptreact",
    "lua",
    "json",
    "jsonc",
    "html",
    "css",
    "scss",
    "yaml",
    "toml",
  },
  callback = function()
    set_indent(2, true)
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "go" },
  callback = function()
    set_indent(4, false)
  end,
})

-- ====================================================================
-- Generador de .editorconfig según el buffer y proyecto actual
-- ====================================================================
local function find_root()
  local lsp_clients = vim.lsp.get_clients({ bufnr = 0 })
  for _, client in ipairs(lsp_clients) do
    if client.config.root_dir then
      return client.config.root_dir
    end
  end
  local git_dir = vim.fs.root(0, { ".git", ".sln", "package.json", "Cargo.toml", "pyproject.toml" })
  return git_dir or vim.fn.getcwd()
end

local function get_file_extension(filename)
  local ext = vim.fn.fnamemodify(filename, ":e")
  return (ext ~= "" and ext) or vim.bo.filetype
end

vim.api.nvim_create_user_command("EditorConfigGenerate", function()
  local root = find_root()
  local editorconfig_path = root .. "/.editorconfig"
  local ext = get_file_extension(vim.api.nvim_buf_get_name(0))

  local style = vim.bo.expandtab and "space" or "tab"
  local size = vim.bo.shiftwidth > 0 and vim.bo.shiftwidth or vim.bo.tabstop

  local pattern_header = ("[*%s]"):format(ext ~= "" and ("." .. ext) or "")

  -- Si el archivo no existe, lo creamos con la estructura inicial
  if vim.fn.filereadable(editorconfig_path) == 0 then
    local content = {
      "root = true",
      "",
      "[*]",
      "charset = utf-8",
      "end_of_line = lf",
      "insert_final_newline = true",
      "trim_trailing_whitespace = true",
      "",
      pattern_header,
      ("indent_style = %s"):format(style),
      ("indent_size = %d"):format(size),
      "",
    }
    vim.fn.writefile(content, editorconfig_path)
    vim.notify("Creado .editorconfig en: " .. editorconfig_path, vim.log.levels.INFO)
    return
  end

  -- Si ya existe, actualizamos o agregamos la sección de la extensión
  local lines = vim.fn.readfile(editorconfig_path)
  local found = false
  local i = 1
  while i <= #lines do
    if lines[i] == pattern_header then
      found = true
      lines[i + 1] = ("indent_style = %s"):format(style)
      lines[i + 2] = ("indent_size = %d"):format(size)
      break
    end
    i = i + 1
  end

  if not found then
    table.insert(lines, "")
    table.insert(lines, pattern_header)
    table.insert(lines, ("indent_style = %s"):format(style))
    table.insert(lines, ("indent_size = %d"):format(size))
  end

  vim.fn.writefile(lines, editorconfig_path)
  vim.notify("Actualizado .editorconfig [" .. pattern_header .. "] en: " .. editorconfig_path, vim.log.levels.INFO)
end, { desc = "Genera o actualiza .editorconfig según el buffer actual" })

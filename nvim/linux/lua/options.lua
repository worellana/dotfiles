require("nvchad.options")

-- Mason: en Windows se usa una ruta sin espacios (los wrappers de Python de
-- Mason fallan con "Williams Orellana"); en Linux se usa la ruta estándar.
if vim.fn.has("win32") == 1 then
  vim.env.MASON = "C:/tools/nvim-mason"
end

local o = vim.o

-- ====================================================================
-- Opciones portadas de la configuración LazyVim
-- ====================================================================

-- Forzar idioma inglés para todos los LSPs, compiladores y herramientas CLI
vim.env.LANG = "en_US.UTF-8"
vim.env.LC_ALL = "en_US.UTF-8"
vim.env.LC_MESSAGES = "en_US.UTF-8"
vim.env.DOTNET_CLI_UI_LANGUAGE = "en-US"
vim.env.VSLANG = "1033"

-- Compatibilidad LazyVim
o.relativenumber = true
o.confirm = true
o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

-- Usar PowerShell de manera robusta y compatible en Windows
if vim.fn.has("win32") == 1 then
  -- nvim-treesitter (rama `main`) compila cada parser con un compilador de C.
  -- WinLibs (winget: BrechtSanders.WinLibs.POSIX.UCRT) no agrega su bin al
  -- PATH; C:\tools\mingw64 es un junction a ese paquete.
  local mingw = "C:/tools/mingw64/bin"
  if vim.uv.fs_stat(mingw .. "/gcc.exe") then
    vim.env.PATH = mingw .. ";" .. vim.env.PATH
    vim.env.CC = vim.env.CC or "gcc"
  end

  local powershell_options = {
    shell = vim.fn.executable("pwsh") == 1 and "pwsh" or "powershell",
    shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;",
    shellredir = "-RedirectStandardOutput %s -NoNewWindow -Wait",
    shellpipe = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode",
    shellquote = "",
    shellxquote = "",
  }

  for option, value in pairs(powershell_options) do
    vim.opt[option] = value
  end
end

vim.g.autoformat = true

o.wrap = true
o.linebreak = true -- corta en espacios/palabras completas, no a media palabra
o.breakindent = true -- mantiene la indentación cuando una línea se envuelve

-- Configuración para Neovide (GUI)
vim.g.neovide_title_background_color =
  string.format("%x", vim.api.nvim_get_hl(0, { id = vim.api.nvim_get_hl_id_by_name("Normal") }).bg)
vim.g.neovide_title_text_color = "white"
vim.g.neovide_corner_preference = "round"
vim.g.neovide_hide_mouse_when_typing = true
vim.g.neovide_cursor_animate_in_insert_mode = true
vim.g.neovide_cursor_vfx_mode = { "railgun", "sonicboom", "pixiedust" }

o.guicursor = "n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250"

-- Mostrar columna de folds (iconos de colapsar)
o.foldcolumn = "1"
o.foldlevel = 99
o.foldlevelstart = 99
o.foldenable = true

-- Iconos de folds (se fusionan con los fillchars de NvChad)
local fillchars = vim.opt.fillchars:get()
fillchars.foldopen = "▾"
fillchars.foldclose = "▸"
fillchars.fold = " "
fillchars.foldsep = " "
fillchars.eob = " "
vim.opt.fillchars = fillchars

-- Configuración limpia de diagnósticos (estilo VS Code / Rider)
require("configs.diagnostics")()

-- Mostrar espacios, tabulaciones y saltos de línea
o.list = true
vim.opt.listchars = {
  space = "·",
  tab = "→ ",
  trail = "·",
  nbsp = "⍽",
}

vim.g.ai_cmp = false

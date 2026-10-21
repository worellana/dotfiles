-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Forzar idioma inglés para todos los LSPs, compiladores y herramientas CLI
vim.env.LANG = "en_US.UTF-8"
vim.env.LC_ALL = "en_US.UTF-8"
vim.env.LC_MESSAGES = "en_US.UTF-8"
vim.env.DOTNET_CLI_UI_LANGUAGE = "en-US"
vim.env.VSLANG = "1033"

-- Configuración para Neovide (GUI)
-- El texto plano debe llevar dos guiones al inicio para ser un comentario legítimo.

--if vim.g.neovide then
--  vim.o.guifont = "CommitMono Nerd Font Mono:h12"
--end

-- Usar PowerShell de manera robusta y compatible en Windows
if vim.fn.has("win32") == 1 then
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
vim.opt.wrap = true
vim.opt.linebreak = true -- corta en espacios/palabras completas, no a media palabra
vim.opt.breakindent = true -- mantiene la indentación cuando una línea se envuelve
--vim.opt.colorcolumn = "90"

vim.g.neovide_title_background_color =
  string.format("%x", vim.api.nvim_get_hl(0, { id = vim.api.nvim_get_hl_id_by_name("Normal") }).bg)

vim.g.neovide_title_text_color = "white"

vim.g.neovide_corner_preference = "round"
vim.g.neovide_hide_mouse_when_typing = true
--vim.g.neovide_cursor_animation_lenght = 0.25
--vim.g.neovide_cursor_trail_size = 0.8
vim.g.neovide_cursor_animate_in_insert_mode = true

vim.g.neovide_cursor_vfx_mode = { "railgun", "sonicboom", "pixiedust" }

vim.o.guicursor = "n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250"

-- Mostrar columna de folds (iconos de colapsar)
vim.opt.foldcolumn = "1" -- Muestra la columna de folds
vim.opt.foldlevel = 99 -- Empieza con todo expandido
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true

-- Iconos más bonitos para los folds
vim.opt.fillchars = {
  foldopen = "▾",
  foldclose = "▸",
  fold = " ",
  foldsep = " ",
  eob = " ",
}

-- Configuración limpia de diagnósticos (estilo VS Code / Rider)
vim.diagnostic.config({
  virtual_text = {
    spacing = 4,
    prefix = "●",
    -- Muestra en texto flotante solo Warnings y Errores (evita duplicados de Hints/Infos en la misma línea)
    severity = { min = vim.diagnostic.severity.WARN },
    format = function(diagnostic)
      -- Evita repetir el mensaje cuando se renderizan multilíneas
      return diagnostic.message:gsub("\n.*", "")
    end,
  },
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

-- Mostrar espacios, tabulaciones y saltos de línea como en la captura
vim.opt.list = true
vim.opt.listchars = {
  space = "·",
  tab = "→ ",
  trail = "·",
  nbsp = "⍽",
}

vim.g.ai_cmp = false

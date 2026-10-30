-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- Navegación entre paneles con <leader> + hjkl / flechas
map("n", "<leader>h", "<C-w>h", { desc = "Mover a panel izquierdo" })
map("n", "<leader>j", "<C-w>j", { desc = "Mover a panel inferior" })
map("n", "<leader>k", "<C-w>k", { desc = "Mover a panel superior" })
map("n", "<leader>l", "<C-w>l", { desc = "Mover a panel derecho" })

map("n", "<leader><Left>", "<C-w>h", { desc = "Mover a panel izquierdo" })
map("n", "<leader><Down>", "<C-w>j", { desc = "Mover a panel inferior" })
map("n", "<leader><Up>", "<C-w>k", { desc = "Mover a panel superior" })
map("n", "<leader><Right>", "<C-w>l", { desc = "Mover a panel derecho" })

-- Zoom de texto en Neovide
if vim.g.neovide then
  vim.g.neovide_scale_factor = 1.0
  local function change_scale_factor(delta)
    vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * delta
  end

  map("n", "<C-=>", function()
    change_scale_factor(1.25)
  end, { desc = "Agrandar texto (Neovide)" })
  map("n", "<C-->", function()
    change_scale_factor(1 / 1.25)
  end, { desc = "Achicar texto (Neovide)" })
  map("n", "<C-0>", function()
    vim.g.neovide_scale_factor = 1.0
  end, { desc = "Resetear tamaño de texto (Neovide)" })
end

-- Duplicar línea manteniendo la columna del cursor
map("n", "<leader>d", function()
  local col = vim.fn.col(".")
  vim.cmd("copy .")
  vim.fn.cursor(vim.fn.line("."), col)
end, { desc = "Duplicar línea (mantener columna)" })

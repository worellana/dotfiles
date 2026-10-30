return {
  -- Desactivar el plugin de comentarios por defecto de LazyVim si estuviera activo
  { "nvim-mini/mini.comment", enabled = false },

  -- Configurar Comment.nvim con soporte para ts_context_commentstring (JSX/TSX/Vue/etc.)
  {
    "numToStr/Comment.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "JoosepAlviste/nvim-ts-context-commentstring",
    },
    opts = function()
      local tscore = require("ts_context_commentstring.integrations.comment_nvim")
      return {
        pre_hook = tscore.create_pre_hook(),
      }
    end,
    config = function(_, opts)
      require("Comment").setup(opts)

      -- Reasignar atajos estándar de LazyVim / Neovim para el comportamiento deseado:
      local map = vim.keymap.set

      -- Modo normal: comenta la línea actual con comentario de línea (//)
      map("n", "<leader>/", function()
        require("Comment.api").toggle.linewise.current()
      end, { desc = "Comentar línea (//)" })

      -- Modo visual: comenta la selección con comentario de bloque (/* */)
      map("x", "<leader>/", function()
        local esc = vim.api.nvim_replace_termcodes("<ESC>", true, false, true)
        vim.api.nvim_feedkeys(esc, "nx", false)
        require("Comment.api").toggle.blockwise(vim.fn.visualmode())
      end, { desc = "Comentar selección en bloque (/* */)" })

      -- Si usas 'gc' en modo visual, forzar que use bloque en lugar de líneas individuales
      map("x", "gc", function()
        local esc = vim.api.nvim_replace_termcodes("<ESC>", true, false, true)
        vim.api.nvim_feedkeys(esc, "nx", false)
        require("Comment.api").toggle.blockwise(vim.fn.visualmode())
      end, { desc = "Comentar selección en bloque (/* */)" })
    end,
  },
}

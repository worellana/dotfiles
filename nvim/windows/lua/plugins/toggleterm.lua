return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    keys = {
      -- Terminal flotante
      {
        "<leader>tf",
        function()
          require("toggleterm").toggle(1, nil, nil, "float")
        end,
        mode = { "n", "t" },
        desc = "Terminal flotante",
      },
      -- Terminal horizontal
      {
        "<leader>th",
        function()
          require("toggleterm").toggle(2, 15, nil, "horizontal")
        end,
        mode = { "n", "t" },
        desc = "Terminal horizontal",
      },
      -- Terminal vertical
      {
        "<leader>tv",
        function()
          require("toggleterm").toggle(3, 70, nil, "vertical")
        end,
        mode = { "n", "t" },
        desc = "Terminal vertical",
      },
      -- LazyGit
      {
        "<leader>gg",
        function()
          local Terminal = require("toggleterm.terminal").Terminal
          local lazygit = Terminal:new({
            cmd = "lazygit",
            dir = "git_dir",
            direction = "float",
            float_opts = {
              border = "curved",
              width = function()
                return math.floor(vim.o.columns * 0.9)
              end,
              height = function()
                return math.floor(vim.o.lines * 0.9)
              end,
            },
            on_open = function(term)
              vim.cmd("startinsert!")
              vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
            end,
            on_close = function()
              vim.cmd("startinsert!")
            end,
          })
          lazygit:toggle()
        end,
        desc = "LazyGit",
      },
    },
    opts = {
      -- Usar el shell global configurado en options.lua
      shell = "pwsh -NoLogo", --vim.o.shell,

      start_in_insert = true,
      insert_mappings = true,
      terminal_mappings = true,
      persist_mode = true,
      close_on_exit = true,

      float_opts = {
        border = "curved",
      },
    },
    config = function(_, opts)
      require("toggleterm").setup(opts)

      -- Entrar automáticamente en modo insert al abrir cualquier terminal
      vim.api.nvim_create_autocmd("TermOpen", {
        pattern = "*",
        callback = function()
          vim.cmd("startinsert")
        end,
      })
    end,
  },
}

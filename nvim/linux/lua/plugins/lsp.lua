-- LSP + Mason (equivalente a los extras de LazyVim)
return {
  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
    build = ":MasonUpdate",
    opts = {
      registries = {
        "github:mason-org/mason-registry",
        "github:Crashdummyy/mason-registry",
      },
      -- Fix para Windows: rutas de usuario con espacios rompen los wrappers de Python.
      -- En Linux se usa la ruta estándar de Mason.
      install_root_dir = vim.fn.has("win32") == 1 and "C:/tools/nvim-mason" or nil,
      -- NvChad usa PATH = "skip"; sin esto los binarios de Mason (lua_ls, stylua, etc.)
      -- no están en el PATH de Neovim.
      PATH = "prepend",
      ensure_installed = {
        "stylua",
        "shfmt",
        "shellcheck",
        "csharpier",
        "cmakelang",
        "cmakelint",
        "ktlint",
        "markdownlint-cli2",
        "markdown-toc",
        "sqlfluff",
        "powershell-editor-services",
        "codelldb",
        "netcoredbg",
        "roslyn",
        "js-debug-adapter",
      },
    },
    config = function(_, opts)
      require("mason").setup(opts)
      local mr = require("mason-registry")
      mr:on("package:install:success", function()
        vim.defer_fn(function()
          require("lazy.core.handler.event").trigger({
            event = "FileType",
            buf = vim.api.nvim_get_current_buf(),
          })
        end, 100)
      end)
      mr.refresh(function()
        for _, tool in ipairs(opts.ensure_installed or {}) do
          local p = mr.has_package(tool) and mr.get_package(tool)
          if p and not p:is_installed() and not p:is_installing() then
            p:install()
          end
        end
      end)
    end,
  },

  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason.nvim" },
  },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile", "User FilePost" },
    dependencies = {
      "mason.nvim",
      "mason-lspconfig.nvim",
      "b0o/SchemaStore.nvim",
    },
    config = function()
      local servers = {
        "clangd",
        "neocmake",
        "jsonls",
        "taplo",
        "marksman",
        "pyright",
        "ruff",
        "vtsls",
        "vue_ls",
        "astro",
        "tailwindcss",
        "kotlin_language_server",
        "bashls",
        "lua_ls",
      }

      require("mason-lspconfig").setup({
        ensure_installed = servers,
        automatic_enable = {
          exclude = {
            "omnisharp",
            "rust_analyzer",
            "ruff_lsp",
            "basedpyright",
            "tsserver",
            "ts_ls",
            "stylua",
          },
        },
      })

      require("configs.lspconfig").setup()
    end,
  },
}

-- Autocompletado: blink.cmp + LuaSnip (equivalente a LazyVim con blink)
return {
  {
    "hrsh7th/nvim-cmp",
    enabled = false,
  },

  {
    "saghen/blink.cmp",
    -- v1 estable: la rama `main` ya es la V2 beta y requiere `saghen/blink.lib`
    -- (de ahí el error "no field package.preload['blink.lib']" en CmdlineEnter).
    version = "*",
    event = { "InsertEnter", "CmdLineEnter" },
    dependencies = {
      "rafamadriz/friendly-snippets",
      {
        "L3MON4D3/LuaSnip",
        opts = { history = true, updateevents = "TextChanged,TextChangedI" },
        config = function(_, opts)
          require("luasnip").config.set_config(opts)
          require("nvchad.configs.luasnip")
        end,
      },
      {
        "saghen/blink.compat",
        optional = true,
        opts = {},
      },
    },

    opts = function()
      pcall(dofile, vim.g.base46_cache .. "blink")
      return {
        snippets = { preset = "luasnip" },
        appearance = {
          use_nvim_cmp_as_default = false,
          nerd_font_variant = "mono",
        },
        fuzzy = { implementation = "prefer_rust" },

        completion = {
          accept = { auto_brackets = { enabled = true } },
          menu = {
            -- menú de NvChad (bordes/colores del tema)
            draw = { treesitter = { "lsp" }, padding = { 1, 1 } },
            border = "single",
            scrollbar = false,
          },
          documentation = {
            auto_show = true,
            auto_show_delay_ms = 200,
            window = { border = "single" },
          },
          ghost_text = { enabled = vim.g.ai_cmp },
        },

        sources = {
          default = { "lsp", "path", "snippets", "buffer" },
          per_filetype = {
            lua = { inherit_defaults = true, "lazydev" },
            sql = { "dadbod" },
          },
          providers = {
            lazydev = {
              name = "LazyDev",
              module = "lazydev.integrations.blink",
              score_offset = 100,
            },
            dadbod = {
              name = "Dadbod",
              module = "vim_dadbod_completion.blink",
            },
          },
        },

        keymap = {
          preset = "enter",
          ["<C-y>"] = { "select_and_accept" },
          ["<Tab>"] = { "snippet_forward", "fallback" },
          ["<S-Tab>"] = { "snippet_backward", "fallback" },
          ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
          ["<C-e>"] = { "hide" },
        },

        cmdline = {
          enabled = true,
          keymap = {
            preset = "cmdline",
            ["<Right>"] = false,
            ["<Left>"] = false,
          },
          completion = {
            list = { selection = { preselect = false } },
            menu = {
              auto_show = function(ctx)
                return vim.fn.getcmdtype() == ":"
              end,
            },
            ghost_text = { enabled = true },
          },
        },
      }
    end,
  },
}

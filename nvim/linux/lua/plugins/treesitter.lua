-- Treesitter (rama main, como LazyVim) + textobjects + autotag
local parsers = {
  "bash",
  "c",
  "cpp",
  "c_sharp",
  "cmake",
  "css",
  "diff",
  "gdscript",
  "html",
  "javascript",
  "jsdoc",
  "json",
  "json5",
  "kotlin",
  "lua",
  "luadoc",
  "luap",
  "markdown",
  "markdown_inline",
  "ninja",
  "printf",
  "python",
  "query",
  "regex",
  "ron",
  "rst",
  "rust",
  "sql",
  "toml",
  "tsx",
  "typescript",
  "vim",
  "vimdoc",
  "vue",
  "xml",
  "yaml",
  "powershell",
  "git_config",
  "astro",
  "fish",
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    version = false,
    build = function()
      local ok, TS = pcall(require, "nvim-treesitter")
      if ok and TS.update then
        TS.update(nil, { summary = true })
      end
    end,
    event = { "BufReadPost", "BufNewFile", "VeryLazy" },
    cmd = { "TSUpdate", "TSInstall", "TSLog", "TSUninstall" },
    opts = { ensure_installed = parsers },
    config = function(_, opts)
      local ok, TS = pcall(require, "nvim-treesitter")
      if not ok or not TS.get_installed then
        return
      end

      local installed = {}
      for _, lang in ipairs(TS.get_installed()) do
        installed[lang] = true
      end
      local missing = vim.tbl_filter(function(lang)
        return not installed[lang]
      end, opts.ensure_installed or {})
      if #missing > 0 then
        TS.install(missing, { summary = true })
      end

      -- highlight + indent por treesitter
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("UserTreesitter", { clear = true }),
        callback = function(ev)
          local lang = vim.treesitter.language.get_lang(ev.match) or ev.match
          if not pcall(vim.treesitter.language.add, lang) then
            return
          end
          pcall(vim.treesitter.start, ev.buf)
          if vim.bo[ev.buf].indentexpr == "" then
            vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = "VeryLazy",
    opts = {
      move = {
        enable = true,
        set_jumps = true,
        keys = {
          goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer", ["]a"] = "@parameter.inner" },
          goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer", ["]A"] = "@parameter.inner" },
          goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer", ["[a"] = "@parameter.inner" },
          goto_previous_end = { ["[F"] = "@function.outer", ["[C"] = "@class.outer", ["[A"] = "@parameter.inner" },
        },
      },
    },
    config = function(_, opts)
      require("nvim-treesitter-textobjects").setup(opts)

      local function attach(buf)
        local ft = vim.bo[buf].filetype
        if not vim.tbl_get(opts, "move", "enable") then
          return
        end
        local moves = vim.tbl_get(opts, "move", "keys") or {}

        for method, keymaps in pairs(moves) do
          for key, query in pairs(keymaps) do
            local queries = type(query) == "table" and query or { query }
            local parts = {}
            for _, q in ipairs(queries) do
              local part = q:gsub("@", ""):gsub("%..*", "")
              part = part:sub(1, 1):upper() .. part:sub(2)
              table.insert(parts, part)
            end
            local desc = table.concat(parts, " or ")
            desc = (key:sub(1, 1) == "[" and "Prev " or "Next ") .. desc
            vim.keymap.set({ "n", "x", "o" }, key, function()
              if vim.wo.diff and key:find("[cC]") then
                return vim.cmd("normal! " .. key)
              end
              require("nvim-treesitter-textobjects.move")[method](query, "textobjects")
            end, { buffer = buf, desc = desc, silent = true })
          end
        end
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("UserTreesitterTextobjects", { clear = true }),
        callback = function(ev)
          attach(ev.buf)
        end,
      })
      vim.tbl_map(attach, vim.api.nvim_list_bufs())
    end,
  },

  {
    "windwp/nvim-ts-autotag",
    event = { "BufReadPost", "BufNewFile" },
    opts = {},
  },
}

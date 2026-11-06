-- Configuración LSP: reemplaza lo que LazyVim hacía con `opts.servers`.
local M = {}

local mason_root = vim.env.MASON or (vim.fn.stdpath("data") .. "/mason")

local function pkg_path(pkg, sub)
  local path = mason_root .. "/packages/" .. pkg .. (sub or "")
  return vim.uv.fs_stat(path) and path or nil
end

function M.setup()
  -- capabilities, on_init y lua_ls de NvChad
  require("nvchad.configs.lspconfig").defaults()

  -- Recuperar tus diagnósticos (NvChad los redefine en defaults())
  require("configs.diagnostics")()

  local capabilities = require("nvchad.configs.lspconfig").capabilities

  vim.lsp.config("*", { capabilities = capabilities })

  -- ---------------------------------------------------------------
  -- Keymaps LSP (equivalente a LazyVim)
  -- ---------------------------------------------------------------
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local buf = args.buf
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if not client then
        return
      end

      -- Se difiere para aplicarse después de los keymaps de NvChad
      -- (nvchad.configs.lspconfig.on_attach) y así conservar los de LazyVim.
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(buf) then
          return
        end

        -- NvChad mapea <leader>D (type definition); LazyVim lo usa para DBUI
        pcall(vim.keymap.del, "n", "<leader>D", { buffer = buf })

      local function bmap(mode, lhs, rhs, desc, method)
        if method and not client:supports_method(method) then
          return
        end
        vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc, silent = true })
      end

      local pick = Snacks.picker

      bmap("n", "gd", function()
        pick.lsp_definitions()
      end, "Goto Definition", "textDocument/definition")
      bmap("n", "gr", function()
        pick.lsp_references()
      end, "References", "textDocument/references")
      bmap("n", "gI", function()
        pick.lsp_implementations()
      end, "Goto Implementation", "textDocument/implementation")
      bmap("n", "gy", function()
        pick.lsp_type_definitions()
      end, "Goto T[y]pe Definition", "textDocument/typeDefinition")
      bmap("n", "gD", vim.lsp.buf.declaration, "Goto Declaration", "textDocument/declaration")
      bmap("n", "K", vim.lsp.buf.hover, "Hover", "textDocument/hover")
      bmap("n", "gK", vim.lsp.buf.signature_help, "Signature Help", "textDocument/signatureHelp")
      bmap("i", "<c-k>", vim.lsp.buf.signature_help, "Signature Help", "textDocument/signatureHelp")
      bmap({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, "Code Action", "textDocument/codeAction")
      bmap("n", "<leader>cc", vim.lsp.codelens.run, "Run Codelens", "textDocument/codeLens")
      bmap("n", "<leader>cC", vim.lsp.codelens.refresh, "Refresh & Display Codelens", "textDocument/codeLens")
      bmap("n", "<leader>cr", vim.lsp.buf.rename, "Rename", "textDocument/rename")
      bmap("n", "<leader>cl", function()
        pick.lsp_config()
      end, "Lsp Info")
      bmap("n", "<leader>ss", function()
        pick.lsp_symbols()
      end, "LSP Symbols", "textDocument/documentSymbol")
      bmap("n", "<leader>sS", function()
        pick.lsp_workspace_symbols()
      end, "LSP Workspace Symbols", "workspace/symbol")
      bmap("n", "gai", function()
        pick.lsp_incoming_calls()
      end, "C[a]lls Incoming", "callHierarchy/incomingCalls")
      bmap("n", "gao", function()
        pick.lsp_outgoing_calls()
      end, "C[a]lls Outgoing", "callHierarchy/outgoingCalls")
      bmap("n", "<leader>co", function()
        vim.lsp.buf.code_action({
          apply = true,
          context = { only = { "source.organizeImports" }, diagnostics = {} },
        })
      end, "Organize Imports", "textDocument/codeAction")

      -- inlay hints automáticos (LazyVim: enabled = true, exclude vue)
      if
        client:supports_method("textDocument/inlayHint")
        and vim.bo[buf].buftype == ""
        and vim.bo[buf].filetype ~= "vue"
      then
        pcall(vim.lsp.inlay_hint.enable, true, { bufnr = buf })
      end
      end)
    end,
  })

  -- ---------------------------------------------------------------
  -- Servidores
  -- ---------------------------------------------------------------
  local servers = {}

  -- C / C++
  servers.clangd = {
    keys = {
      { "<leader>ch", "<cmd>LspClangdSwitchSourceHeader<cr>", desc = "Switch Source/Header (C/C++)" },
    },
    root_markers = {
      "compile_commands.json",
      "compile_flags.txt",
      "configure.ac",
      "Makefile",
      "configure.in",
      "config.h.in",
      "meson.build",
      "meson_options.txt",
      "build.ninja",
      ".git",
    },
    capabilities = { offsetEncoding = { "utf-16" } },
    cmd = {
      "clangd",
      "--background-index",
      "--clang-tidy",
      "--header-insertion=iwyu",
      "--completion-style=detailed",
      "--function-arg-placeholders",
      "--fallback-style=llvm",
    },
    init_options = {
      usePlaceholders = true,
      completeUnimported = true,
      clangdFileStatus = true,
    },
  }

  -- CMake
  servers.neocmake = {}

  -- JSON (SchemaStore)
  servers.jsonls = {
    before_init = function(_, new_config)
      new_config.settings = new_config.settings or {}
      new_config.settings.json = new_config.settings.json or {}
      new_config.settings.json.schemas = new_config.settings.json.schemas or {}
      vim.list_extend(new_config.settings.json.schemas, require("schemastore").json.schemas())
    end,
    settings = {
      json = {
        format = { enable = true },
        validate = { enable = true },
      },
    },
  }

  -- TOML
  servers.taplo = {}

  -- Markdown
  servers.marksman = {}

  -- Python (LazyVim: pyright + ruff)
  servers.pyright = {}
  servers.ruff = {
    cmd_env = { RUFF_TRACE = "messages" },
    init_options = {
      settings = { logLevel = "error" },
    },
  }
  servers.ruff_lsp = { enabled = false }
  servers.basedpyright = { enabled = false }

  -- TypeScript / JavaScript
  local vtsls_plugins = {}
  local astro_plugin = pkg_path("astro-language-server", "/node_modules/@astrojs/ts-plugin")
  if astro_plugin then
    table.insert(vtsls_plugins, {
      name = "@astrojs/ts-plugin",
      location = astro_plugin,
      enableForWorkspaceTypeScriptVersions = true,
    })
  end
  local vue_plugin = pkg_path("vue-language-server", "/node_modules/@vue/typescript-plugin")
  if vue_plugin then
    table.insert(vtsls_plugins, {
      name = "@vue/typescript-plugin",
      location = vue_plugin,
      languages = { "vue" },
      configNamespace = "typescript",
      enableForWorkspaceTypeScriptVersions = true,
    })
  end

  servers.vtsls = {
    filetypes = {
      "javascript",
      "javascriptreact",
      "javascript.jsx",
      "typescript",
      "typescriptreact",
      "typescript.tsx",
      "vue",
    },
    settings = {
      complete_function_calls = true,
      vtsls = {
        enableMoveToFileCodeAction = true,
        autoUseWorkspaceTsdk = true,
        experimental = {
          maxInlayHintLength = 30,
          completion = { enableServerSideFuzzyMatch = true },
        },
        tsserver = { globalPlugins = vtsls_plugins },
      },
      typescript = {
        updateImportsOnFileMove = { enabled = "always" },
        suggest = { completeFunctionCalls = true },
        inlayHints = {
          enumMemberValues = { enabled = true },
          functionLikeReturnTypes = { enabled = true },
          parameterNames = { enabled = "literals" },
          parameterTypes = { enabled = true },
          propertyDeclarationTypes = { enabled = true },
          variableTypes = { enabled = false },
        },
      },
    },
  }
  servers.tsserver = { enabled = false }
  servers.ts_ls = { enabled = false }

  servers.vue_ls = {}
  servers.astro = {}
  servers.tailwindcss = {
    filetypes_exclude = { "markdown" },
    settings = {
      tailwindCSS = {
        includeLanguages = {
          elixir = "html-eex",
          eelixir = "html-eex",
          heex = "html-eex",
        },
      },
    },
  }

  -- Kotlin
  servers.kotlin_language_server = {}

  -- stylua expone un LSP experimental; el formateo lo hace conform
  servers.stylua = { enabled = false }

  -- Shell / dotfiles
  servers.bashls = {}

  -- Godot (el servidor lo provee el editor de Godot en el puerto 6005)
  servers.gdscript = {}

  -- Rust: lo maneja rustaceanvim
  servers.rust_analyzer = { enabled = false }

  -- C#: Roslyn (plugin seblyng/roslyn.nvim); Omnisharp apagado
  servers.omnisharp = { enabled = false }
  servers.roslyn = {
    cmd_env = {
      DOTNET_SYSTEM_GLOBALIZATION_INVARIANT = "1",
    },
  }

  for name, conf in pairs(servers) do
    vim.lsp.config(name, conf)
  end

  -- Los servidores de Mason se habilitan con mason-lspconfig; estos no vienen
  -- del registro oficial, así que se habilitan explícitamente.
  vim.lsp.enable({ "roslyn", "gdscript" })

  M.capabilities = capabilities
end

return M

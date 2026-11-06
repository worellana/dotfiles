-- Núcleo DAP portado de LazyVim (adaptadores en dap-cpp / dap-csharp / dap-js / dap-python)
local function get_args(config)
  local args = type(config.args) == "function" and (config.args() or {}) or config.args or {}
  local args_str = type(args) == "table" and table.concat(args, " ") or args

  config = vim.deepcopy(config)
  config.args = function()
    local new_args = vim.fn.expand(vim.fn.input("Run with args: ", args_str))
    if config.type and config.type == "java" then
      return new_args
    end
    return require("dap.utils").splitstr(new_args)
  end
  return config
end

return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      {
        "theHamsta/nvim-dap-virtual-text",
        opts = {},
      },
    },
    keys = {
      {
        "<leader>dB",
        function()
          require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
        end,
        desc = "Breakpoint Condition",
      },
      {
        "<leader>db",
        function()
          require("dap").toggle_breakpoint()
        end,
        desc = "Toggle Breakpoint",
      },
      {
        "<leader>dc",
        function()
          require("dap").continue()
        end,
        desc = "Run/Continue",
      },
      {
        "<leader>da",
        function()
          require("dap").continue({ before = get_args })
        end,
        desc = "Run with Args",
      },
      {
        "<leader>dC",
        function()
          require("dap").run_to_cursor()
        end,
        desc = "Run to Cursor",
      },
      {
        "<leader>dg",
        function()
          require("dap").goto_()
        end,
        desc = "Go to Line (No Execute)",
      },
      {
        "<leader>di",
        function()
          require("dap").step_into()
        end,
        desc = "Step Into",
      },
      {
        "<leader>dj",
        function()
          require("dap").down()
        end,
        desc = "Down",
      },
      {
        "<leader>dk",
        function()
          require("dap").up()
        end,
        desc = "Up",
      },
      {
        "<leader>dl",
        function()
          require("dap").run_last()
        end,
        desc = "Run Last",
      },
      {
        "<leader>do",
        function()
          require("dap").step_out()
        end,
        desc = "Step Out",
      },
      {
        "<leader>dO",
        function()
          require("dap").step_over()
        end,
        desc = "Step Over",
      },
      {
        "<leader>dP",
        function()
          require("dap").pause()
        end,
        desc = "Pause",
      },
      {
        "<leader>dr",
        function()
          require("dap").repl.toggle()
        end,
        desc = "Toggle REPL",
      },
      {
        "<leader>ds",
        function()
          require("dap").session()
        end,
        desc = "Session",
      },
      {
        "<leader>dt",
        function()
          require("dap").terminate()
        end,
        desc = "Terminate",
      },
      {
        "<leader>dw",
        function()
          require("dap.ui.widgets").hover()
        end,
        desc = "Widgets",
      },
    },
    config = function()
      vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })

      local signs = {
        Breakpoint = { "", "DiagnosticInfo" },
        BreakpointCondition = { "", "DiagnosticInfo" },
        BreakpointRejected = { "", "DiagnosticError" },
        LogPoint = { "◆", "DiagnosticInfo" },
        Stopped = { "", "DiagnosticWarn", "DapStoppedLine" },
      }
      for name, sign in pairs(signs) do
        vim.fn.sign_define("Dap" .. name, { text = sign[1], texthl = sign[2] or "DiagnosticInfo", linehl = sign[3] })
      end

      local ok, mason_dap = pcall(require, "mason-nvim-dap")
      if ok then
        mason_dap.setup({
          automatic_installation = false,
          handlers = {
            codelldb = function() end,
            coreclr = function() end,
            python = function() end,
          },
        })
      end

      -- Configuración desde .vscode/launch.json
      local vscode = require("dap.ext.vscode")
      local json = require("plenary.json")
      vscode.json_decode = function(str)
        return vim.json.decode(json.json_strip_comments(str))
      end
    end,
  },

  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "nvim-neotest/nvim-nio" },
    keys = {
      { "<leader>du", function() require("dapui").toggle({}) end, desc = "Dap UI" },
      { "<leader>de", function() require("dapui").eval() end, desc = "Eval", mode = { "n", "x" } },
      {
        "<leader>dq",
        function()
          require("dap").terminate()
          require("dapui").close()
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_valid(buf) then
              local ft = vim.bo[buf].filetype
              local bt = vim.bo[buf].buftype
              local name = vim.api.nvim_buf_get_name(buf)
              if ft == "dap-terminal" or (bt == "terminal" and name:find("dap%-terminal")) then
                vim.api.nvim_buf_delete(buf, { force = true })
              end
            end
          end
        end,
        desc = "Terminar debug y cerrar UI",
      },
    },
    opts = {},
    config = function(_, opts)
      local dap = require("dap")
      local dapui = require("dapui")
      local focus = require("util.winfocus")
      dapui.setup(opts)

      -- Terminal integrada en buffer inferior para stdin/cin/scanf
      dap.defaults.fallback.terminal_win_cmd = "botright 12split new"

      local function is_dap_terminal(buf)
        local ft = vim.bo[buf].filetype
        local bt = vim.bo[buf].buftype
        local name = vim.api.nvim_buf_get_name(buf)
        return ft == "dap-terminal" or (bt == "terminal" and name:find("dap%-terminal") ~= nil)
      end

      local function close_debug_ui()
        if dap.session() then pcall(dap.close) end
        pcall(dapui.close)
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_valid(buf) and is_dap_terminal(buf) then
            pcall(vim.api.nvim_buf_delete, buf, { force = true })
          end
        end
      end

      local function is_godot(session)
        return session ~= nil and session.config ~= nil and session.config.type == "godot"
      end

      -- Nombre del proyecto Godot, para no enfocar la ventana equivocada si
      -- hay varios editores abiertos.
      local function godot_project_name(project)
        if type(project) ~= "string" or project == "" then return "" end
        local file = io.open(project:gsub("[/\\]+$", "") .. "/project.godot", "r")
        if not file then return "" end
        local content = file:read("*a")
        file:close()
        return content:match('config/name="([^"]*)"') or ""
      end

      -- Abrir UI al iniciar
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open({})
      end

      -- Godot lanza el juego en otra ventana; Windows no le da el foco porque
      -- el proceso lo crea el editor (que está en segundo plano). Lo pedimos
      -- explícitamente y guardamos la ventana actual para restaurarla después.
      dap.listeners.after.event_initialized["godot_focus"] = function(session)
        if not is_godot(session) then return end
        focus.focus_game(godot_project_name(session.config.project))
      end

      -- Godot manda `exited` (no `terminated`) al cerrar la ventana del juego;
      -- nvim-dap no cierra la sesión con ese evento, así que lo hacemos aquí:
      -- equivale a pulsar <leader>dq y además devuelve el foco a Neovim.
      local closed = {}
      local function on_godot_exit(session)
        if not is_godot(session) then return end
        local id = session.id or tostring(session)
        if closed[id] then return end
        closed[id] = true
        vim.schedule(function()
          close_debug_ui()
          vim.defer_fn(function() focus.restore() end, 200)
        end)
      end

      dap.listeners.after.event_exited["godot_auto_close"] = on_godot_exit
      dap.listeners.after.event_terminated["godot_auto_close"] = on_godot_exit

      -- Auto-focus terminal al salir proceso (solo depuradores con terminal,
      -- no Godot: en Godot devolvemos el foco a la ventana del editor).
      dap.listeners.after.event_terminated["dapui_config"] = function(session)
        if is_godot(session) then return end
        vim.schedule(function()
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            local buf = vim.api.nvim_win_get_buf(win)
            local ft = vim.bo[buf].filetype
            if ft == "dap-terminal" or vim.bo[buf].buftype == "terminal" then
              vim.api.nvim_set_current_win(win)
              vim.cmd("normal! G")
              break
            end
          end
        end)
      end
    end,
  },

  -- Configuración específica para Python
  {
    "mfussenegger/nvim-dap-python",
    ft = "python",
    config = function()
      -- ESTA línea es la que faltaba: sin ella, dap.configurations.python
      -- nunca se llena, sin importar cuántas veces la recorras después.
      -- Usamos un venv creado a mano (python -m venv) en vez del de Mason,
      -- porque el instalador de Mason tiene un bug conocido con debugpy en Windows.
      local python = "python3"
      if vim.fn.has("win32") == 1 then
        python = "C:/tools/nvim-mason/debugpy-venv/Scripts/pythonw.exe"
      end
      require("dap-python").setup(python)

      local dap = require("dap")
      -- Ahora sí, esto tiene algo que modificar:
      for _, config in pairs(dap.configurations.python or {}) do
        config.console = "internalConsole"
      end
    end,
  },
}

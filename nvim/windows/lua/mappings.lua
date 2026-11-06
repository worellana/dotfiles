require("nvchad.mappings")

local map = vim.keymap.set
local del = function(mode, lhs)
  pcall(vim.keymap.del, mode, lhs)
end

-- Quitar mappings de NvChad que chocan con los grupos de LazyVim
del("n", "<leader>x") -- NvChad: cerrar buffer  -> LazyVim: grupo diagnósticos/quickfix
del("n", "<leader>b") -- NvChad: buffer nuevo  -> LazyVim: grupo buffers
del("n", "<leader>n") -- NvChad: toggle números -> LazyVim: historial de notificaciones
del("n", "<leader>e") -- NvChad: nvim-tree      -> snacks explorer

-- ====================================================================
-- Helpers de búsqueda (raíz del proyecto, como LazyVim)
-- ====================================================================
local function root()
  return vim.fs.root(0, { ".git", ".hg", ".svn", ".jj", "package.json", "Cargo.toml", "pyproject.toml", "*.sln" })
    or vim.uv.cwd()
end

local function pick(source, opts)
  return function()
    Snacks.picker.pick(source, opts or {})
  end
end

local function pick_root(source)
  return function()
    Snacks.picker.pick(source, { cwd = root() })
  end
end

-- ====================================================================
-- Navegación entre paneles con <leader> + hjkl / flechas
-- ====================================================================
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

-- ====================================================================
-- Keymaps base de LazyVim (config/keymaps.lua)
-- ====================================================================
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })
map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

map("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window", remap = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window", remap = true })

map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

map("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
map("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
map("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })

-- buffers
map("n", "<S-h>", function()
  require("nvchad.tabufline").prev()
end, { desc = "Prev Buffer" })
map("n", "<S-l>", function()
  require("nvchad.tabufline").next()
end, { desc = "Next Buffer" })
map("n", "[b", function()
  require("nvchad.tabufline").prev()
end, { desc = "Prev Buffer" })
map("n", "]b", function()
  require("nvchad.tabufline").next()
end, { desc = "Next Buffer" })
map("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
map("n", "<leader>`", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
map("n", "<leader>bd", function()
  Snacks.bufdelete()
end, { desc = "Delete Buffer" })
map("n", "<leader>bo", function()
  Snacks.bufdelete.other()
end, { desc = "Delete Other Buffers" })
map("n", "<leader>bi", function()
  Snacks.bufdelete.invisible()
end, { desc = "Delete Invisible Buffers" })
map("n", "<leader>bD", "<cmd>:bd<cr>", { desc = "Delete Buffer and Window" })

map({ "i", "n", "s" }, "<esc>", function()
  vim.cmd("noh")
  return "<esc>"
end, { expr = true, desc = "Escape and Clear hlsearch" })

map("n", "<leader>ur", "<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! \12<CR>", { desc = "Redraw / Clear hlsearch / Diff Update" })

map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
map("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
map("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
map("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })

map("i", ",", ",<c-g>u")
map("i", ".", ".<c-g>u")
map("i", ";", ";<c-g>u")

map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })
map("n", "<leader>K", "<cmd>norm! K<cr>", { desc = "Keywordprg" })
map("x", "<", "<gv")
map("x", ">", ">gv")

-- `:Lazy` (LazyVim lo ponía en <leader>l, pero tú usas <leader>l para paneles)
map("n", "<leader>L", "<cmd>Lazy<cr>", { desc = "Lazy" })
map("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New File" })

map("n", "<leader>xl", function()
  local success, err = pcall(vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 and vim.cmd.lclose or vim.cmd.lopen)
  if not success and err then
    vim.notify(err, vim.log.levels.ERROR)
  end
end, { desc = "Location List" })

map("n", "<leader>xq", function()
  local success, err = pcall(vim.fn.getqflist({ winid = 0 }).winid ~= 0 and vim.cmd.cclose or vim.cmd.copen)
  if not success and err then
    vim.notify(err, vim.log.levels.ERROR)
  end
end, { desc = "Quickfix List" })

map({ "n", "x" }, "<leader>cf", function()
  require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "Format" })

local diagnostic_goto = function(next, severity)
  return function()
    vim.diagnostic.jump({
      count = (next and 1 or -1) * vim.v.count1,
      severity = severity and vim.diagnostic.severity[severity] or nil,
      float = true,
    })
  end
end
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
map("n", "]d", diagnostic_goto(true), { desc = "Next Diagnostic" })
map("n", "[d", diagnostic_goto(false), { desc = "Prev Diagnostic" })
map("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
map("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev Error" })
map("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next Warning" })
map("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Prev Warning" })

-- ====================================================================
-- Explorador (snacks) y pickers (snacks, raíz del proyecto como LazyVim)
-- ====================================================================
map("n", "<leader>e", function()
  Snacks.explorer()
end, { desc = "Explorer (snacks)" })
map("n", "<C-n>", function()
  Snacks.explorer()
end, { desc = "Explorer (snacks)" })

map("n", "<leader>,", function()
  Snacks.picker.buffers()
end, { desc = "Buffers" })
map("n", "<leader>:", function()
  Snacks.picker.command_history()
end, { desc = "Command History" })
map("n", "<leader><space>", pick_root("files"), { desc = "Find Files (Root Dir)" })
map("n", "<leader>n", function()
  Snacks.picker.notifications()
end, { desc = "Notification History" })

-- find
map("n", "<leader>fb", function()
  Snacks.picker.buffers()
end, { desc = "Buffers" })
map("n", "<leader>fB", function()
  Snacks.picker.buffers({ hidden = true, nofile = true })
end, { desc = "Buffers (all)" })
map("n", "<leader>fc", function()
  Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
end, { desc = "Find Config File" })
map("n", "<leader>ff", pick_root("files"), { desc = "Find Files (Root Dir)" })
map("n", "<leader>fF", pick("files"), { desc = "Find Files (cwd)" })
map("n", "<leader>fg", function()
  Snacks.picker.git_files()
end, { desc = "Find Files (git-files)" })
map("n", "<leader>fr", function()
  Snacks.picker.recent()
end, { desc = "Recent" })
map("n", "<leader>fR", function()
  Snacks.picker.recent({ filter = { cwd = true } })
end, { desc = "Recent (cwd)" })
map("n", "<leader>fp", function()
  Snacks.picker.projects()
end, { desc = "Projects" })

-- git
map("n", "<leader>gd", function()
  Snacks.picker.git_diff()
end, { desc = "Git Diff (hunks)" })
map("n", "<leader>gD", function()
  Snacks.picker.git_diff({ base = "origin", group = true })
end, { desc = "Git Diff (origin)" })
map("n", "<leader>gs", function()
  Snacks.picker.git_status()
end, { desc = "Git Status" })
map("n", "<leader>gS", function()
  Snacks.picker.git_stash()
end, { desc = "Git Stash" })
map("n", "<leader>gl", function()
  Snacks.picker.git_log({ cwd = root() })
end, { desc = "Git Log" })
map("n", "<leader>gL", function()
  Snacks.picker.git_log()
end, { desc = "Git Log (cwd)" })
map("n", "<leader>gb", function()
  Snacks.picker.git_log_line()
end, { desc = "Git Blame Line" })
map("n", "<leader>gf", function()
  Snacks.picker.git_log_file()
end, { desc = "Git Current File History" })
map({ "n", "x" }, "<leader>gB", function()
  Snacks.gitbrowse()
end, { desc = "Git Browse (open)" })
map({ "n", "x" }, "<leader>gY", function()
  Snacks.gitbrowse({
    open = function(url)
      vim.fn.setreg("+", url)
    end,
    notify = false,
  })
end, { desc = "Git Browse (copy)" })

-- grep / search
map("n", "<leader>sb", function()
  Snacks.picker.lines()
end, { desc = "Buffer Lines" })
map("n", "<leader>sB", function()
  Snacks.picker.grep_buffers()
end, { desc = "Grep Open Buffers" })
map("n", "<leader>sg", pick_root("grep"), { desc = "Grep (Root Dir)" })
map("n", "<leader>sG", pick("grep"), { desc = "Grep (cwd)" })
map("n", "<leader>sp", function()
  Snacks.picker.lazy()
end, { desc = "Search for Plugin Spec" })
map({ "n", "x" }, "<leader>sw", pick_root("grep_word"), { desc = "Visual selection or word (Root Dir)" })
map({ "n", "x" }, "<leader>sW", pick("grep_word"), { desc = "Visual selection or word (cwd)" })
map("n", '<leader>s"', function()
  Snacks.picker.registers()
end, { desc = "Registers" })
map("n", "<leader>s/", function()
  Snacks.picker.search_history()
end, { desc = "Search History" })
map("n", "<leader>sa", function()
  Snacks.picker.autocmds()
end, { desc = "Autocmds" })
map("n", "<leader>sc", function()
  Snacks.picker.command_history()
end, { desc = "Command History" })
map("n", "<leader>sC", function()
  Snacks.picker.commands()
end, { desc = "Commands" })
map("n", "<leader>sd", function()
  Snacks.picker.diagnostics()
end, { desc = "Diagnostics" })
map("n", "<leader>sD", function()
  Snacks.picker.diagnostics_buffer()
end, { desc = "Buffer Diagnostics" })
map("n", "<leader>sh", function()
  Snacks.picker.help()
end, { desc = "Help Pages" })
map("n", "<leader>sH", function()
  Snacks.picker.highlights()
end, { desc = "Highlights" })
map("n", "<leader>si", function()
  Snacks.picker.icons()
end, { desc = "Icons" })
map("n", "<leader>sj", function()
  Snacks.picker.jumps()
end, { desc = "Jumps" })
map("n", "<leader>sk", function()
  Snacks.picker.keymaps()
end, { desc = "Keymaps" })
map("n", "<leader>sl", function()
  Snacks.picker.loclist()
end, { desc = "Location List" })
map("n", "<leader>sM", function()
  Snacks.picker.man()
end, { desc = "Man Pages" })
map("n", "<leader>sm", function()
  Snacks.picker.marks()
end, { desc = "Marks" })
map("n", "<leader>sR", function()
  Snacks.picker.resume()
end, { desc = "Resume" })
map("n", "<leader>sq", function()
  Snacks.picker.qflist()
end, { desc = "Quickfix List" })
map("n", "<leader>su", function()
  Snacks.picker.undo()
end, { desc = "Undotree" })

-- ====================================================================
-- Toggles de UI (LazyVim)
-- ====================================================================
local function toggle_map(toggle, lhs)
  pcall(function()
    toggle:map(lhs)
  end)
end

pcall(function()
  local toggle = Snacks.toggle

  toggle({
    name = "Auto Format",
    get = function()
      return vim.g.autoformat
    end,
    set = function(state)
      vim.g.autoformat = state
    end,
  }):map("<leader>uf")

  toggle.option("spell", { name = "Spelling" }):map("<leader>us")
  toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
  toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
  toggle.diagnostics():map("<leader>ud")
  toggle.line_number():map("<leader>ul")
  toggle
    .option("conceallevel", {
      off = 0,
      on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2,
      name = "Conceal Level",
    })
    :map("<leader>uc")
  toggle
    .option("showtabline", {
      off = 0,
      on = vim.o.showtabline > 0 and vim.o.showtabline or 2,
      name = "Tabline",
    })
    :map("<leader>uA")
  toggle.treesitter():map("<leader>uT")
  toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")
  toggle.dim():map("<leader>uD")
  toggle.animate():map("<leader>ua")
  toggle.indent():map("<leader>ug")
  toggle.scroll():map("<leader>uS")
  toggle.profiler():map("<leader>dpp")
  toggle.profiler_highlights():map("<leader>dph")

  if vim.lsp.inlay_hint then
    toggle.inlay_hints():map("<leader>uh")
  end
end)

-- ====================================================================
-- Diagnósticos / Quickfix (trouble)
-- ====================================================================
map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics (Trouble)" })
map("n", "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Buffer Diagnostics (Trouble)" })
map("n", "<leader>cs", "<cmd>Trouble symbols toggle<cr>", { desc = "Symbols (Trouble)" })
map("n", "<leader>cS", "<cmd>Trouble lsp toggle<cr>", { desc = "LSP references/definitions/... (Trouble)" })
map("n", "<leader>xL", "<cmd>Trouble loclist toggle<cr>", { desc = "Location List (Trouble)" })
map("n", "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix List (Trouble)" })
map("n", "[q", function()
  if require("trouble").is_open() then
    require("trouble").prev({ skip_groups = true, jump = true })
  else
    local ok, err = pcall(vim.cmd.cprev)
    if not ok then
      vim.notify(err, vim.log.levels.ERROR)
    end
  end
end, { desc = "Previous Trouble/Quickfix Item" })
map("n", "]q", function()
  if require("trouble").is_open() then
    require("trouble").next({ skip_groups = true, jump = true })
  else
    local ok, err = pcall(vim.cmd.cnext)
    if not ok then
      vim.notify(err, vim.log.levels.ERROR)
    end
  end
end, { desc = "Next Trouble/Quickfix Item" })

-- ====================================================================
-- Sesiones, terminal, ventanas y tabs
-- ====================================================================
map("n", "<leader>qs", function()
  require("persistence").load()
end, { desc = "Restore Session" })
map("n", "<leader>qS", function()
  require("persistence").select()
end, { desc = "Select Session" })
map("n", "<leader>ql", function()
  require("persistence").load({ last = true })
end, { desc = "Restore Last Session" })
map("n", "<leader>qd", function()
  require("persistence").stop()
end, { desc = "Don't Save Current Session" })
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit All" })

map("n", "<leader>ui", vim.show_pos, { desc = "Inspect Pos" })
map("n", "<leader>uI", function()
  vim.treesitter.inspect_tree()
  vim.api.nvim_input("I")
end, { desc = "Inspect Tree" })

map("n", "<leader>fT", function()
  Snacks.terminal()
end, { desc = "Terminal (cwd)" })
map("n", "<leader>ft", function()
  Snacks.terminal(nil, { cwd = root() })
end, { desc = "Terminal (Root Dir)" })
map({ "n", "t" }, "<c-/>", function()
  Snacks.terminal.focus(nil, { cwd = root() })
end, { desc = "Terminal (Root Dir)" })
map({ "n", "t" }, "<c-_>", function()
  Snacks.terminal.focus(nil, { cwd = root() })
end, { desc = "which_key_ignore" })

map("n", "<leader>-", "<C-W>s", { desc = "Split Window Below", remap = true })
map("n", "<leader>|", "<C-W>v", { desc = "Split Window Right", remap = true })
map("n", "<leader>wd", "<C-W>c", { desc = "Delete Window", remap = true })
pcall(function()
  Snacks.toggle.zoom():map("<leader>wm"):map("<leader>uZ")
  Snacks.toggle.zen():map("<leader>uz")
end)

map("n", "<leader><tab>l", "<cmd>tablast<cr>", { desc = "Last Tab" })
map("n", "<leader><tab>o", "<cmd>tabonly<cr>", { desc = "Close Other Tabs" })
map("n", "<leader><tab>f", "<cmd>tabfirst<cr>", { desc = "First Tab" })
map("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New Tab" })
map("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next Tab" })
map("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close Tab" })
map("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Previous Tab" })

map({ "n", "x" }, "<localleader>r", function()
  Snacks.debug.run()
end, { desc = "Run Lua" })

-- ====================================================================
-- Tema (equivalente a Themery: selector persistente de temas NvChad)
-- ====================================================================
map("n", "<leader>ut", function()
  require("nvchad.themes").open()
end, { desc = "Elegir tema (persistente)" })
map("n", "<leader>uC", function()
  require("nvchad.themes").open()
end, { desc = "Colorschemes" })

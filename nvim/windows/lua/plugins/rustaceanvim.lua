return {
  "mrcjkb/rustaceanvim",
  version = "^5",
  lazy = false,
  opts = {
    dap = {
      adapter = false,
    },
  },
  -- rustaceanvim no expone setup(); su configuración se pasa por vim.g
  config = function(_, opts)
    vim.g.rustaceanvim = vim.tbl_deep_extend("keep", vim.g.rustaceanvim or {}, opts or {})
  end,
}

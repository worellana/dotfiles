-- Configuración única de diagnósticos (se usa en options.lua y al cargar el LSP,
-- para que NvChad no la sobrescriba).
return function()
  vim.diagnostic.config({
    virtual_text = {
      spacing = 4,
      prefix = "●",
      severity = { min = vim.diagnostic.severity.WARN },
      format = function(diagnostic)
        return diagnostic.message:gsub("\n.*", "")
      end,
    },
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = " ",
        [vim.diagnostic.severity.WARN] = " ",
        [vim.diagnostic.severity.INFO] = " ",
        [vim.diagnostic.severity.HINT] = " ",
      },
    },
    underline = true,
    update_in_insert = false,
    severity_sort = true,
    float = { border = "rounded" },
  })
end

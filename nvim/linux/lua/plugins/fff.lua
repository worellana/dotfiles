return {
  {
    "dmtrKovalenko/fff.nvim",
    -- Esto descarga automáticamente el binario precompilado de Rust para Windows
    build = function()
      require("fff.download").download_or_build_binary()
    end,
    -- Aseguramos que cargue de inmediato para que registre sus funciones
    lazy = false,
    opts = {
      debug = {
        enabled = false, -- Cambia a true si necesitas ver scores de búsqueda
      },
    },
    -- Mapeos de teclas oficiales recomendados por el autor
    keys = {
      { "ff", function() require('fff').find_files() end, desc = "FFF: Buscar Archivos" },
      { "fg", function() require('fff').live_grep() end, desc = "FFF: Live Grep (Buscar texto)" },
      { "fz", function() require('fff').live_grep({ grep = { modes = { 'fuzzy', 'plain' } } }) end, desc = "FFF: Live Fuzzy Grep" },
      { "fc", function() require('fff').live_grep({ query = vim.fn.expand("<cword>") }) end, desc = "FFF: Buscar palabra bajo el cursor" },
    },
  }
}

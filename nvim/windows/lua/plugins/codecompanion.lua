return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  opts = {
    adapters = {
      http = {
        gemini = function()
          return require("codecompanion.adapters").extend("gemini", {
            env = { api_key = "GEMINI_API_KEY" },
            schema = {
              model = { default = "gemini-3.5-flash" },
            },
          })
        end,
      },
    },
    strategies = {
      chat = { adapter = "gemini" },
      inline = { adapter = "gemini" },
    },
  },
  enabled = false,
}

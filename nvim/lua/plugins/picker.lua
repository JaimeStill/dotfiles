return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        files = { hidden = true },
        grep = { hidden = true },
        smart = { hidden = true },
      },
      exclude = { ".git" },
    },
  },
}

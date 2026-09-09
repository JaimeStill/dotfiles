return {
  "saghen/blink.cmp",
  opts = {
    sources = {
      default = { "lsp" },
      transform_items = function(_, items)
        return vim.tbl_filter(function(item)
          local kind = require("blink.cmp.types").CompletionItemKind[item.kind]
          return kind ~= "Text" and kind ~= "Snippet" and kind ~= "Macro"
        end, items)
      end,
    },
    -- keymap = {
    --   ["<CR>"] = {}, -- Disable Enter for accept
    --   ["<Tab>"] = { "accept", "fallback" }, -- Use Tab to accept
    -- },
  },
}

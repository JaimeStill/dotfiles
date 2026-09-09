return {
  "nvim-mini/mini.pairs",
  keys = {
    {
      "<CR>",
      function()
        local tag_filetypes = {
          html = true,
          xml = true,
          javascript = true,
          typescript = true,
          javascriptreact = true,
          typescriptreact = true,
          vue = true,
          svelte = true,
          php = true,
          astro = true,
          markdown = true,
        }

        if tag_filetypes[vim.bo.filetype] then
          local line = vim.api.nvim_get_current_line()
          local col = vim.api.nvim_win_get_cursor(0)[2]
          local before = line:sub(col, col)
          local after = line:sub(col + 1, col + 2)

          -- Check if cursor is between > and </
          if before == ">" and after == "</" then
            -- Manually convert termcodes since replace_keycodes is false
            return vim.api.nvim_replace_termcodes("<CR><CR><Up><End><C-f>", true, true, true)
          end
        end

        -- Otherwise use default CR behavior from mini.pairs
        return require("mini.pairs").cr()
      end,
      mode = "i",
      expr = true,
      replace_keycodes = false,
      desc = "Smart Enter for HTML tags",
    },
  },
}

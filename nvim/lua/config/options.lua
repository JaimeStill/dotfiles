require("config.remote_clipboard").setup()
-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.o.wrap = true
vim.o.linebreak = true
vim.opt.relativenumber = true
vim.g.lazyvim_mini_snippets_in_completion = false
-- LazyVim leaves the clipboard unsynced over SSH so its OSC 52 copies stay explicit ("+y).
-- remote_clipboard.lua already routes copies through OSC 52 in SSH/tmux/herdr, so sync always:
-- a plain y reaches the local machine's clipboard.
vim.opt.clipboard = "unnamedplus"

-- Minimal init for testing vim_leetcode_ai
-- Used by plenary test harness

-- Add the plugin to runtimepath
local plugin_root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h:h')
vim.opt.runtimepath:prepend(plugin_root)

-- Add plenary to runtimepath
local plenary_path = vim.fn.expand('~/.local/share/nvim/plugged/plenary.nvim')
if vim.fn.isdirectory(plenary_path) == 1 then
  vim.opt.runtimepath:prepend(plenary_path)
end

-- Add lua directory to package path for slideshow modules
local lua_path = plugin_root .. '/lua/?.lua;' .. plugin_root .. '/lua/?/init.lua;'
package.path = lua_path .. package.path

-- Load plenary if available
local ok, _ = pcall(require, 'plenary')
if not ok then
  print('Warning: plenary.nvim not found. Some tests may not work.')
end

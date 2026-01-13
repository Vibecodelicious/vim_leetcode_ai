-- vim_leetcode_ai - AI assistant with interactive slideshow
-- Main entry point

local M = {}

local config = require('vim_leetcode_ai.config')
local layout = require('vim_leetcode_ai.layout')
local terminal = require('vim_leetcode_ai.terminal')
local state = require('vim_leetcode_ai.state')
local keybindings = require('vim_leetcode_ai.keybindings')

--- Setup the plugin with user configuration
---@param opts table|nil User configuration options
function M.setup(opts)
  config.setup(opts)
  keybindings.setup()
end

--- Open the AI assistant layout
function M.open()
  if state.get().layout_open then
    vim.notify('AI assistant is already open', vim.log.levels.WARN)
    return
  end

  layout.create()
end

--- Close the AI assistant layout
function M.close()
  if not state.get().layout_open then
    vim.notify('AI assistant is not open', vim.log.levels.WARN)
    return
  end

  layout.close()
end

--- Restart the AI agent
function M.restart()
  terminal.restart()
end

return M

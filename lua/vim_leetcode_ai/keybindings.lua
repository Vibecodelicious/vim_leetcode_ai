-- vim_leetcode_ai keybindings module
-- Handles slideshow navigation keybindings

local M = {}

local config = require('vim_leetcode_ai.config')
local state = require('vim_leetcode_ai.state')

--- Setup keybindings for slideshow navigation
function M.setup()
  local keys = config.get().keys

  -- Open AI assistant
  vim.keymap.set('n', keys.open, function()
    require('vim_leetcode_ai').open()
  end, { desc = 'Open AI assistant' })

  -- Close AI assistant
  vim.keymap.set('n', keys.close, function()
    require('vim_leetcode_ai').close()
  end, { desc = 'Close AI assistant' })

  -- Slideshow/animation navigation - normal mode (for when focused in code buffer)
  -- Sends single keypress to tool pane (n=next, p=prev)
  vim.keymap.set('n', keys.next_slide, function()
    M.send_key_to_tool('n')
  end, { desc = 'Next slide' })

  vim.keymap.set('n', keys.prev_slide, function()
    M.send_key_to_tool('p')
  end, { desc = 'Previous slide' })
end

--- Send a single keypress to the tool pane terminal
---@param key string Single character to send
function M.send_key_to_tool(key)
  local s = state.get()
  if not s.tool_active then
    return
  end

  if s.tool_terminal_job then
    vim.fn.chansend(s.tool_terminal_job, key)
  end
end

return M

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

  -- Slideshow navigation - normal mode
  vim.keymap.set('n', keys.next_slide, function()
    M.send_to_slideshow('next')
  end, { desc = 'Next slide' })

  vim.keymap.set('n', keys.prev_slide, function()
    M.send_to_slideshow('prev')
  end, { desc = 'Previous slide' })

  -- Slideshow navigation - terminal mode (so keybindings work when focused in terminal)
  vim.keymap.set('t', keys.next_slide, function()
    M.send_to_slideshow('next')
  end, { desc = 'Next slide' })

  vim.keymap.set('t', keys.prev_slide, function()
    M.send_to_slideshow('prev')
  end, { desc = 'Previous slide' })
end

--- Send a command to the slideshow program via chansend
---@param cmd string Command to send (next, prev, goto N, quit)
function M.send_to_slideshow(cmd)
  -- TODO: Implement in US2 (T041)
  local s = state.get()
  if not s.slideshow_active then
    return
  end

  if s.tool_terminal_job then
    vim.fn.chansend(s.tool_terminal_job, cmd .. '\n')
  end
end

return M

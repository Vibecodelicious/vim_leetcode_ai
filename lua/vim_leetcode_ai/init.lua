-- vim_leetcode_ai - AI assistant with interactive slideshow
-- Main entry point

local M = {}

local config = require('vim_leetcode_ai.config')
local layout = require('vim_leetcode_ai.layout')
local terminal = require('vim_leetcode_ai.terminal')
local state = require('vim_leetcode_ai.state')
local keybindings = require('vim_leetcode_ai.keybindings')

-- Track if setup has been called
local setup_called = false

--- Ensure plugin is initialized (auto-setup with defaults if needed)
local function ensure_setup()
  if not setup_called then
    M.setup({})
  end
end

--- Setup the plugin with user configuration
---@param opts table|nil User configuration options
function M.setup(opts)
  config.setup(opts)
  keybindings.setup()

  -- Setup autocmd to clean up jobs when vim exits
  local group = vim.api.nvim_create_augroup('VimLeetcodeAICleanup', { clear = true })
  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = group,
    callback = function()
      -- Stop all running jobs to prevent orphaned processes
      local s = state.get()
      if s.ai_terminal_job then
        vim.fn.jobstop(s.ai_terminal_job)
      end
      if s.tool_terminal_job then
        vim.fn.jobstop(s.tool_terminal_job)
      end
      if s.quickfix_timer then
        pcall(function()
          s.quickfix_timer:stop()
          s.quickfix_timer:close()
        end)
      end
    end,
  })

  setup_called = true
end

--- Open the AI assistant layout
function M.open()
  ensure_setup()

  if state.get().layout_open then
    vim.notify('AI assistant is already open', vim.log.levels.WARN)
    return
  end

  layout.create()
end

--- Close the AI assistant layout
function M.close()
  ensure_setup()

  if not state.get().layout_open then
    vim.notify('AI assistant is not open', vim.log.levels.WARN)
    return
  end

  layout.close()
end

--- Restart the AI agent
function M.restart()
  ensure_setup()
  terminal.restart()
end

return M

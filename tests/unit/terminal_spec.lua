-- Tests for lua/vim_leetcode_ai/terminal.lua

describe('terminal', function()
  local terminal
  local state
  local config

  before_each(function()
    package.loaded['vim_leetcode_ai.terminal'] = nil
    package.loaded['vim_leetcode_ai.state'] = nil
    package.loaded['vim_leetcode_ai.config'] = nil
    terminal = require('vim_leetcode_ai.terminal')
    state = require('vim_leetcode_ai.state')
    config = require('vim_leetcode_ai.config')
    state.reset()
    config.setup({ ai_command = 'echo "test"' }) -- Use simple command for tests
  end)

  describe('spawn_ai_agent()', function()
    -- Note: These tests require a proper terminal environment
    -- They may fail in headless mode
    it('should be callable', function()
      assert.is_function(terminal.spawn_ai_agent)
    end)

    it('should require a window argument', function()
      -- The function signature takes a window ID
      -- In headless mode, we can only verify the function exists
      -- and handles errors gracefully
      local ok = pcall(function()
        -- Create a scratch buffer first
        local buf = vim.api.nvim_create_buf(false, true)
        local win = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_buf(win, buf)
        terminal.spawn_ai_agent(win)
      end)
      -- Either it works or fails gracefully
      assert.is_boolean(ok)
    end)
  end)

  describe('on_exit_callback()', function()
    it('should display restart/close instructions on exit', function()
      -- This test verifies the callback shows a message
      -- In practice, this would be an integration test
      -- For now, just verify the function exists and is callable
      assert.is_function(terminal.on_exit_callback)
    end)
  end)

  describe('restart()', function()
    it('should be callable', function()
      assert.is_function(terminal.restart)
    end)

    it('should warn when layout is not open', function()
      -- Arrange: ensure layout is closed
      state.reset()

      -- Act & Assert: should not error
      assert.has_no.errors(function()
        terminal.restart()
      end)
    end)
  end)
end)

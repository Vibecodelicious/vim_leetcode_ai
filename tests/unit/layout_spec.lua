-- Tests for lua/vim_leetcode_ai/layout.lua

describe('layout', function()
  local layout
  local state

  before_each(function()
    package.loaded['vim_leetcode_ai.layout'] = nil
    package.loaded['vim_leetcode_ai.state'] = nil
    layout = require('vim_leetcode_ai.layout')
    state = require('vim_leetcode_ai.state')
    state.reset()
  end)

  describe('create()', function()
    it('should create a three-pane layout', function()
      -- Arrange: start with a single window
      local initial_win_count = #vim.api.nvim_list_wins()

      -- Act
      layout.create()

      -- Assert: should have 3 windows (tool, code, ai terminal)
      local s = state.get()
      assert.is_true(s.layout_open)
      assert.is_not_nil(s.code_window)
      assert.is_not_nil(s.tool_window)
      assert.is_not_nil(s.ai_window)

      -- All windows should be valid
      assert.is_true(vim.api.nvim_win_is_valid(s.code_window))
      assert.is_true(vim.api.nvim_win_is_valid(s.tool_window))
      assert.is_true(vim.api.nvim_win_is_valid(s.ai_window))
    end)

    it('should preserve the current buffer in code pane', function()
      -- Arrange: create a buffer with content
      local test_buf = vim.api.nvim_create_buf(true, false)
      vim.api.nvim_buf_set_lines(test_buf, 0, -1, false, {'line 1', 'line 2'})
      vim.api.nvim_set_current_buf(test_buf)

      -- Act
      layout.create()

      -- Assert: code buffer should be the original buffer
      local s = state.get()
      assert.equals(test_buf, s.code_buffer)
    end)

    it('should not create layout if already open', function()
      -- Arrange
      layout.create()
      local s = state.get()
      local original_code_window = s.code_window

      -- Act: try to create again
      layout.create()

      -- Assert: should be same window (not recreated)
      -- The init.lua guards against this, but layout should handle it too
      assert.equals(original_code_window, state.get().code_window)
    end)
  end)

  describe('get_tool_pane_size()', function()
    it('should return dimensions of tool pane', function()
      -- Arrange
      layout.create()

      -- Act
      local size = layout.get_tool_pane_size()

      -- Assert
      assert.is_number(size.cols)
      assert.is_number(size.rows)
      assert.is_true(size.cols > 0)
      assert.is_true(size.rows > 0)
    end)

    it('should return default dimensions when layout not open', function()
      -- Act
      local size = layout.get_tool_pane_size()

      -- Assert: should return reasonable defaults
      assert.is_number(size.cols)
      assert.is_number(size.rows)
    end)
  end)

  describe('get_code_buffer_info()', function()
    it('should return buffer info', function()
      -- Arrange
      local test_buf = vim.api.nvim_create_buf(true, false)
      vim.api.nvim_buf_set_name(test_buf, '/tmp/test.lua')
      vim.api.nvim_buf_set_lines(test_buf, 0, -1, false, {'line 1', 'line 2', 'line 3'})
      vim.api.nvim_set_current_buf(test_buf)
      layout.create()

      -- Act
      local info = layout.get_code_buffer_info()

      -- Assert
      assert.equals(3, info.lines)
      assert.equals('/tmp/test.lua', info.path)
    end)
  end)
end)

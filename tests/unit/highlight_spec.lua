-- Tests for lua/vim_leetcode_ai/highlight.lua (T024)

describe('highlight', function()
  local highlight
  local state

  before_each(function()
    package.loaded['vim_leetcode_ai.highlight'] = nil
    package.loaded['vim_leetcode_ai.state'] = nil
    highlight = require('vim_leetcode_ai.highlight')
    state = require('vim_leetcode_ai.state')
    state.reset()
  end)

  describe('set_lines()', function()
    it('should be callable', function()
      assert.is_function(highlight.set_lines)
    end)

    it('should highlight specified lines in code buffer', function()
      -- Arrange: create a buffer with some content and a window
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        'line 1',
        'line 2',
        'line 3',
        'line 4',
        'line 5',
      })
      local win = vim.api.nvim_get_current_win()
      state.update({ code_buffer = buf, code_window = win })

      -- Act
      highlight.set_lines({ 2, 3 })

      -- Assert: check that extmarks were added
      local s = state.get()
      local marks = vim.api.nvim_buf_get_extmarks(buf, s.highlight_ns, 0, -1, {})
      assert.equals(2, #marks)

      -- Cleanup
      highlight.clear()
      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it('should clear previous highlights before setting new ones', function()
      -- Arrange
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        'line 1',
        'line 2',
        'line 3',
      })
      local win = vim.api.nvim_get_current_win()
      state.update({ code_buffer = buf, code_window = win })

      -- Act: set highlights twice
      highlight.set_lines({ 1 })
      highlight.set_lines({ 2, 3 })

      -- Assert: should only have 2 marks (not 3)
      local s = state.get()
      local marks = vim.api.nvim_buf_get_extmarks(buf, s.highlight_ns, 0, -1, {})
      assert.equals(2, #marks)

      -- Cleanup
      highlight.clear()
      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it('should handle empty lines array by clearing highlights', function()
      -- Arrange
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'line 1', 'line 2' })
      local win = vim.api.nvim_get_current_win()
      state.update({ code_buffer = buf, code_window = win })
      highlight.set_lines({ 1 })

      -- Act
      highlight.set_lines({})

      -- Assert: no marks
      local s = state.get()
      local marks = vim.api.nvim_buf_get_extmarks(buf, s.highlight_ns, 0, -1, {})
      assert.equals(0, #marks)

      -- Cleanup
      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it('should skip invalid line numbers with warning', function()
      -- Arrange: buffer with 3 lines
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'line 1', 'line 2', 'line 3' })
      local win = vim.api.nvim_get_current_win()
      state.update({ code_buffer = buf, code_window = win })

      -- Act: try to highlight line 99 (doesn't exist)
      highlight.set_lines({ 2, 99 })

      -- Assert: only line 2 should be highlighted
      local s = state.get()
      local marks = vim.api.nvim_buf_get_extmarks(buf, s.highlight_ns, 0, -1, {})
      assert.equals(1, #marks)

      -- Cleanup
      highlight.clear()
      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it('should use full-line background highlight', function()
      -- Arrange
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'line 1', 'line 2' })
      local win = vim.api.nvim_get_current_win()
      state.update({ code_buffer = buf, code_window = win })

      -- Act
      highlight.set_lines({ 1 })

      -- Assert: extmark should have line_hl_group
      local s = state.get()
      local marks = vim.api.nvim_buf_get_extmarks(buf, s.highlight_ns, 0, -1, { details = true })
      assert.equals(1, #marks)
      -- The mark should have line highlight (details[4] contains options)
      local details = marks[1][4]
      assert.is_not_nil(details.line_hl_group)

      -- Cleanup
      highlight.clear()
      vim.api.nvim_buf_delete(buf, { force = true })
    end)
  end)

  describe('clear()', function()
    it('should remove all highlights', function()
      -- Arrange
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'line 1', 'line 2' })
      state.update({ code_buffer = buf })
      highlight.set_lines({ 1, 2 })

      -- Act
      highlight.clear()

      -- Assert
      local s = state.get()
      local marks = vim.api.nvim_buf_get_extmarks(buf, s.highlight_ns, 0, -1, {})
      assert.equals(0, #marks)

      -- Cleanup
      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it('should handle missing code buffer gracefully', function()
      -- Arrange: no code buffer set
      state.update({ code_buffer = nil })

      -- Act & Assert: should not error
      assert.has_no.errors(function()
        highlight.clear()
      end)
    end)
  end)

  describe('scroll_to_highlight()', function()
    it('should be callable', function()
      assert.is_function(highlight.scroll_to_highlight)
    end)

    -- Note: Testing actual scrolling requires a window, which is
    -- harder to set up in unit tests. The function should exist
    -- and handle edge cases gracefully.
  end)

  describe('mark_stale()', function()
    it('should update state to indicate stale highlights', function()
      -- Arrange
      state.update({ slideshow_stale = false })

      -- Act
      highlight.mark_stale()

      -- Assert
      local s = state.get()
      assert.is_true(s.slideshow_stale)
    end)
  end)

  describe('clear_stale()', function()
    it('should clear stale indicator', function()
      -- Arrange
      state.update({ slideshow_stale = true })

      -- Act
      highlight.clear_stale()

      -- Assert
      local s = state.get()
      assert.is_false(s.slideshow_stale)
    end)
  end)
end)

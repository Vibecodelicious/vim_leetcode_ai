-- vim_leetcode_ai highlight module
-- Handles line highlighting in the code editor

local M = {}

local state = require('vim_leetcode_ai.state')

-- Define highlight group for slideshow lines
vim.api.nvim_set_hl(0, 'VimLeetcodeAIHighlight', {
  bg = '#3a3a5a',
  default = true,
})

-- Define highlight group for stale indicator
vim.api.nvim_set_hl(0, 'VimLeetcodeAIStale', {
  bg = '#5a3a3a',
  default = true,
})

--- Set line highlights in the code buffer
---@param lines number[] Array of 1-indexed line numbers to highlight
function M.set_lines(lines)
  local s = state.get()

  if not s.code_buffer or not vim.api.nvim_buf_is_valid(s.code_buffer) then
    return
  end

  -- Clear existing highlights first
  M.clear()

  -- Get total lines in buffer for validation
  local total_lines = vim.api.nvim_buf_line_count(s.code_buffer)

  -- Determine highlight group based on stale state
  local hl_group = s.slideshow_stale and 'VimLeetcodeAIStale' or 'VimLeetcodeAIHighlight'

  local valid_lines = {}
  local invalid_lines = {}

  for _, line in ipairs(lines) do
    if line >= 1 and line <= total_lines then
      table.insert(valid_lines, line)
      -- Add extmark with line highlight (0-indexed)
      vim.api.nvim_buf_set_extmark(s.code_buffer, s.highlight_ns, line - 1, 0, {
        line_hl_group = hl_group,
        priority = 100,
      })
    else
      table.insert(invalid_lines, line)
    end
  end

  -- Warn about invalid lines (FR-028)
  if #invalid_lines > 0 then
    local msg = string.format(
      'Slideshow: %d invalid line(s) skipped (out of range 1-%d): %s',
      #invalid_lines,
      total_lines,
      table.concat(invalid_lines, ', ')
    )
    vim.notify(msg, vim.log.levels.WARN)
  end

  -- Scroll to show highlighted range
  if #valid_lines > 0 then
    table.sort(valid_lines)
    M.scroll_to_highlight_range(valid_lines[1], valid_lines[#valid_lines])
  end
end

--- Clear all line highlights
function M.clear()
  local s = state.get()
  if s.code_buffer and vim.api.nvim_buf_is_valid(s.code_buffer) then
    vim.api.nvim_buf_clear_namespace(s.code_buffer, s.highlight_ns, 0, -1)
  end
end

--- Scroll the code window to show a highlighted range
---@param first_line number First line of range (1-indexed)
---@param last_line number Last line of range (1-indexed)
function M.scroll_to_highlight_range(first_line, last_line)
  local s = state.get()

  if not s.code_window or not vim.api.nvim_win_is_valid(s.code_window) then
    return
  end

  -- Get window info
  local win_height = vim.api.nvim_win_get_height(s.code_window)
  local win_info = vim.fn.getwininfo(s.code_window)[1]
  if not win_info then
    return
  end

  local topline = win_info.topline
  local botline = win_info.botline
  local range_size = last_line - first_line + 1

  -- Check if entire range is already visible
  if first_line >= topline and last_line <= botline then
    return
  end

  local target_topline
  if range_size >= win_height then
    -- Range is too large to fit - show from the beginning
    target_topline = first_line
  else
    -- Range fits - try to show entire range with some context
    -- Position so first_line is near the top with a small margin
    local margin = math.floor((win_height - range_size) / 3)
    target_topline = math.max(1, first_line - margin)
  end

  -- Use nvim_win_call to set the view
  vim.api.nvim_win_call(s.code_window, function()
    vim.fn.winrestview({ topline = target_topline })
  end)
end

--- Mark highlights as stale (code was modified)
function M.mark_stale()
  state.update({ slideshow_stale = true })

  -- Re-apply highlights with stale coloring
  local s = state.get()
  if s.code_buffer and vim.api.nvim_buf_is_valid(s.code_buffer) then
    -- Get current extmarks
    local marks = vim.api.nvim_buf_get_extmarks(s.code_buffer, s.highlight_ns, 0, -1, { details = true })
    if #marks > 0 then
      -- Clear and re-add with stale highlight
      vim.api.nvim_buf_clear_namespace(s.code_buffer, s.highlight_ns, 0, -1)
      for _, mark in ipairs(marks) do
        local line = mark[2] -- 0-indexed line number
        vim.api.nvim_buf_set_extmark(s.code_buffer, s.highlight_ns, line, 0, {
          line_hl_group = 'VimLeetcodeAIStale',
          priority = 100,
        })
      end
    end
  end

  -- Notify user
  vim.notify('Slideshow highlights are stale (code was modified). Refresh the slideshow to update.', vim.log.levels.WARN)
end

--- Clear stale indicator
function M.clear_stale()
  state.update({ slideshow_stale = false })
end

--- Setup autocmd to detect code buffer modifications (FR-029)
function M.setup_stale_detection()
  local s = state.get()

  if not s.code_buffer or not vim.api.nvim_buf_is_valid(s.code_buffer) then
    return
  end

  -- Create autocmd group
  local group = vim.api.nvim_create_augroup('VimLeetcodeAIStale', { clear = true })

  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
    group = group,
    buffer = s.code_buffer,
    callback = function()
      local current_state = state.get()
      if current_state.slideshow_active and not current_state.slideshow_stale then
        M.mark_stale()
      end
    end,
  })
end

return M

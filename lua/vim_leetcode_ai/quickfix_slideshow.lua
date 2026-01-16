-- vim_leetcode_ai quickfix slideshow module
-- Handles quickfix-based slideshow navigation with buffer content display

local M = {}

local state = require('vim_leetcode_ai.state')
local highlight = require('vim_leetcode_ai.highlight')
local layout = require('vim_leetcode_ai.layout')

--- Create a content buffer for displaying slide explanations
---@return number buf_id The buffer ID
local function create_content_buffer()
  local buf = vim.api.nvim_create_buf(false, true)

  -- Set buffer options
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = false

  -- Set buffer name for identification
  pcall(vim.api.nvim_buf_set_name, buf, 'vim_leetcode_ai://quickfix_content')

  return buf
end

--- Update the content buffer with slide text
---@param buf number Buffer ID
---@param content string Slide content text
local function update_content_buffer(buf, content)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  -- Temporarily allow modification
  vim.bo[buf].modifiable = true

  -- Split content by newlines
  local lines = {}
  for line in content:gmatch('[^\n]*') do
    table.insert(lines, line)
  end

  -- Replace buffer content
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Lock buffer
  vim.bo[buf].modifiable = false
end

--- Launch a quickfix-based slideshow
---@param slideshow_data table Parsed slideshow data {slides: [{content: string, lines: number[], ...}, ...]}
---@return boolean success Whether the slideshow was launched successfully
function M.launch(slideshow_data)
  local s = state.get()

  if not s.layout_open then
    vim.notify('AI assistant is not open', vim.log.levels.WARN)
    return false
  end

  -- Ensure tool pane exists
  local tool_win = layout.show_tool_pane()
  if not tool_win then
    vim.notify('Failed to create tool pane', vim.log.levels.ERROR)
    return false
  end

  s = state.get() -- Refresh state

  -- Create content buffer
  local content_buf = create_content_buffer()

  -- Display content buffer in tool pane
  vim.api.nvim_win_set_buf(s.tool_window, content_buf)

  -- Convert slides to quickfix entries
  local qf_items = {}
  for i, slide in ipairs(slideshow_data.slides) do
    table.insert(qf_items, {
      text = string.format('Slide %d: %s', i, slide.content:sub(1, 50):gsub('\n', ' ')),
      user_data = {
        slide_index = i,
        content = slide.content,
        lines = slide.lines or {},
      }
    })
  end

  -- Populate quickfix list
  vim.fn.setqflist({}, ' ', {
    title = 'Slideshow',
    items = qf_items,
  })

  -- Update state
  state.update({
    tool_active = true,
    tool_stale = false,
    quickfix_content_buf = content_buf,
  })

  -- Setup stale detection
  highlight.setup_stale_detection()

  -- Setup timer to monitor quickfix position changes
  local last_idx = 0
  local timer = vim.loop.new_timer()
  timer:start(
    100, -- initial delay
    100, -- repeat interval
    vim.schedule_wrap(function()
      if not vim.api.nvim_buf_is_valid(content_buf) then
        -- Content buffer was deleted, stop the timer
        timer:close()
        return
      end

      local qf_list = vim.fn.getqflist({ idx = 0 })
      if qf_list and qf_list.idx and qf_list.idx ~= last_idx then
        last_idx = qf_list.idx
        M.on_quickfix_entry_change(content_buf)
      end
    end)
  )

  -- Store timer in state for cleanup
  state.update({ quickfix_timer = timer })

  -- Navigate to first slide
  M.on_quickfix_entry_change(content_buf)

  return true
end

--- Handle quickfix entry change (navigation)
---@param content_buf number Buffer ID for content display
function M.on_quickfix_entry_change(content_buf)
  local qf_list = vim.fn.getqflist({ idx = 0 })
  if not qf_list or not qf_list.idx or qf_list.idx < 1 then
    return
  end

  local idx = qf_list.idx
  local qf_items = vim.fn.getqflist()
  if not qf_items or idx > #qf_items then
    return
  end

  local entry = qf_items[idx]
  if not entry or not entry.user_data then
    return
  end

  local user_data = entry.user_data

  -- Update content buffer
  if vim.api.nvim_buf_is_valid(content_buf) then
    update_content_buffer(content_buf, user_data.content)
  end

  -- Update highlights in code buffer
  highlight.set_lines(user_data.lines)
end

--- Clear quickfix slideshow (called when slideshow ends)
function M.clear()
  local s = state.get()

  -- Stop the timer if it exists
  if s.quickfix_timer then
    s.quickfix_timer:stop()
    s.quickfix_timer:close()
  end

  if s.quickfix_content_buf and vim.api.nvim_buf_is_valid(s.quickfix_content_buf) then
    vim.api.nvim_buf_delete(s.quickfix_content_buf, { force = true })
  end

  highlight.clear()

  state.update({
    tool_active = false,
    quickfix_content_buf = nil,
    quickfix_timer = nil,
  })

  -- Clear quickfix list
  vim.fn.setqflist({})
end

return M

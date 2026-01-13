-- vim_leetcode_ai layout module
-- Handles the three-pane layout management

local M = {}

local state = require('vim_leetcode_ai.state')
local config = require('vim_leetcode_ai.config')

--- Create the three-pane layout
--- Layout: tool output (top-left), code editor (top-right), AI terminal (bottom)
function M.create()
  local s = state.get()

  -- Guard against double-open
  if s.layout_open then
    return
  end

  local cfg = config.get()

  -- Save the current buffer as the code buffer
  local code_buf = vim.api.nvim_get_current_buf()
  local code_win = vim.api.nvim_get_current_win()

  -- Calculate dimensions
  local total_height = vim.o.lines - vim.o.cmdheight - 1
  local total_width = vim.o.columns
  local bottom_height = math.floor(total_height * cfg.layout.bottom_height)
  local top_height = total_height - bottom_height
  local tool_width = math.floor(total_width * cfg.layout.tool_width)

  -- Create the layout:
  -- 1. Split horizontally to create bottom pane (AI terminal) - full width
  vim.cmd('botright split')
  local ai_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_height(ai_win, bottom_height)

  -- 2. Go back to code window and split vertically for tool pane on left
  vim.api.nvim_set_current_win(code_win)
  vim.cmd('aboveleft vsplit')
  local tool_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_width(tool_win, tool_width)

  -- Create empty buffer for tool pane
  local tool_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(tool_win, tool_buf)
  -- Use unique buffer name with timestamp to avoid conflicts
  local buf_name = string.format('vim_leetcode_ai://tool/%d', os.time())
  pcall(vim.api.nvim_buf_set_name, tool_buf, buf_name)
  vim.bo[tool_buf].buftype = 'nofile'
  vim.bo[tool_buf].bufhidden = 'hide'
  vim.bo[tool_buf].swapfile = false

  -- Set tool pane placeholder content
  vim.api.nvim_buf_set_lines(tool_buf, 0, -1, false, {
    '',
    '  AI Tool Output',
    '  ──────────────',
    '',
    '  Waiting for AI to launch a tool...',
    '',
  })

  -- Spawn AI agent in bottom pane
  vim.api.nvim_set_current_win(ai_win)
  local terminal = require('vim_leetcode_ai.terminal')
  local job_id = terminal.spawn_ai_agent(ai_win)

  -- Update state
  state.update({
    layout_open = true,
    code_buffer = code_buf,
    code_window = code_win,
    tool_window = tool_win,
    tool_terminal_buf = tool_buf,
    ai_window = ai_win,
  })

  -- Focus back on code window
  vim.api.nvim_set_current_win(code_win)
end

--- Close the layout and restore normal view
function M.close()
  local s = state.get()

  if not s.layout_open then
    return
  end

  -- Close tool window (keep buffer for restore)
  if s.tool_window and vim.api.nvim_win_is_valid(s.tool_window) then
    vim.api.nvim_win_close(s.tool_window, true)
  end

  -- Close AI window (keep buffer for restore)
  if s.ai_window and vim.api.nvim_win_is_valid(s.ai_window) then
    vim.api.nvim_win_close(s.ai_window, true)
  end

  -- Update state
  state.update({
    layout_open = false,
    tool_window = nil,
    ai_window = nil,
    code_window = nil,
  })

  -- Clear highlights
  local highlight = require('vim_leetcode_ai.highlight')
  highlight.clear()
end

--- Restore the layout from hidden buffers
function M.restore()
  local s = state.get()

  -- If we have existing terminal buffers, restore them
  if s.ai_terminal_buf and vim.api.nvim_buf_is_valid(s.ai_terminal_buf) then
    -- Create layout structure first
    M.create()

    -- Replace the new AI buffer with the existing one
    local new_state = state.get()
    if new_state.ai_window and vim.api.nvim_win_is_valid(new_state.ai_window) then
      vim.api.nvim_win_set_buf(new_state.ai_window, s.ai_terminal_buf)
    end
  else
    -- No existing session, create fresh
    M.create()
  end
end

--- Get the size of the tool output pane
---@return table {cols: number, rows: number}
function M.get_tool_pane_size()
  local s = state.get()
  if s.tool_window and vim.api.nvim_win_is_valid(s.tool_window) then
    return {
      cols = vim.api.nvim_win_get_width(s.tool_window),
      rows = vim.api.nvim_win_get_height(s.tool_window),
    }
  end
  return { cols = 80, rows = 24 }
end

--- Get info about the code buffer
---@return table {lines: number, path: string}
function M.get_code_buffer_info()
  local s = state.get()
  if s.code_buffer and vim.api.nvim_buf_is_valid(s.code_buffer) then
    return {
      lines = vim.api.nvim_buf_line_count(s.code_buffer),
      path = vim.api.nvim_buf_get_name(s.code_buffer),
    }
  end
  return { lines = 0, path = '' }
end

return M

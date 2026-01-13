-- vim_leetcode_ai layout module
-- Handles the three-pane layout management

local M = {}

local state = require('vim_leetcode_ai.state')
local config = require('vim_leetcode_ai.config')

--- Create the two-pane layout (code editor + AI terminal)
--- Tool pane is created on-demand when a tool is launched
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
  local bottom_height = math.floor(total_height * cfg.layout.bottom_height)

  -- Create the layout:
  -- Split horizontally to create bottom pane (AI terminal) - full width
  vim.cmd('botright split')
  local ai_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_height(ai_win, bottom_height)

  -- Spawn AI agent in bottom pane
  local terminal = require('vim_leetcode_ai.terminal')
  local job_id = terminal.spawn_ai_agent(ai_win)

  -- Update state (no tool window yet)
  state.update({
    layout_open = true,
    code_buffer = code_buf,
    code_window = code_win,
    tool_window = nil,
    tool_terminal_buf = nil,
    ai_window = ai_win,
  })

  -- Focus back on code window
  vim.api.nvim_set_current_win(code_win)
end

--- Show the tool pane (create if doesn't exist)
--- Called automatically when a tool is launched
---@return number|nil tool_window Window ID of the tool pane
function M.show_tool_pane()
  local s = state.get()

  if not s.layout_open then
    vim.notify('AI assistant is not open', vim.log.levels.WARN)
    return nil
  end

  -- If tool window already exists and is valid, return it
  if s.tool_window and vim.api.nvim_win_is_valid(s.tool_window) then
    return s.tool_window
  end

  local cfg = config.get()

  -- Calculate tool pane width
  local total_width = vim.o.columns
  local tool_width = math.floor(total_width * cfg.layout.tool_width)

  -- Go to code window and split vertically for tool pane on left
  if s.code_window and vim.api.nvim_win_is_valid(s.code_window) then
    vim.api.nvim_set_current_win(s.code_window)
  end

  vim.cmd('aboveleft vsplit')
  local tool_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_width(tool_win, tool_width)

  -- Create empty buffer for tool pane
  local tool_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(tool_win, tool_buf)
  local buf_name = string.format('vim_leetcode_ai://tool/%d', os.time())
  pcall(vim.api.nvim_buf_set_name, tool_buf, buf_name)
  vim.bo[tool_buf].buftype = 'nofile'
  vim.bo[tool_buf].bufhidden = 'hide'
  vim.bo[tool_buf].swapfile = false

  -- Update state
  state.update({
    tool_window = tool_win,
    tool_terminal_buf = tool_buf,
  })

  return tool_win
end

--- Close the layout and restore normal view
function M.close()
  local s = state.get()

  if not s.layout_open then
    return
  end

  -- Helper to safely close a window (can't close last window)
  local function safe_close(win)
    if win and vim.api.nvim_win_is_valid(win) and vim.fn.winnr('$') > 1 then
      vim.api.nvim_win_close(win, true)
    end
  end

  -- Close tool window first, then AI window (keep buffers for restore)
  safe_close(s.tool_window)
  safe_close(s.ai_window)

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

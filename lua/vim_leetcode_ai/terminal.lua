-- vim_leetcode_ai terminal module
-- Handles terminal buffer management for AI agent and tool output

local M = {}

local state = require('vim_leetcode_ai.state')
local config = require('vim_leetcode_ai.config')

--- Spawn the AI agent in the specified window
---@param win number Window ID to spawn terminal in
---@return number|nil job_id The job ID if successful
function M.spawn_ai_agent(win)
  local cfg = config.get()
  local cmd = cfg.ai_command

  -- Ensure we're in the right window
  vim.api.nvim_set_current_win(win)

  -- Create a new scratch buffer first to avoid transforming the shared buffer
  -- This is necessary because termopen() transforms the current buffer into a terminal
  local scratch_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(win, scratch_buf)

  -- Create terminal with the AI command
  local job_id = vim.fn.termopen(cmd, {
    on_exit = function(job, exit_code, event)
      M.on_exit_callback(job, exit_code)
    end,
  })

  if job_id <= 0 then
    vim.notify('Failed to start AI agent: ' .. cmd, vim.log.levels.ERROR)
    return nil
  end

  -- Get the buffer that was created
  local buf = vim.api.nvim_get_current_buf()

  -- Update state
  state.update({
    ai_terminal_job = job_id,
    ai_terminal_buf = buf,
  })

  -- Set buffer options
  vim.bo[buf].bufhidden = 'hide'

  return job_id
end

--- Handle AI agent terminal exit
---@param job_id number The job ID that exited
---@param exit_code number The exit code
function M.on_exit_callback(job_id, exit_code)
  local s = state.get()

  -- Only handle if this is our AI terminal
  if s.ai_terminal_job ~= job_id then
    return
  end

  -- Clear the job ID (process is dead)
  state.update({ ai_terminal_job = nil })

  -- Show message with instructions
  local cfg = config.get()
  local msg = string.format(
    'AI agent exited (code %d). Use :AIRestart to restart or %s to close.',
    exit_code,
    cfg.keys.close
  )
  vim.notify(msg, vim.log.levels.INFO)

  -- If the terminal buffer is still visible, show instructions in it
  if s.ai_terminal_buf and vim.api.nvim_buf_is_valid(s.ai_terminal_buf) then
    -- The terminal buffer will show [Process exited N] already
    -- We could append more instructions but that requires the buffer to be modifiable
  end
end

--- Restart the AI agent
function M.restart()
  local s = state.get()

  -- Check if layout is open
  if not s.layout_open then
    vim.notify('AI assistant is not open. Use :AIOpen first.', vim.log.levels.WARN)
    return
  end

  -- If there's a running job, stop it first
  if s.ai_terminal_job then
    vim.fn.jobstop(s.ai_terminal_job)
    state.update({ ai_terminal_job = nil })
  end

  -- If we have an AI window, spawn new terminal there
  if s.ai_window and vim.api.nvim_win_is_valid(s.ai_window) then
    -- Delete old buffer if it exists
    if s.ai_terminal_buf and vim.api.nvim_buf_is_valid(s.ai_terminal_buf) then
      vim.api.nvim_buf_delete(s.ai_terminal_buf, { force = true })
    end

    M.spawn_ai_agent(s.ai_window)
    vim.notify('AI agent restarted', vim.log.levels.INFO)
  else
    vim.notify('AI window not found. Try :AIClose then :AIOpen.', vim.log.levels.ERROR)
  end
end

--- Launch a program in the tool output pane
---@param cmd string Command to run
---@return number|nil job_id The job ID if successful
function M.launch_in_tool_pane(cmd)
  local s = state.get()

  if not s.layout_open then
    vim.notify('AI assistant is not open', vim.log.levels.WARN)
    return nil
  end

  if not s.tool_window or not vim.api.nvim_win_is_valid(s.tool_window) then
    vim.notify('Tool pane not found', vim.log.levels.ERROR)
    return nil
  end

  -- Kill existing tool process if any
  if s.tool_terminal_job then
    vim.fn.jobstop(s.tool_terminal_job)
  end

  -- Save current window
  local current_win = vim.api.nvim_get_current_win()

  -- Switch to tool window
  vim.api.nvim_set_current_win(s.tool_window)

  -- Create a scratch buffer FIRST and set it in the window
  -- This must happen BEFORE deleting the old buffer, otherwise
  -- deleting the buffer might close the window
  local scratch_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(s.tool_window, scratch_buf)

  -- Now safe to delete old buffer (window has a new buffer)
  if s.tool_terminal_buf and vim.api.nvim_buf_is_valid(s.tool_terminal_buf) then
    vim.api.nvim_buf_delete(s.tool_terminal_buf, { force = true })
  end

  -- Create terminal with command
  local job_id = vim.fn.termopen(cmd, {
    on_exit = function(job, exit_code, event)
      -- Tool program exited - could show status
      state.update({
        tool_terminal_job = nil,
        slideshow_active = false,
      })
    end,
  })

  if job_id <= 0 then
    vim.notify('Failed to launch: ' .. cmd, vim.log.levels.ERROR)
    vim.api.nvim_set_current_win(current_win)
    return nil
  end

  local buf = vim.api.nvim_get_current_buf()

  state.update({
    tool_terminal_job = job_id,
    tool_terminal_buf = buf,
    slideshow_active = true, -- Assume slideshow if launching program
  })

  -- Restore original window
  vim.api.nvim_set_current_win(current_win)

  return job_id
end

return M

-- vim_leetcode_ai state management module

local M = {}

---@class VimLeetcodeAIState
---@field layout_open boolean Whether the three-pane layout is active
---@field ai_terminal_job number|nil Job ID of the AI agent terminal
---@field ai_terminal_buf number|nil Buffer ID of the AI agent terminal
---@field tool_terminal_job number|nil Job ID of the tool output terminal
---@field tool_terminal_buf number|nil Buffer ID of the tool output terminal
---@field code_buffer number|nil Buffer ID of the code editor pane
---@field code_window number|nil Window ID of the code editor pane
---@field tool_window number|nil Window ID of the tool output pane
---@field ai_window number|nil Window ID of the AI terminal pane
---@field highlight_ns number Namespace ID for line highlights
---@field slideshow_active boolean Whether a slideshow is currently active
---@field slideshow_stale boolean Whether the slideshow is stale (code modified)
---@field current_slide number|nil Current slide index (1-indexed)
---@field total_slides number|nil Total number of slides

---@type VimLeetcodeAIState
local state = {
  layout_open = false,
  ai_terminal_job = nil,
  ai_terminal_buf = nil,
  tool_terminal_job = nil,
  tool_terminal_buf = nil,
  code_buffer = nil,
  code_window = nil,
  tool_window = nil,
  ai_window = nil,
  highlight_ns = vim.api.nvim_create_namespace('vim_leetcode_ai_highlight'),
  slideshow_active = false,
  slideshow_stale = false,
  current_slide = nil,
  total_slides = nil,
}

--- Get the current state
---@return VimLeetcodeAIState
function M.get()
  return state
end

--- Update state fields
---@param updates table Partial state updates
function M.update(updates)
  -- List of valid state keys
  local valid_keys = {
    'layout_open', 'ai_terminal_job', 'ai_terminal_buf',
    'tool_terminal_job', 'tool_terminal_buf', 'code_buffer',
    'code_window', 'tool_window', 'ai_window', 'highlight_ns',
    'slideshow_active', 'slideshow_stale', 'current_slide', 'total_slides',
  }
  local valid_set = {}
  for _, k in ipairs(valid_keys) do
    valid_set[k] = true
  end

  for key, value in pairs(updates) do
    if valid_set[key] then
      state[key] = value
    end
  end
end

--- Reset state to initial values (except namespace)
function M.reset()
  state.layout_open = false
  state.ai_terminal_job = nil
  state.ai_terminal_buf = nil
  state.tool_terminal_job = nil
  state.tool_terminal_buf = nil
  state.code_buffer = nil
  state.code_window = nil
  state.tool_window = nil
  state.ai_window = nil
  state.slideshow_active = false
  state.slideshow_stale = false
  state.current_slide = nil
  state.total_slides = nil
end

return M

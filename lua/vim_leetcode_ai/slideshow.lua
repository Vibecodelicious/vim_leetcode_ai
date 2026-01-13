-- vim_leetcode_ai slideshow module
-- Handles slideshow-related functionality in the plugin

local M = {}

local state = require('vim_leetcode_ai.state')

--- Called by slideshow process when slide changes
---@param current number Current slide index (1-indexed)
---@param total number Total number of slides
function M.on_slide_change(current, total)
  state.update({
    current_slide = current,
    total_slides = total,
  })

  -- Could update statusline or other UI elements here
  -- For now, just store the state
end

--- Get current slideshow position
---@return number|nil current Current slide index
---@return number|nil total Total slides
function M.get_position()
  local s = state.get()
  return s.current_slide, s.total_slides
end

return M

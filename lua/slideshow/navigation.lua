-- slideshow navigation module
-- Handles slide navigation logic and command parsing

local M = {}

--- Navigator class for managing slide navigation
---@class Navigator
---@field slides table[] Array of slides
---@field index number Current slide index (1-indexed)
---@field _at_end boolean Whether we've hit the end
local Navigator = {}
Navigator.__index = Navigator

--- Create a new navigator
---@param slides table[] Array of slides
---@return Navigator
function M.create(slides)
  local nav = setmetatable({}, Navigator)
  nav.slides = slides
  nav.index = 1
  nav._at_end = false
  return nav
end

--- Get current slide index (1-indexed)
---@return number
function Navigator:current_index()
  return self.index
end

--- Get total number of slides
---@return number
function Navigator:total()
  return #self.slides
end

--- Check if at end of slideshow
---@return boolean
function Navigator:at_end()
  return self._at_end
end

--- Get current slide
---@return table slide
function Navigator:current()
  return self.slides[self.index]
end

--- Advance to next slide
---@return table|nil slide The new slide, or nil if at end
function Navigator:next()
  self._at_end = false

  if self.index >= #self.slides then
    self._at_end = true
    return nil
  end

  self.index = self.index + 1
  return self.slides[self.index]
end

--- Go to previous slide
---@return table|nil slide The new slide, or nil if at beginning
function Navigator:prev()
  self._at_end = false

  if self.index <= 1 then
    return nil
  end

  self.index = self.index - 1
  return self.slides[self.index]
end

--- Jump to specific slide
---@param n number Slide number (1-indexed)
---@return table slide The slide at that index
function Navigator:goto_slide(n)
  self._at_end = false

  -- Clamp to valid range
  if n < 1 then
    n = 1
  elseif n > #self.slides then
    n = #self.slides
  end

  self.index = n
  return self.slides[self.index]
end

--- Parse a navigation command from stdin
---@param line string Input line
---@return string|nil command Command name or nil if invalid
---@return number|nil arg Argument for goto command
function M.parse_command(line)
  -- Trim whitespace
  line = line:match('^%s*(.-)%s*$')

  if line == 'next' then
    return 'next', nil
  elseif line == 'prev' then
    return 'prev', nil
  elseif line == 'quit' then
    return 'quit', nil
  else
    -- Check for 'goto N' pattern
    local n = line:match('^goto%s+(%d+)$')
    if n then
      return 'goto', tonumber(n)
    end
  end

  return nil, nil
end

--- Read commands from stdin in a loop
--- This is the main input loop for the slideshow
---@param callback function(cmd: string, arg: number|nil): boolean Callback for each command. Return false to stop.
function M.read_commands(callback)
  while true do
    local line = io.read('*l')
    if not line then
      break -- EOF
    end

    local cmd, arg = M.parse_command(line)
    if cmd then
      local continue = callback(cmd, arg)
      if not continue then
        break
      end
    end
  end
end

return M

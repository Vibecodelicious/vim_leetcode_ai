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

--- Parse a single character command
---@param char string Single character input
---@return string|nil command Command name or nil if invalid
---@return number|nil arg Argument for goto command
function M.parse_char(char)
  if char == 'n' or char == 'j' or char == ' ' then
    return 'next', nil
  elseif char == 'p' or char == 'k' then
    return 'prev', nil
  elseif char == 'q' then
    return 'quit', nil
  elseif char:match('^%d$') then
    return 'goto', tonumber(char)
  end
  return nil, nil
end

--- Parse a navigation command from stdin (for line-based input)
---@param line string Input line
---@return string|nil command Command name or nil if invalid
---@return number|nil arg Argument for goto command
function M.parse_command(line)
  -- Trim whitespace
  line = line:match('^%s*(.-)%s*$')

  if line == 'next' or line == 'n' then
    return 'next', nil
  elseif line == 'prev' or line == 'p' then
    return 'prev', nil
  elseif line == 'quit' or line == 'q' then
    return 'quit', nil
  else
    -- Check for 'goto N' or just a number
    local n = line:match('^goto%s+(%d+)$') or line:match('^(%d+)$')
    if n then
      return 'goto', tonumber(n)
    end
  end

  return nil, nil
end

--- Set terminal to raw mode for single character input
local function set_raw_mode()
  os.execute('stty raw -echo 2>/dev/null')
end

--- Restore terminal to normal mode
local function restore_terminal()
  os.execute('stty cooked echo 2>/dev/null')
end

--- Read single character commands from stdin (blocking version)
--- Uses raw terminal mode for immediate response
---@param callback function(cmd: string, arg: number|nil): boolean Callback for each command. Return false to stop.
function M.read_commands(callback)
  set_raw_mode()

  while true do
    local char = io.read(1)
    if not char then
      break -- EOF
    end

    -- Handle Ctrl-C
    if char == '\003' then
      restore_terminal()
      os.exit(0)
    end

    local cmd, arg = M.parse_char(char)
    if cmd then
      local continue = callback(cmd, arg)
      if not continue then
        break
      end
    end
  end

  restore_terminal()
end

return M

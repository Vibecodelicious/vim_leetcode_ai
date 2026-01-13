-- slideshow TUI module
-- Handles terminal display of slides

local M = {}

--- Clear the terminal screen
function M.clear()
  io.write('\027[2J\027[H')
  io.flush()
end

--- Move cursor to position
---@param row number Row (1-indexed)
---@param col number Column (1-indexed)
function M.move_to(row, col)
  io.write(string.format('\027[%d;%dH', row, col))
  io.flush()
end

--- Render a slide to the terminal
---@param content string Slide content text
---@param current number Current slide index (1-indexed)
---@param total number Total number of slides
---@param at_end boolean Whether we're showing end-of-slideshow indicator
function M.render_slide(content, current, total, at_end)
  M.clear()

  -- Display slide content (convert \n to \r\n for raw mode)
  local formatted_content = content:gsub('\n', '\r\n')
  io.write(formatted_content)
  io.write('\r\n')

  -- Add separator
  io.write('\r\n')
  io.write(string.rep('─', 40))
  io.write('\r\n')

  -- Display navigation indicator
  local indicator
  if at_end then
    indicator = string.format('End of slideshow (%d/%d) | p:back  q:quit', total, total)
  else
    indicator = string.format('Slide %d/%d | n:next  p:prev  q:quit', current, total)
  end
  io.write(indicator)
  io.write('\r\n')

  io.flush()
end

--- Show an error message
---@param message string Error message
function M.show_error(message)
  io.stderr:write('Error: ' .. message .. '\r\n')
end

--- Show end-of-slideshow indicator
---@param current number Current slide index
---@param total number Total slides
function M.show_end_indicator(current, total)
  io.write('\r\n')
  io.write('────────────────────────────────────────\r\n')
  io.write(string.format('  End of slideshow (%d/%d)\r\n', total, total))
  io.write('  p:back  q:quit\r\n')
  io.write('────────────────────────────────────────\r\n')
  io.flush()
end

return M

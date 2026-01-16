#!/usr/bin/env -S nvim -l
-- Animation Template
-- Visual animation with bar charts, colors, and code highlighting
--
-- Usage: nvim -l animation.lua
-- Controls: space/n/j=next, p/k=prev, r=restart, q=quit
--
-- ============================================================================
-- BE CREATIVE! This template shows ONE example (bar chart for sorting).
-- Your visualization should match the algorithm/concept being explained:
--
--   - Sorting algorithms → bar charts with colored comparisons/swaps
--   - Tree traversals → ASCII tree structures with highlighted nodes
--   - Graph algorithms → node/edge diagrams showing visited paths
--   - Linked lists → boxes connected with arrows: [A]→[B]→[C]
--   - Stack/Queue → vertical/horizontal box representations
--   - Binary search → number line with shrinking search range
--   - Dynamic programming → 2D grids/tables filling in
--   - Recursion → call stack visualization
--
-- Use ANSI colors liberally to show state (red=active, green=done, etc.)
-- Use box drawing characters: ┌─┐│└┘├┤┬┴┼ and arrows: ↑↓←→↔
-- Make it VISUAL - if it could be plain text, use a slideshow instead!
--
-- IMPORTANT: Before launching, open the code file with open_file.sh so the
-- user sees code alongside the animation. Each frame's `lines` array syncs
-- highlights to the code - use this to show which lines are executing!
--
-- NOTE: You're not limited to this framework! run_tool.sh can run ANY program.
-- You could write a Python script, a video game, or a fully custom interactive
-- visualization - whatever best explains the concept!
--
-- WARNING: In raw terminal mode, use io.write() NOT print()!
-- print() won't render ANSI codes correctly. Use the write_line() helper below.
-- ============================================================================

-- ANSI color codes (add more as needed)
local RESET = '\027[0m'
local RED = '\027[91m'      -- Active/pivot element
local GREEN = '\027[92m'    -- Sorted/done
local YELLOW = '\027[93m'   -- Comparing
local BLUE = '\027[94m'     -- In range
local CYAN = '\027[96m'     -- Secondary highlight
local MAGENTA = '\027[95m'  -- Tertiary highlight
local GRAY = '\027[90m'     -- Inactive
local BOLD = '\027[1m'

-- Configuration
local CONFIG = {
  title = "Sorting Visualization",  -- Change this!
}

-- ============================================================================
-- HELPER FUNCTIONS - Modify these or write your own for different visuals
-- ============================================================================

-- Example helper: render a bar chart from array with highlighted indices
local function render_bars(arr, highlights)
  highlights = highlights or {}
  local max_val = 0
  for _, v in ipairs(arr) do
    if v > max_val then max_val = v end
  end

  local lines = {}
  local height = 8

  -- Draw bars top to bottom
  for row = height, 1, -1 do
    local line = "  "
    for i, val in ipairs(arr) do
      local bar_height = math.floor((val / max_val) * height)
      local color = highlights[i] or GRAY
      if bar_height >= row then
        line = line .. color .. '██' .. RESET .. ' '
      else
        line = line .. '   '
      end
    end
    table.insert(lines, line)
  end

  -- Draw separator and values
  table.insert(lines, "  " .. string.rep("───", #arr))
  local val_line = "  "
  for _, v in ipairs(arr) do
    val_line = val_line .. string.format("%-3d", v)
  end
  table.insert(lines, val_line)

  return table.concat(lines, "\r\n")
end

-- ============================================================================
-- FRAMES - Each frame has:
--   lines = {line numbers to highlight in code editor}
--   render = function that returns the visual string
--
-- The example below shows a sorting visualization. DELETE IT and create
-- your own frames appropriate to the algorithm you're explaining!
-- ============================================================================
local FRAMES = {
  {
    lines = {1, 2},
    render = function()
      local arr = {64, 25, 12, 22, 11}
      local hl = {[1] = BLUE, [2] = BLUE, [3] = BLUE, [4] = BLUE, [5] = BLUE}
      return "Initial Array\r\n\r\n" .. render_bars(arr, hl) .. "\r\n\r\nStarting selection sort..."
    end
  },
  {
    lines = {4, 5},
    render = function()
      local arr = {64, 25, 12, 22, 11}
      local hl = {[1] = RED, [2] = YELLOW}
      return "Finding Minimum (Pass 1)\r\n\r\n" .. render_bars(arr, hl) .. "\r\n\r\n" ..
             RED .. "██" .. RESET .. " Current min (64)  " ..
             YELLOW .. "██" .. RESET .. " Comparing (25)"
    end
  },
  {
    lines = {4, 5},
    render = function()
      local arr = {64, 25, 12, 22, 11}
      local hl = {[2] = RED, [3] = YELLOW}
      return "Finding Minimum (Pass 1)\r\n\r\n" .. render_bars(arr, hl) .. "\r\n\r\n" ..
             RED .. "██" .. RESET .. " Current min (25)  " ..
             YELLOW .. "██" .. RESET .. " Comparing (12) ← smaller!"
    end
  },
  {
    lines = {4, 5},
    render = function()
      local arr = {64, 25, 12, 22, 11}
      local hl = {[3] = RED, [5] = YELLOW}
      return "Finding Minimum (Pass 1)\r\n\r\n" .. render_bars(arr, hl) .. "\r\n\r\n" ..
             RED .. "██" .. RESET .. " Current min (12)  " ..
             YELLOW .. "██" .. RESET .. " Found 11 ← new minimum!"
    end
  },
  {
    lines = {7, 8},
    render = function()
      local arr = {11, 25, 12, 22, 64}
      local hl = {[1] = GREEN, [5] = GREEN}
      return "After Swap\r\n\r\n" .. render_bars(arr, hl) .. "\r\n\r\n" ..
             GREEN .. "██" .. RESET .. " Swapped: 64 ↔ 11\r\n" ..
             "First element now in final position"
    end
  },
  {
    lines = {3},
    render = function()
      local arr = {11, 12, 22, 25, 64}
      local hl = {[1] = GREEN, [2] = GREEN, [3] = GREEN, [4] = GREEN, [5] = GREEN}
      return "Sorting Complete!\r\n\r\n" .. render_bars(arr, hl) .. "\r\n\r\n" ..
             GREEN .. "All elements sorted" .. RESET
    end
  },
}

-----------------------------------------------------------------------
-- Engine code below - typically don't need to modify
-----------------------------------------------------------------------

-- State
local current_frame = 1

-- Terminal helpers
local function clear_screen()
  io.write('\027[2J\027[H')
end

local function set_raw_mode()
  os.execute('stty raw -echo 2>/dev/null')
end

local function restore_terminal()
  os.execute('stty cooked echo 2>/dev/null')
end

local function write_line(text)
  io.write((text:gsub('\n', '\r\n')))  -- parens discard gsub's second return value (count)
  io.write('\r\n')
end

-- RPC to highlight lines in code editor
local function highlight_lines(lines)
  local nvim_socket = os.getenv('NVIM')
  if not nvim_socket then return end

  local lines_str = '{' .. table.concat(lines, ',') .. '}'
  local cmd = string.format(
    'nvim --server "%s" --remote-send "<Cmd>lua require(\'vim_leetcode_ai.highlight\').set_lines(%s)<CR>" 2>/dev/null',
    nvim_socket, lines_str
  )
  os.execute(cmd)
end

local function clear_highlights()
  local nvim_socket = os.getenv('NVIM')
  if not nvim_socket then return end

  os.execute(string.format(
    'nvim --server "%s" --remote-send "<Cmd>lua require(\'vim_leetcode_ai.highlight\').clear()<CR>" 2>/dev/null',
    nvim_socket
  ))
end

-- Render current frame
local function render()
  clear_screen()

  local frame = FRAMES[current_frame]

  -- Title bar
  io.write('\027[44;37m')  -- Blue background, white text
  write_line(string.format(' %s ', CONFIG.title))
  io.write('\027[0m')  -- Reset
  io.write('\r\n')

  -- Frame content (call the render function)
  write_line(frame.render())

  -- Status bar
  io.write('\027[90m')  -- Gray text
  write_line(string.format('Frame %d/%d', current_frame, #FRAMES))
  write_line('space/n:next  p:prev  r:restart  q:quit')
  io.write('\027[0m')

  io.flush()

  -- Update code highlights
  if frame.lines and #frame.lines > 0 then
    highlight_lines(frame.lines)
  end
end

-- Navigation
local function next_frame()
  if current_frame < #FRAMES then
    current_frame = current_frame + 1
    render()
    return true
  end
  return false
end

local function prev_frame()
  if current_frame > 1 then
    current_frame = current_frame - 1
    render()
  end
end

local function restart()
  current_frame = 1
  render()
end

-- Input handling
local function handle_input(char)
  if char == 'q' then
    return false
  elseif char == ' ' then
    -- Toggle auto-advance (simple version - just go to next)
    next_frame()
  elseif char == 'n' or char == 'j' then
    next_frame()
  elseif char == 'p' or char == 'k' then
    prev_frame()
  elseif char == 'r' then
    restart()
  elseif char == '\003' then  -- Ctrl-C
    return false
  end
  return true
end

-- Main loop (blocking, like slideshow)
local function main()
  set_raw_mode()
  render()

  while true do
    local char = io.read(1)
    if not char then
      break  -- EOF
    end

    if not handle_input(char) then
      break
    end
  end

  clear_highlights()
  restore_terminal()
  clear_screen()
end

main()

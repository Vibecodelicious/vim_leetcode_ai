#!/usr/bin/env -S nvim -l
-- Animation Template
-- A visual animation with play/pause/next/prev controls and code highlighting
--
-- Usage: nvim -l animation.lua
-- Controls: space/n/j=next, p/k=prev, r=restart, q=quit

-- Configuration: Edit these for your animation
local CONFIG = {
  title = "Algorithm Visualization",
}

-- Animation frames: each frame has display content and lines to highlight
-- The display should be VISUAL (use box drawing, colors, ASCII art)
local FRAMES = {
  {
    lines = {1, 2},  -- lines to highlight in code editor
    display = [[
┌─────────────────────────────────┐
│  Step 1: Initialize            │
├─────────────────────────────────┤
│                                 │
│    arr = [3, 1, 4, 1, 5]       │
│            ↑                    │
│           [0]                   │
│                                 │
│    Pointer starts at index 0   │
│                                 │
└─────────────────────────────────┘
]],
  },
  {
    lines = {3, 4},
    display = [[
┌─────────────────────────────────┐
│  Step 2: Compare               │
├─────────────────────────────────┤
│                                 │
│    arr = [3, 1, 4, 1, 5]       │
│            ↑  ↑                 │
│           [0][1]                │
│                                 │
│    Compare: 3 > 1? YES → swap  │
│                                 │
└─────────────────────────────────┘
]],
  },
  {
    lines = {5, 6},
    display = [[
┌─────────────────────────────────┐
│  Step 3: After Swap            │
├─────────────────────────────────┤
│                                 │
│    arr = [1, 3, 4, 1, 5]       │
│               ↑  ↑              │
│              [1][2]             │
│                                 │
│    ✓ Swapped! Now compare next │
│                                 │
└─────────────────────────────────┘
]],
  },
  -- Add more frames...
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
  io.write(text:gsub('\n', '\r\n'))
  io.write('\r\n')
end

-- RPC to highlight lines in code editor
local function highlight_lines(lines)
  local nvim_socket = os.getenv('NVIM')
  if not nvim_socket then return end

  local lines_str = '{' .. table.concat(lines, ',') .. '}'
  local cmd = string.format(
    'nvim --server "%s" --remote-expr "luaeval(\\"require(\'vim_leetcode_ai.highlight\').set_lines(%s)\\")" 2>/dev/null',
    nvim_socket, lines_str
  )
  os.execute(cmd)
end

local function clear_highlights()
  local nvim_socket = os.getenv('NVIM')
  if not nvim_socket then return end

  os.execute(string.format(
    'nvim --server "%s" --remote-expr "luaeval(\\"require(\'vim_leetcode_ai.highlight\').clear()\\")" 2>/dev/null',
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

  -- Frame content
  write_line(frame.display)

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

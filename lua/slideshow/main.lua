#!/usr/bin/env -S nvim -l
-- slideshow main module
-- Entry point for the slideshow program
-- Run with: nvim -l main.lua --data '{"slides":[...]}' or --file path.json

-- Add the lua directory to package.path so modules can be found
-- Get the directory of this script and add parent/lua to path
local script_path = debug.getinfo(1, 'S').source:sub(2)
local script_dir = script_path:match('(.*/)')
if script_dir then
  local lua_dir = script_dir:match('(.*/)lua/slideshow/') or ''
  if lua_dir ~= '' then
    package.path = lua_dir .. 'lua/?.lua;' .. lua_dir .. 'lua/?/init.lua;' .. package.path
  else
    -- Running from within lua/ directory
    local parent = script_dir:match('(.*/)slideshow/') or ''
    if parent ~= '' then
      package.path = parent .. '?.lua;' .. parent .. '?/init.lua;' .. package.path
    end
  end
end

local parser = require('slideshow.parser')
local navigation = require('slideshow.navigation')
local rpc_client = require('slideshow.rpc_client')
local tui = require('slideshow.tui')

--- Parse command line arguments
---@return table|nil options Parsed options or nil on error
---@return string|nil error Error message
local function parse_args()
  local args = arg or {}
  local options = {}

  local i = 1
  while i <= #args do
    local a = args[i]
    if a == '--data' then
      i = i + 1
      options.data = args[i]
    elseif a == '--file' then
      i = i + 1
      options.file = args[i]
    elseif a == '--help' or a == '-h' then
      return nil, 'help'
    end
    i = i + 1
  end

  -- Validate
  if not options.data and not options.file then
    return nil, 'Must provide either --data or --file'
  end

  if options.data and options.file then
    return nil, 'Cannot provide both --data and --file'
  end

  return options, nil
end

--- Print usage help
local function print_help()
  print([[
Usage: nvim -l main.lua [OPTIONS]

Options:
  --data JSON    Slideshow data as JSON string
  --file PATH    Path to JSON file containing slideshow data
  --help, -h     Show this help message

Environment:
  NVIM           Socket path to parent Neovim (set automatically in terminal)

Example:
  nvim -l main.lua --data '{"slides":[{"content":"Hello","lines":[1,2]}]}'
]])
end

--- Main slideshow loop
---@param slideshow table Parsed slideshow data
---@param client table RPC client
local function run_slideshow(slideshow, client)
  local nav = navigation.create(slideshow.slides)

  -- Track stale state locally
  local is_stale = false

  -- Render initial slide
  local slide = nav:current()
  tui.render_slide(slide.content, nav:current_index(), nav:total(), false, false)

  -- Send initial highlights
  client:set_highlights(slide.lines)
  client:notify_slide_change(nav:current_index(), nav:total())

  -- Main loop - read commands from stdin
  navigation.read_commands(function(cmd, cmd_arg)
    if cmd == 'quit' then
      client:clear_highlights()
      return false -- stop loop
    end

    -- Check for stale status before processing command
    if not is_stale then
      is_stale = client:is_stale()
    end

    local new_slide
    local at_end = false

    if cmd == 'next' then
      new_slide = nav:next()
      at_end = nav:at_end()
    elseif cmd == 'prev' then
      new_slide = nav:prev()
      if not new_slide then
        -- Already at beginning, just show current
        new_slide = nav:current()
      end
    elseif cmd == 'goto' and cmd_arg then
      new_slide = nav:goto_slide(cmd_arg)
    end

    if new_slide then
      tui.render_slide(new_slide.content, nav:current_index(), nav:total(), at_end, is_stale)
      client:set_highlights(new_slide.lines)
      client:notify_slide_change(nav:current_index(), nav:total())
    elseif at_end then
      -- At end of slideshow - re-render with end indicator
      local current = nav:current()
      tui.render_slide(current.content, nav:current_index(), nav:total(), true, is_stale)
    end

    return true -- continue loop
  end)
end

--- Cleanup function to delete temp file
---@param file_path string|nil Path to delete
local function cleanup(file_path)
  if file_path then
    os.remove(file_path)
  end
end

--- Main entry point
local function main()
  local file_to_cleanup = nil

  -- Parse arguments
  local options, err = parse_args()
  if err == 'help' then
    print_help()
    os.exit(0)
  end
  if not options then
    tui.show_error(err)
    print_help()
    os.exit(1)
  end

  -- Parse slideshow data
  local slideshow
  if options.data then
    slideshow, err = parser.parse_json(options.data)
  else
    slideshow, err = parser.parse_file(options.file)
    file_to_cleanup = options.file -- Mark for cleanup
  end

  if not slideshow then
    tui.show_error(err)
    cleanup(file_to_cleanup)
    os.exit(2)
  end

  -- Connect to parent Neovim
  local client = rpc_client.create()
  local connected, connect_err = client:connect()
  if not connected then
    tui.show_error(connect_err)
    cleanup(file_to_cleanup)
    os.exit(3)
  end

  -- Run the slideshow (wrapped in pcall for cleanup on error)
  local ok, run_err = pcall(run_slideshow, slideshow, client)
  if not ok then
    tui.show_error('Slideshow error: ' .. tostring(run_err))
  end

  -- Cleanup
  client:disconnect()
  cleanup(file_to_cleanup)
  os.exit(ok and 0 or 4)
end

-- Run if executed as script (not required as module)
if arg then
  main()
end

return {
  parse_args = parse_args,
  run_slideshow = run_slideshow,
}

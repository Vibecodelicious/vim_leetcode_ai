#!/usr/bin/env nvim -l
-- Simple test runner without external dependencies

local plugin_root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h:h')
vim.opt.runtimepath:prepend(plugin_root)

-- Add lua path
local lua_path = plugin_root .. '/lua/?.lua;' .. plugin_root .. '/lua/?/init.lua;'
package.path = lua_path .. package.path

local passed = 0
local failed = 0

local function test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    print('✓ ' .. name)
    passed = passed + 1
  else
    print('✗ ' .. name)
    print('  Error: ' .. tostring(err))
    failed = failed + 1
  end
end

local function assert_eq(a, b, msg)
  if a ~= b then
    error((msg or 'assertion failed') .. ': expected ' .. vim.inspect(b) .. ', got ' .. vim.inspect(a))
  end
end

local function assert_not_nil(v, msg)
  if v == nil then
    error((msg or 'assertion failed') .. ': expected non-nil')
  end
end

local function assert_nil(v, msg)
  if v ~= nil then
    error((msg or 'assertion failed') .. ': expected nil, got ' .. vim.inspect(v))
  end
end

print('\n=== Testing slideshow.parser ===\n')

local parser = require('slideshow.parser')

test('parse_json: valid JSON', function()
  local result, err = parser.parse_json('{"slides":[{"content":"Hello","lines":[1,2]}]}')
  assert_nil(err, 'should not have error')
  assert_not_nil(result, 'should have result')
  assert_eq(#result.slides, 1, 'should have 1 slide')
  assert_eq(result.slides[1].content, 'Hello', 'content should match')
end)

test('parse_json: invalid JSON', function()
  local result, err = parser.parse_json('not json')
  assert_nil(result, 'should not have result')
  assert_not_nil(err, 'should have error')
end)

test('parse_json: missing slides', function()
  local result, err = parser.parse_json('{"foo":"bar"}')
  assert_nil(result, 'should not have result')
  assert_not_nil(err, 'should have error')
end)

test('parse_json: empty slides', function()
  local result, err = parser.parse_json('{"slides":[]}')
  assert_nil(result, 'should not have result')
  assert_not_nil(err, 'should have error')
end)

print('\n=== Testing slideshow.navigation ===\n')

local navigation = require('slideshow.navigation')

test('navigation.create: creates navigator', function()
  local slides = { { content = 'A', lines = {} }, { content = 'B', lines = {} } }
  local nav = navigation.create(slides)
  assert_not_nil(nav, 'should create navigator')
  assert_eq(nav:current_index(), 1, 'should start at 1')
  assert_eq(nav:total(), 2, 'should have 2 slides')
end)

test('navigation.next: advances slide', function()
  local slides = { { content = 'A', lines = {} }, { content = 'B', lines = {} } }
  local nav = navigation.create(slides)
  local slide = nav:next()
  assert_not_nil(slide, 'should return slide')
  assert_eq(nav:current_index(), 2, 'should be at slide 2')
end)

test('navigation.next: at end returns nil', function()
  local slides = { { content = 'A', lines = {} } }
  local nav = navigation.create(slides)
  local slide = nav:next()
  assert_nil(slide, 'should return nil at end')
  assert_eq(nav:at_end(), true, 'should be at end')
end)

test('navigation.prev: goes back', function()
  local slides = { { content = 'A', lines = {} }, { content = 'B', lines = {} } }
  local nav = navigation.create(slides)
  nav:next()
  local slide = nav:prev()
  assert_not_nil(slide, 'should return slide')
  assert_eq(nav:current_index(), 1, 'should be at slide 1')
end)

test('navigation.goto_slide: jumps to slide', function()
  local slides = { { content = 'A', lines = {} }, { content = 'B', lines = {} }, { content = 'C', lines = {} } }
  local nav = navigation.create(slides)
  nav:goto_slide(3)
  assert_eq(nav:current_index(), 3, 'should be at slide 3')
end)

test('navigation.parse_command: parses next', function()
  local cmd, arg = navigation.parse_command('next')
  assert_eq(cmd, 'next', 'should parse next')
  assert_nil(arg, 'should have no arg')
end)

test('navigation.parse_command: parses goto with number', function()
  local cmd, arg = navigation.parse_command('goto 5')
  assert_eq(cmd, 'goto', 'should parse goto')
  assert_eq(arg, 5, 'should parse number')
end)

print('\n=== Testing vim_leetcode_ai.config ===\n')

package.loaded['vim_leetcode_ai.config'] = nil
local config = require('vim_leetcode_ai.config')

test('config.get: returns defaults', function()
  local cfg = config.get()
  assert_not_nil(cfg.ai_command:match('^claude'), 'should have default ai_command starting with claude')
end)

test('config.setup: merges options', function()
  config.setup({ ai_command = 'aider' })
  local cfg = config.get()
  assert_eq(cfg.ai_command, 'aider', 'should override ai_command')
end)

print('\n=== Testing vim_leetcode_ai.highlight ===\n')

package.loaded['vim_leetcode_ai.highlight'] = nil
package.loaded['vim_leetcode_ai.state'] = nil
local highlight = require('vim_leetcode_ai.highlight')
local state = require('vim_leetcode_ai.state')
state.reset()

test('highlight.set_lines: is callable', function()
  assert_not_nil(highlight.set_lines, 'should exist')
end)

test('highlight.clear: is callable', function()
  assert_not_nil(highlight.clear, 'should exist')
end)

test('highlight.scroll_to_highlight_range: is callable', function()
  assert_not_nil(highlight.scroll_to_highlight_range, 'should exist')
end)

test('highlight.mark_stale: updates state', function()
  state.update({ slideshow_stale = false })
  highlight.mark_stale()
  assert_eq(state.get().slideshow_stale, true, 'should be stale')
end)

print('\n=== Testing vim_leetcode_ai.terminal ===\n')

package.loaded['vim_leetcode_ai.terminal'] = nil
package.loaded['vim_leetcode_ai.state'] = nil
local terminal = require('vim_leetcode_ai.terminal')
state = require('vim_leetcode_ai.state')
state.reset()

test('terminal.spawn_ai_agent: is callable', function()
  assert_not_nil(terminal.spawn_ai_agent, 'should exist')
end)

test('terminal.restart: is callable', function()
  assert_not_nil(terminal.restart, 'should exist')
end)

test('terminal.launch_in_tool_pane: is callable', function()
  assert_not_nil(terminal.launch_in_tool_pane, 'should exist')
end)

test('terminal.launch_in_tool_pane: returns nil when layout not open', function()
  state.reset()
  local result = terminal.launch_in_tool_pane('echo test')
  assert_nil(result, 'should return nil when layout closed')
end)

print('\n=== Testing vim_leetcode_ai.layout ===\n')

package.loaded['vim_leetcode_ai.layout'] = nil
package.loaded['vim_leetcode_ai.state'] = nil
local layout = require('vim_leetcode_ai.layout')
state = require('vim_leetcode_ai.state')
state.reset()

test('layout.create: is callable', function()
  assert_not_nil(layout.create, 'should exist')
end)

test('layout.close: is callable', function()
  assert_not_nil(layout.close, 'should exist')
end)

test('layout.restore: is callable', function()
  assert_not_nil(layout.restore, 'should exist')
end)

test('layout.get_tool_pane_size: returns default when no layout', function()
  state.reset()
  local size = layout.get_tool_pane_size()
  assert_not_nil(size.cols, 'should have cols')
  assert_not_nil(size.rows, 'should have rows')
end)

test('layout.get_code_buffer_info: returns default when no buffer', function()
  state.reset()
  local info = layout.get_code_buffer_info()
  assert_eq(info.lines, 0, 'should have 0 lines')
  assert_eq(info.path, '', 'should have empty path')
end)

print('\n=== Testing vim_leetcode_ai.init ===\n')

package.loaded['vim_leetcode_ai'] = nil
package.loaded['vim_leetcode_ai.state'] = nil
local init = require('vim_leetcode_ai')
state = require('vim_leetcode_ai.state')
state.reset()

test('init.setup: is callable', function()
  assert_not_nil(init.setup, 'should exist')
end)

test('init.open: is callable', function()
  assert_not_nil(init.open, 'should exist')
end)

test('init.close: is callable', function()
  assert_not_nil(init.close, 'should exist')
end)

test('init.restart: is callable', function()
  assert_not_nil(init.restart, 'should exist')
end)

print('\n=== Summary ===\n')
print(string.format('Passed: %d, Failed: %d', passed, failed))

if failed > 0 then
  os.exit(1)
else
  os.exit(0)
end

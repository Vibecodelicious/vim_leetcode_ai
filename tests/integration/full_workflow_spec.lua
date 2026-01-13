-- Integration test for full workflow
-- Tests the complete user journey from opening to closing

-- Note: This test requires a full Neovim instance and cannot run headless
-- Run with: nvim -l tests/integration/full_workflow_spec.lua

local plugin_root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h:h:h')
vim.opt.runtimepath:prepend(plugin_root)

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

local function assert_true(v, msg)
  if not v then
    error((msg or 'assertion failed') .. ': expected true')
  end
end

print('\n=== Integration Tests: Full Workflow ===\n')

-- Reset modules for clean test
for key in pairs(package.loaded) do
  if key:match('^vim_leetcode_ai') or key:match('^slideshow') then
    package.loaded[key] = nil
  end
end

local init = require('vim_leetcode_ai')
local state = require('vim_leetcode_ai.state')
local config = require('vim_leetcode_ai.config')

-- Setup with test config
config.setup({
  ai_command = 'echo "Test AI"',
})

test('Workflow: Initial state is closed', function()
  assert_eq(state.get().layout_open, false, 'layout should be closed')
end)

test('Workflow: Module functions exist', function()
  assert_true(type(init.setup) == 'function', 'setup exists')
  assert_true(type(init.open) == 'function', 'open exists')
  assert_true(type(init.close) == 'function', 'close exists')
  assert_true(type(init.restart) == 'function', 'restart exists')
end)

test('Workflow: Config is accessible', function()
  local cfg = config.get()
  assert_eq(cfg.ai_command, 'echo "Test AI"', 'ai_command set correctly')
  assert_true(cfg.keys.next_slide == ']s', 'next_slide key set')
  assert_true(cfg.keys.prev_slide == '[s', 'prev_slide key set')
end)

test('Workflow: Highlight module initializes', function()
  local highlight = require('vim_leetcode_ai.highlight')
  assert_true(type(highlight.set_lines) == 'function', 'set_lines exists')
  assert_true(type(highlight.clear) == 'function', 'clear exists')
end)

test('Workflow: Slideshow parser works', function()
  local parser = require('slideshow.parser')
  local data, err = parser.parse_json('{"slides":[{"content":"Test","lines":[1]}]}')
  assert_true(data ~= nil, 'parser returns data')
  assert_true(err == nil, 'parser has no error')
  assert_eq(#data.slides, 1, 'one slide parsed')
end)

test('Workflow: Slideshow navigation works', function()
  local navigation = require('slideshow.navigation')
  local slides = {
    { content = 'Slide 1', lines = { 1 } },
    { content = 'Slide 2', lines = { 2, 3 } },
  }
  local nav = navigation.create(slides)
  assert_eq(nav:current_index(), 1, 'starts at 1')
  nav:next()
  assert_eq(nav:current_index(), 2, 'advanced to 2')
  nav:prev()
  assert_eq(nav:current_index(), 1, 'back to 1')
end)

print('\n=== Summary ===\n')
print(string.format('Passed: %d, Failed: %d', passed, failed))

if failed > 0 then
  os.exit(1)
else
  print('\nAll integration tests passed!')
  os.exit(0)
end

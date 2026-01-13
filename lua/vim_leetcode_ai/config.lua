-- vim_leetcode_ai configuration module

local M = {}

-- Find the plugin directory from this file's location
local function get_plugin_dir()
  local source = debug.getinfo(1, 'S').source:sub(2) -- Remove leading @
  -- Get absolute path and go up 3 levels: config.lua -> vim_leetcode_ai -> lua -> plugin_root
  local abs_path = vim.fn.fnamemodify(source, ':p:h:h:h')
  return abs_path .. '/'
end

local plugin_dir = get_plugin_dir()

-- Create a temp directory for slideshow files
-- vim.fn.tempname() returns a path like /tmp/nvimXXXXXX/0, we use its directory
local temp_file = vim.fn.tempname()
local temp_dir = vim.fn.fnamemodify(temp_file, ':h')

---@class VimLeetcodeAIConfig
---@field ai_command string Command to run the AI agent
---@field keys table Keybinding configuration
---@field layout table Layout proportion configuration

-- System prompt for Claude when running in the vim terminal
local system_prompt = [[You are running inside a Neovim terminal (vim_leetcode_ai plugin) to help the user with code.

## Plugin Scripts (use these absolute paths)
- ]] .. plugin_dir .. [[scripts/get_code_file.sh - Get code buffer contents with line numbers
- ]] .. plugin_dir .. [[scripts/open_file.sh <path> - Open file in code pane
- ]] .. plugin_dir .. [[scripts/launch_slideshow.sh --stdin - Launch slideshow (pipe JSON to it)
- ]] .. plugin_dir .. [[scripts/run_tool.sh <cmd> [args] - Run any program in tool pane

## CRITICAL RULES
- NEVER use vim/nvim directly to open files - use open_file.sh
- NEVER use os.system('clear') in tools - use print('\033[2J\033[H', end='')
- Use \r\n for line breaks in tool pane (raw terminal mode)

## Slideshow (text explanations with code highlighting)
Pipe JSON to launch_slideshow.sh --stdin:
  {"slides":[{"content":"Explanation text","lines":[1,2,3]}]}

## Visual Animations (diagrams, ASCII art, box drawing)
For VISUAL animations (not just text), copy and modify the template:
  cp ]] .. plugin_dir .. [[templates/animation.lua ]] .. temp_dir .. [[/anim.lua
Then edit FRAMES array with your visuals (use box drawing: ┌─┐│└─┘, arrows: ↑↓←→, colors via ANSI)
Launch with: ]] .. plugin_dir .. [[scripts/run_tool.sh nvim -l ]] .. temp_dir .. [[/anim.lua
Controls: space/n=next, p=prev, r=restart, q=quit

## Highlighting Code (for custom tools)
  nvim --server "$NVIM" --remote-expr "luaeval(\"require('vim_leetcode_ai.highlight').set_lines({5,6,7})\")"

## Temp Directory: ]] .. temp_dir .. [[

## More Details: ]] .. plugin_dir .. [[skills/]]

local defaults = {
  -- Command to run the AI agent (required)
  ai_command = 'claude --system-prompt ' .. vim.fn.shellescape(system_prompt) .. ' --add-dir ' .. vim.fn.shellescape(temp_dir),

  -- Keybindings
  keys = {
    open = '<leader>ai',
    close = '<leader>aq',
    next_slide = ']s',
    prev_slide = '[s',
  },

  -- Layout proportions
  layout = {
    tool_width = 0.5,      -- Tool pane width as fraction of top area
    bottom_height = 0.3,   -- AI terminal height as fraction of window
  },
}

---@type VimLeetcodeAIConfig
local current_config = vim.deepcopy(defaults)

--- Setup configuration with user options
---@param opts table|nil User configuration options
function M.setup(opts)
  current_config = vim.tbl_deep_extend('force', defaults, opts or {})
end

--- Get the current configuration
---@return VimLeetcodeAIConfig
function M.get()
  return current_config
end

return M

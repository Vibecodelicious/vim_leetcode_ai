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

Skills available:
- ]] .. plugin_dir .. [[skills/slideshow.md - Generate explanatory slideshows with synchronized line highlighting
- ]] .. plugin_dir .. [[skills/run_tool.md - Run custom programs in the tool pane (visualizations, animations, etc.)

Plugin scripts (use absolute paths):
- ]] .. plugin_dir .. [[scripts/get_code_file.sh - Get the code buffer contents
- ]] .. plugin_dir .. [[scripts/launch_slideshow.sh <file> - Launch a slideshow
- ]] .. plugin_dir .. [[scripts/run_tool.sh <command> [args...] - Run any program in the tool pane

The tool pane is a terminal window that displays alongside the code editor. You can run any interactive program there - custom visualizations, animations, or other tools. The program will have access to $NVIM for RPC communication back to Neovim.

Temp directory for files: ]] .. temp_dir .. [[
Write temporary files there (e.g., ]] .. temp_dir .. [[/slideshow.json)]]

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

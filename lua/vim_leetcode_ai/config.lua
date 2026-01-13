-- vim_leetcode_ai configuration module

local M = {}

-- Find the plugin directory from this file's location
local function get_plugin_dir()
  local source = debug.getinfo(1, 'S').source:sub(2) -- Remove leading @
  -- source is .../lua/vim_leetcode_ai/config.lua, we want ...
  return source:match('(.*/)[^/]+/[^/]+/[^/]+$') or '.'
end

local plugin_dir = get_plugin_dir()

---@class VimLeetcodeAIConfig
---@field ai_command string Command to run the AI agent
---@field keys table Keybinding configuration
---@field layout table Layout proportion configuration

-- System prompt for Claude when running in the vim terminal
local system_prompt = [[You are running inside a Neovim terminal (vim_leetcode_ai plugin) to help the user with code.

There is a slideshow skill at ]] .. plugin_dir .. [[skills/slideshow.md that you can use for generating explanatory slideshows with synchronized line highlighting in the user's code editor.]]

local defaults = {
  -- Command to run the AI agent (required)
  ai_command = 'claude --system-prompt ' .. vim.fn.shellescape(system_prompt),

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

-- vim_leetcode_ai configuration module

local M = {}

---@class VimLeetcodeAIConfig
---@field ai_command string Command to run the AI agent
---@field keys table Keybinding configuration
---@field layout table Layout proportion configuration
-- System prompt for Claude when running in the vim terminal
local system_prompt = [[You are running inside a Neovim terminal (vim_leetcode_ai plugin) to help the user with code.

You have access to a /slideshow skill that creates interactive presentations with synchronized line highlighting in the user's code editor. Use it when explaining code, debugging issues, or walking through algorithms step-by-step.

Scripts available:
- ./scripts/get_code_file.sh - Get the contents of the user's code buffer
- ./scripts/launch_slideshow.sh <json-file> - Launch a slideshow]]

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

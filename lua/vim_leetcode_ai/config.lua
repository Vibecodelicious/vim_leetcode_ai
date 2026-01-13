-- vim_leetcode_ai configuration module

local M = {}

---@class VimLeetcodeAIConfig
---@field ai_command string Command to run the AI agent
---@field keys table Keybinding configuration
---@field layout table Layout proportion configuration
local defaults = {
  -- Command to run the AI agent (required)
  ai_command = 'claude',

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

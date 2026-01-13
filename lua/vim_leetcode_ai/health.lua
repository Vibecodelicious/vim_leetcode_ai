-- vim_leetcode_ai health check module
-- Used by :checkhealth vim_leetcode_ai

local M = {}

--- Check if a command is available
---@param cmd string Command name
---@return boolean
local function command_exists(cmd)
  return vim.fn.executable(cmd) == 1
end

--- Run health checks for the plugin
function M.check()
  vim.health.start('vim_leetcode_ai')

  -- Check Neovim version
  local nvim_version = vim.version()
  if nvim_version.major > 0 or (nvim_version.major == 0 and nvim_version.minor >= 9) then
    vim.health.ok(string.format('Neovim version %d.%d.%d (>= 0.9 required)', nvim_version.major, nvim_version.minor, nvim_version.patch))
  else
    vim.health.error(
      string.format('Neovim version %d.%d.%d is too old', nvim_version.major, nvim_version.minor, nvim_version.patch),
      { 'Upgrade to Neovim 0.9 or later' }
    )
  end

  -- Check for AI command
  local config = require('vim_leetcode_ai.config')
  local cfg = config.get()
  local ai_cmd = cfg.ai_command:match('^(%S+)')

  if command_exists(ai_cmd) then
    vim.health.ok('AI command found: ' .. ai_cmd)
  else
    vim.health.warn('AI command not found: ' .. ai_cmd, {
      'Install ' .. ai_cmd .. ' or configure a different ai_command',
      "Example: require('vim_leetcode_ai').setup({ ai_command = 'your-command' })",
    })
  end

  -- Check plugin modules can be loaded
  local modules = {
    'vim_leetcode_ai.config',
    'vim_leetcode_ai.state',
    'vim_leetcode_ai.layout',
    'vim_leetcode_ai.terminal',
    'vim_leetcode_ai.highlight',
    'vim_leetcode_ai.keybindings',
  }

  local all_modules_ok = true
  for _, mod in ipairs(modules) do
    local ok, err = pcall(require, mod)
    if ok then
      vim.health.ok('Module loaded: ' .. mod)
    else
      vim.health.error('Failed to load module: ' .. mod, { tostring(err) })
      all_modules_ok = false
    end
  end

  -- Check slideshow modules
  local slideshow_modules = {
    'slideshow.parser',
    'slideshow.navigation',
    'slideshow.rpc_client',
    'slideshow.tui',
    'slideshow.main',
    'slideshow.query',
  }

  for _, mod in ipairs(slideshow_modules) do
    local ok, err = pcall(require, mod)
    if ok then
      vim.health.ok('Slideshow module loaded: ' .. mod)
    else
      vim.health.warn('Failed to load slideshow module: ' .. mod, {
        'This may affect slideshow functionality',
        'Error: ' .. tostring(err),
      })
    end
  end

  -- Check current state
  local state = require('vim_leetcode_ai.state')
  local s = state.get()
  if s.layout_open then
    vim.health.info('Layout is currently open')
  else
    vim.health.info('Layout is currently closed')
  end
end

return M

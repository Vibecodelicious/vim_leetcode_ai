-- slideshow RPC client module
-- Handles communication with parent Neovim instance

local M = {}

--- RPC client state
---@class RpcClient
---@field channel number|nil RPC channel ID
local RpcClient = {}
RpcClient.__index = RpcClient

--- Create a new RPC client
---@return RpcClient
function M.create()
  local client = setmetatable({}, RpcClient)
  client.channel = nil
  return client
end

--- Connect to parent Neovim via $NVIM socket
---@return boolean success
---@return string|nil error
function RpcClient:connect()
  local nvim_socket = os.getenv('NVIM')
  if not nvim_socket then
    return false, 'NVIM environment variable not set'
  end

  local ok, channel = pcall(vim.fn.sockconnect, 'pipe', nvim_socket, { rpc = true })
  if not ok or channel == 0 then
    return false, 'Failed to connect to Neovim socket: ' .. nvim_socket
  end

  self.channel = channel
  return true, nil
end

--- Disconnect from parent Neovim
function RpcClient:disconnect()
  if self.channel then
    pcall(vim.fn.chanclose, self.channel)
    self.channel = nil
  end
end

--- Check if connected
---@return boolean
function RpcClient:is_connected()
  return self.channel ~= nil
end

--- Send highlight update to parent Neovim
---@param lines number[] Array of 1-indexed line numbers to highlight
function RpcClient:set_highlights(lines)
  if not self.channel then
    return
  end

  pcall(vim.rpcnotify, self.channel, 'nvim_exec_lua', [[require('vim_leetcode_ai.highlight').set_lines(...)]], { lines })
end

--- Clear highlights in parent Neovim
function RpcClient:clear_highlights()
  if not self.channel then
    return
  end

  pcall(vim.rpcnotify, self.channel, 'nvim_exec_lua', [[require('vim_leetcode_ai.highlight').clear()]], {})
end

--- Notify parent of slide change
---@param current number Current slide index (1-indexed)
---@param total number Total number of slides
function RpcClient:notify_slide_change(current, total)
  if not self.channel then
    return
  end

  pcall(
    vim.rpcnotify,
    self.channel,
    'nvim_exec_lua',
    [[require('vim_leetcode_ai.slideshow').on_slide_change(...)]],
    { current, total }
  )
end

--- Check if parent indicates stale status
---@return boolean stale True if tool is marked as stale
function RpcClient:is_stale()
  if not self.channel then
    return false
  end

  local ok, result = pcall(
    vim.rpcrequest,
    self.channel,
    'nvim_exec_lua',
    [[return require('vim_leetcode_ai.state').get().tool_stale]],
    {}
  )

  if ok then
    return result == true
  end
  return false
end

return M

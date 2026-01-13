#!/usr/bin/env -S nvim -l
-- slideshow query module
-- Query Neovim for information like window size, code buffer info
-- Run with: nvim -l query.lua [query-type]

--- Print usage help
local function print_help()
  print([[
Usage: nvim -l query.lua [QUERY]

Queries:
  window-size    Get tool output pane dimensions
  code-buffer    Get code buffer info (lines, path)

Environment:
  NVIM           Socket path to parent Neovim (set automatically in terminal)

Output:
  JSON object with query results

Exit Codes:
  0    Success
  1    Unknown query
  2    Failed to connect to Neovim RPC
]])
end

--- Connect to parent Neovim
---@return number|nil channel
---@return string|nil error
local function connect()
  local nvim_socket = os.getenv('NVIM')
  if not nvim_socket then
    return nil, 'NVIM environment variable not set'
  end

  local ok, channel = pcall(vim.fn.sockconnect, 'pipe', nvim_socket, { rpc = true })
  if not ok or channel == 0 then
    return nil, 'Failed to connect to Neovim socket: ' .. nvim_socket
  end

  return channel, nil
end

--- Query window size
---@param channel number RPC channel
---@return table {cols, rows}
local function query_window_size(channel)
  local ok, result =
    pcall(vim.rpcrequest, channel, 'nvim_exec_lua', [[return require('vim_leetcode_ai.layout').get_tool_pane_size()]], {})
  if ok and result then
    return result
  end
  return { cols = 80, rows = 24 }
end

--- Query code buffer info
---@param channel number RPC channel
---@return table {lines, path}
local function query_code_buffer(channel)
  local ok, result =
    pcall(vim.rpcrequest, channel, 'nvim_exec_lua', [[return require('vim_leetcode_ai.layout').get_code_buffer_info()]], {})
  if ok and result then
    return result
  end
  return { lines = 0, path = '' }
end

--- Main entry point
local function main()
  local args = arg or {}

  if #args == 0 or args[1] == '--help' or args[1] == '-h' then
    print_help()
    os.exit(0)
  end

  local query = args[1]

  -- Connect to Neovim
  local channel, err = connect()
  if not channel then
    io.stderr:write('Error: ' .. err .. '\n')
    os.exit(2)
  end

  -- Execute query
  local result
  if query == 'window-size' then
    result = query_window_size(channel)
  elseif query == 'code-buffer' then
    result = query_code_buffer(channel)
  else
    io.stderr:write('Error: Unknown query: ' .. query .. '\n')
    print_help()
    vim.fn.chanclose(channel)
    os.exit(1)
  end

  -- Output as JSON
  print(vim.json.encode(result))

  -- Cleanup
  vim.fn.chanclose(channel)
  os.exit(0)
end

-- Run if executed as script
if arg then
  main()
end

return {
  query_window_size = query_window_size,
  query_code_buffer = query_code_buffer,
}

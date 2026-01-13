# RPC Contracts

Communication between the slideshow process and the parent Neovim instance uses Neovim's built-in RPC over the `$NVIM` socket.

## Slideshow → Neovim

### Set Highlights

Updates line highlighting in the code editor.

**Method**: `nvim_exec_lua`

**Lua code**: `require('vim_leetcode_ai.highlight').set_lines(...)`

**Arguments**: `[lines]` where `lines` is an array of 1-indexed line numbers

**Example**:
```lua
vim.rpcnotify(channel, 'nvim_exec_lua',
  [[require('vim_leetcode_ai.highlight').set_lines(...)]],
  {{5, 6, 7, 8}})
```

**Behavior**:
- Clears existing highlights
- Highlights specified lines with full-line background
- Scrolls code editor to show highlighted lines if outside viewport
- If `lines` is empty, just clears highlights

---

### Clear Highlights

Removes all line highlighting.

**Method**: `nvim_exec_lua`

**Lua code**: `require('vim_leetcode_ai.highlight').clear()`

**Arguments**: none

**Example**:
```lua
vim.rpcnotify(channel, 'nvim_exec_lua',
  [[require('vim_leetcode_ai.highlight').clear()]],
  {})
```

---

### Notify Slide Change

Informs the plugin of current slide (for status line, etc.).

**Method**: `nvim_exec_lua`

**Lua code**: `require('vim_leetcode_ai.slideshow').on_slide_change(...)`

**Arguments**: `[current, total]` where both are 1-indexed integers

**Example**:
```lua
vim.rpcnotify(channel, 'nvim_exec_lua',
  [[require('vim_leetcode_ai.slideshow').on_slide_change(...)]],
  {2, 5})  -- Slide 2 of 5
```

---

## Neovim → Slideshow

Communication from Neovim to the slideshow uses `chansend()` to write to the terminal's stdin.

### Navigation Commands

Sent via `vim.fn.chansend(job_id, command .. "\n")`

| Command | Description |
|---------|-------------|
| `next\n` | Go to next slide |
| `prev\n` | Go to previous slide |
| `goto N\n` | Go to slide N |
| `quit\n` | Exit slideshow |

**Example** (in plugin code):
```lua
local function next_slide()
  local job_id = state.tool_terminal_job
  if job_id then
    vim.fn.chansend(job_id, "next\n")
  end
end
```

---

## Query RPC

For the query command to get information from Neovim.

### Get Window Size

**Method**: `nvim_exec_lua`

**Lua code**: `return require('vim_leetcode_ai.layout').get_tool_pane_size()`

**Returns**: `{cols = N, rows = N}`

**Example**:
```lua
local channel = vim.fn.sockconnect('pipe', os.getenv('NVIM'), {rpc = true})
local size = vim.rpcrequest(channel, 'nvim_exec_lua',
  [[return require('vim_leetcode_ai.layout').get_tool_pane_size()]],
  {})
print(vim.json.encode(size))
```

---

### Get Code Buffer Info

**Method**: `nvim_exec_lua`

**Lua code**: `return require('vim_leetcode_ai.layout').get_code_buffer_info()`

**Returns**: `{lines = N, path = "filename"}`

**Example**:
```lua
local info = vim.rpcrequest(channel, 'nvim_exec_lua',
  [[return require('vim_leetcode_ai.layout').get_code_buffer_info()]],
  {})
print(vim.json.encode(info))
```

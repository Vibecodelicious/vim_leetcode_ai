# Run Tool

Run custom programs in the tool pane for visualizations, animations, or interactive tools.

## Visual Animation Template

For visual animations (diagrams, ASCII art, box drawing), use the Lua template:

```bash
# Copy template to temp directory
cp /path/to/plugin/templates/animation.lua /tmp/nvimXXXX/anim.lua

# Edit the FRAMES array with your visual content
# Then launch:
./scripts/run_tool.sh nvim -l /tmp/nvimXXXX/anim.lua
```

The template provides:
- Play/pause with spacebar
- Next/prev with n/p keys
- Code line highlighting synced to frames
- Proper terminal handling

## How to Launch Custom Tools

```bash
./scripts/run_tool.sh <command> [args...]
```

The command runs in the tool pane with access to `$NVIM` for RPC communication back to Neovim.

## Tips for Custom Lua Tools

### Clearing the Screen

Don't use `os.execute('clear')` - it doesn't work reliably. Use ANSI escape codes:

```lua
io.write('\027[2J\027[H')
io.flush()
```

### Line Breaks in Raw Mode

Use `\r\n` instead of just `\n`:

```lua
io.write('Line 1\r\nLine 2\r\n')
```

### Colors via ANSI

```lua
io.write('\027[44;37m')  -- Blue background, white text
io.write(' Title ')
io.write('\027[0m')      -- Reset
io.write('\027[90m')     -- Gray text
io.write('Subtitle')
io.write('\027[0m')
```

### RPC Communication

Your tool has access to `$NVIM` socket for communicating with the parent Neovim:

```bash
# Query something from Neovim
nvim --server "$NVIM" --remote-expr "line('.')"

# Execute Lua in parent Neovim
nvim --server "$NVIM" --remote-expr "luaeval('vim.fn.expand(\"%:p\")')"
```

### Highlighting Code Lines

Custom tools can highlight lines in the code editor - useful for stepping through code:

```lua
-- Highlight specific lines (1-indexed)
local function highlight_lines(lines)
  local nvim_socket = os.getenv('NVIM')
  if not nvim_socket then return end

  local lines_str = '{' .. table.concat(lines, ',') .. '}'
  os.execute(string.format(
    'nvim --server "%s" --remote-expr "luaeval(\\"require(\'vim_leetcode_ai.highlight\').set_lines(%s)\\")" 2>/dev/null',
    nvim_socket, lines_str
  ))
end

-- Clear all highlights
local function clear_highlights()
  local nvim_socket = os.getenv('NVIM')
  if not nvim_socket then return end

  os.execute(string.format(
    'nvim --server "%s" --remote-expr "luaeval(\\"require(\'vim_leetcode_ai.highlight\').clear()\\")" 2>/dev/null',
    nvim_socket
  ))
end

-- Usage
highlight_lines({5, 6, 7})
clear_highlights()
```

## When to Use

- Custom visualizations beyond slideshows
- Interactive debugging tools
- Animations or progress displays
- Any tool that needs to display alongside the code editor

# Run Tool

Run custom programs in the tool pane for visualizations, animations, or interactive tools.

## How to Launch

```bash
./scripts/run_tool.sh <command> [args...]
```

The command runs in the tool pane with access to `$NVIM` for RPC communication back to Neovim.

## Examples

```bash
# Run a Python visualization
./scripts/run_tool.sh python /tmp/nvimXXXX/visualization.py

# Run a custom Lua script
./scripts/run_tool.sh nvim -l /tmp/nvimXXXX/tool.lua

# Run any interactive program
./scripts/run_tool.sh ./my_tool --arg value
```

## Tips for Custom Tools

### Clearing the Screen

Don't use `os.system('clear')` - it doesn't work reliably in all terminal contexts.

Use ANSI escape codes directly:

**Python:**
```python
print('\033[2J\033[H', end='')
sys.stdout.flush()
```

**Lua:**
```lua
io.write('\027[2J\027[H')
io.flush()
```

**Bash:**
```bash
printf '\033[2J\033[H'
```

### Line Breaks in Raw Mode

If the tool pane uses raw terminal mode, use `\r\n` instead of just `\n`:

```python
print('Line 1\r\nLine 2\r\n')
```

### RPC Communication

Your tool has access to `$NVIM` socket for communicating with the parent Neovim:

```bash
# Query something from Neovim
nvim --server "$NVIM" --remote-expr "line('.')"

# Execute Lua in parent Neovim
nvim --server "$NVIM" --remote-expr "luaeval('vim.fn.expand(\"%:p\")')"
```

## When to Use

- Custom visualizations beyond slideshows
- Interactive debugging tools
- Animations or progress displays
- Any tool that needs to display alongside the code editor

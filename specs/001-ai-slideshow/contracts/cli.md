# CLI Contracts

## Slideshow Program

**Invocation**: `nvim -l <plugin-path>/lua/slideshow/main.lua [options]`

### Options

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `--data` | JSON string | Yes* | Slideshow data as JSON |
| `--file` | path | Yes* | Path to JSON file containing slideshow data |

*One of `--data` or `--file` must be provided.

### Environment Variables

| Variable | Description |
|----------|-------------|
| `NVIM` | Socket path to parent Neovim instance (set automatically by Neovim terminal) |

### Examples

```bash
# Inline JSON data
nvim -l ~/.local/share/nvim/lazy/vim_leetcode_ai/lua/slideshow/main.lua \
  --data '{"slides":[{"content":"Step 1...","lines":[5,6,7]}]}'

# From file
nvim -l ~/.local/share/nvim/lazy/vim_leetcode_ai/lua/slideshow/main.lua \
  --file /tmp/slideshow.json
```

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Normal exit (user quit or end of slides) |
| 1 | Invalid arguments |
| 2 | Failed to parse slideshow data |
| 3 | Failed to connect to Neovim RPC |

---

## Query Command

**Invocation**: `nvim -l <plugin-path>/lua/slideshow/query.lua [query]`

### Queries

| Query | Output | Description |
|-------|--------|-------------|
| `window-size` | `{"cols": N, "rows": N}` | Tool output pane dimensions |
| `code-buffer` | `{"lines": N, "path": "..."}` | Code buffer info |

### Examples

```bash
# Get window size
nvim -l ~/.local/share/nvim/lazy/vim_leetcode_ai/lua/slideshow/query.lua window-size
# Output: {"cols": 80, "rows": 24}

# Get code buffer info
nvim -l ~/.local/share/nvim/lazy/vim_leetcode_ai/lua/slideshow/query.lua code-buffer
# Output: {"lines": 45, "path": "1.two_sum.cpp"}
```

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Unknown query |
| 2 | Failed to connect to Neovim RPC |

---

## Navigation Protocol (stdin)

The slideshow program reads line-based commands from stdin.

### Commands

| Command | Description |
|---------|-------------|
| `next` | Advance to next slide |
| `prev` | Go back to previous slide |
| `goto N` | Jump to slide N (1-indexed) |
| `quit` | Exit the slideshow |

### Behavior

- Commands are newline-terminated
- Unknown commands are ignored
- Navigation beyond bounds wraps or clamps (TBD based on UX preference)
- `quit` causes clean exit with code 0

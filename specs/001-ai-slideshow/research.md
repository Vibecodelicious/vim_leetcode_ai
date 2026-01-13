# Research: AI Slideshow Assistant

## Decisions

### 1. Slideshow TUI Approach

**Decision**: Plain text buffer with minimal ANSI (clear screen, cursor home)

**Rationale**: The LLM generates slide content including any formatting it wants (ASCII art, box drawings, etc.). The slideshow program just displays text and handles navigation. This is the simplest approach that works.

**Alternatives considered**:
- Lua TUI library (plterm, lua-tui) - Adds complexity, limited ecosystem
- Full ANSI rendering with box-drawing - We'd be reimplementing what the LLM can do itself
- Rich text/markdown rendering - Over-engineering for the use case

### 2. Neovim RPC Communication

**Decision**: Use `vim.fn.sockconnect()` from the slideshow to connect to parent Neovim via `$NVIM` socket

**Rationale**: When Neovim spawns a terminal, it sets `$NVIM` environment variable pointing to its RPC socket. The slideshow (running via `nvim -l`) can connect back using:

```lua
local channel = vim.fn.sockconnect('pipe', os.getenv('NVIM'), { rpc = true })
vim.rpcnotify(channel, 'nvim_exec_lua', [[require('vim_leetcode_ai.highlight').set_lines(...)]], {lines})
```

**Alternatives considered**:
- TCP socket - Requires port management, firewall considerations
- File-based communication - Polling is inefficient
- Custom IPC - Reinventing the wheel

### 3. Slideshow Data Format

**Decision**: JSON passed via command-line argument or stdin

**Rationale**: Simple, universal, easy for AI to generate. Structure:

```json
{
  "slides": [
    {
      "content": "Step 1: Initialize the hashmap\n\nWe create an empty hashmap...",
      "lines": [5, 6, 7]
    },
    {
      "content": "Step 2: Iterate through the array...",
      "lines": [9, 10, 11, 12]
    }
  ]
}
```

**Alternatives considered**:
- YAML - Requires parser, multi-line strings are awkward in CLI args
- Custom format - No benefit over JSON
- Lua table literal - Harder for AI to generate correctly

### 4. Navigation Command Protocol

**Decision**: Line-based commands on stdin

**Rationale**: Simple text protocol that works with `chansend()`:

- `next` - Go to next slide
- `prev` - Go to previous slide
- `goto N` - Go to slide N (1-indexed)
- `quit` - Exit slideshow

**Alternatives considered**:
- Single-character commands - Harder to extend, ambiguous
- JSON commands - Over-engineering for simple nav

### 5. Plugin Language

**Decision**: Lua (Neovim-native)

**Rationale**: Best performance, full API access, no runtime dependency beyond Neovim itself.

**Alternatives considered**:
- Vimscript - More verbose, slower, less capable
- Remote plugin (Python/Node) - Adds runtime dependency

### 6. Testing Framework

**Decision**: busted + plenary.nvim

**Rationale**:
- busted: Standard Lua testing, works for pure Lua modules (slideshow logic)
- plenary.nvim: Neovim-specific testing, works for plugin code that needs `vim.*` APIs

**Alternatives considered**:
- vusted - Less common, similar to busted
- Manual testing only - Violates constitution (Testing Standards)

## Open Questions (Resolved)

| Question | Resolution |
|----------|------------|
| How to render slideshow TUI? | Plain text, LLM provides formatting |
| How does slideshow talk to Neovim? | `$NVIM` socket + `vim.fn.sockconnect()` |
| What format for slide data? | JSON via CLI arg or stdin |
| Vim compatibility? | Dropped; Neovim 0.9+ only |

## References

- [Neovim Lua Guide](https://neovim.io/doc/user/lua-guide.html)
- [Neovim `-l` flag discussion](https://github.com/neovim/neovim/issues/15749)
- [Neovim RPC API](https://neovim.io/doc/user/api.html)
- [plterm - Pure Lua ANSI Terminal](https://github.com/philanc/plterm)

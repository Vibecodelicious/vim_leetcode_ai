# Quickstart: vim_leetcode_ai

## Prerequisites

- Neovim 0.9+
- [leetcode.vim](https://github.com/ianding1/leetcode.vim) installed and configured
- An AI coding agent installed (e.g., Claude Code, Aider)

## Installation

Using lazy.nvim:

```lua
{
  "Vibecodelicious/vim_leetcode_ai",
  dependencies = { "ianding1/leetcode.vim" },
  config = function()
    require("vim_leetcode_ai").setup({
      ai_command = "claude",  -- or "aider", or custom command
    })
  end,
}
```

Using packer.nvim:

```lua
use {
  "Vibecodelicious/vim_leetcode_ai",
  requires = { "ianding1/leetcode.vim" },
  config = function()
    require("vim_leetcode_ai").setup({
      ai_command = "claude",
    })
  end,
}
```

## Configuration

```lua
require("vim_leetcode_ai").setup({
  -- Command to run the AI agent (required)
  ai_command = "claude",

  -- Keybindings (optional, shown are defaults)
  keys = {
    open = "<leader>ai",      -- Open AI assistant layout
    close = "<leader>aq",     -- Close AI assistant layout
    next_slide = "]s",        -- Next slide
    prev_slide = "[s",        -- Previous slide
  },

  -- Layout proportions (optional)
  layout = {
    tool_width = 0.5,         -- Tool pane width as fraction of top area
    bottom_height = 0.3,      -- AI terminal height as fraction of window
  },
})
```

## Usage

### 1. Open a LeetCode Problem

```vim
:LeetCodeList
```

Navigate to a problem and press `<CR>` to open it.

### 2. Open AI Assistant

Press `<leader>ai` (or your configured key) to open the three-pane layout:

```
┌─────────────────┬─────────────────┐
│                 │                 │
│  Tool Output    │  Code Editor    │
│  (empty)        │  (your code)    │
│                 │                 │
├─────────────────┴─────────────────┤
│                                   │
│  AI Agent Terminal                │
│                                   │
└───────────────────────────────────┘
```

### 3. Ask for Help

In the AI terminal, ask for help:

```
> Help me understand the two-pointer approach for this problem
```

Or ask for a walkthrough:

```
> Walk me through a solution step by step
```

### 4. Navigate Slideshow

When the AI creates a slideshow, it appears in the Tool Output pane. Navigate with:

- `]s` - Next slide
- `[s` - Previous slide

The code editor will highlight the relevant lines for each slide.

### 5. Close AI Assistant

Press `<leader>aq` to close the layout and return to normal editing.

## Commands

| Command | Description |
|---------|-------------|
| `:AIOpen` | Open AI assistant layout |
| `:AIClose` | Close AI assistant layout |
| `:AINextSlide` | Go to next slide |
| `:AIPrevSlide` | Go to previous slide |

## For AI Agents

The AI agent can create slideshows by running:

```bash
nvim -l <plugin-path>/lua/slideshow/main.lua --data '<json>'
```

Query window size before generating slides:

```bash
nvim -l <plugin-path>/lua/slideshow/query.lua window-size
# Returns: {"cols": 80, "rows": 24}
```

See [contracts/cli.md](./contracts/cli.md) for full CLI documentation.

## Troubleshooting

### AI terminal not starting

Check that your `ai_command` is correct:

```lua
require("vim_leetcode_ai").setup({
  ai_command = "/full/path/to/claude",  -- Try full path
})
```

### Slideshow not highlighting lines

Ensure the slideshow has valid line numbers that exist in the code buffer.

### Layout looks wrong

Try closing and reopening: `<leader>aq` then `<leader>ai`

# vim_leetcode_ai

An AI-assisted Neovim plugin for solving LeetCode problems with interactive slideshows, code highlighting, and AI coaching using the Socratic method.

## Overview

`vim_leetcode_ai` creates a three-pane layout in Neovim that brings Claude Code (or any AI agent) directly into your editor while solving coding problems. Get AI guidance through the Socratic method, request interactive algorithm explanations with synchronized code highlighting, and run visualizations—all without leaving Vim.

### Key Features

- **Three-Pane Layout**: Code editor (top-right), tool output (top-left), and AI terminal (bottom) side-by-side
- **Interactive Slideshows**: Navigate algorithm explanations with automatic code line highlighting
- **Socratic Method AI**: System prompt guides users to discover solutions rather than providing direct answers
- **Tool Pane**: Run visualizations, animations, and custom programs (Python, shell scripts, etc.)

## Installation

### Requirements

- **Neovim 0.9+** (for Lua execution and RPC support)
- **Shell access** (for launching slideshow and tool programs)
- **Optional**: Claude Code (default AI agent—configurable to any CLI tool)

### Using a Plugin Manager

#### With `lazy.nvim`:
```lua
{
  'basil/vim_leetcode_ai',
  config = function()
    require('vim_leetcode_ai').setup()
  end
}
```

#### With `packer.nvim`:
```lua
use {
  'basil/vim_leetcode_ai',
  config = function()
    require('vim_leetcode_ai').setup()
  end
}
```

#### With `vim-plug`:
```vim
Plug 'basil/vim_leetcode_ai'
```

## Quick Start

1. Open any code file in Neovim
2. Run `:AIOpen` to launch the three-pane layout
3. Type your question or request in the AI terminal (bottom pane)
4. Ask Claude to explain an algorithm or show you a visualization
5. Close with `:AIClose` when you're done

## Usage Guide

### Commands

- **`:AIOpen`** — Open the three-pane layout and spawn the AI agent
- **`:AIClose`** — Close the layout
- **`:AIRestart`** — Restart the AI agent terminal
- **`:checkhealth vim_leetcode_ai`** — Diagnose configuration and dependency issues

### Keybindings

| Keybinding | Action |
|-----------|--------|
| `<leader>ai` | Open layout (`:AIOpen`) |
| `<leader>aq` | Close layout (`:AIClose`) |

All keybindings can be customized in your config (see Configuration section below).

### How It Works

**AI-Assisted Coding Workflow:**
1. Open a LeetCode problem in Neovim
2. Launch the plugin with `:AIOpen`
3. Ask Claude for guidance: "Can you explain how to solve this problem using the Socratic method?"
4. Claude responds in the terminal pane
5. Request a visual explanation: "Show me a slideshow of the algorithm steps"
6. Claude generates and launches an interactive slideshow in the tool pane
7. Ask follow-up questions without losing context

## Configuration

Add this to your Neovim config (typically `~/.config/nvim/init.lua`):

```lua
require('vim_leetcode_ai').setup({
  -- AI command and system prompt
  ai_command = 'claude --system-prompt "You are a Socratic tutor..." --add-dir /tmp',

  -- Keybindings
  keys = {
    open = '<leader>ai',
    close = '<leader>aq',
  },

  -- Layout proportions (0.0-1.0)
  layout = {
    tool_width = 0.5,        -- Tool pane takes 50% of top area
    bottom_height = 0.3,     -- AI terminal takes 30% of height
  },
})
```

### Customizing the AI Agent

To use a different AI command (not Claude Code):

```lua
require('vim_leetcode_ai').setup({
  ai_command = 'your-ai-tool --options --flags',
})
```

The plugin passes a temporary directory as a working directory to the AI agent, enabling access to helper scripts and generated slideshow files.

## Project Structure

```
vim_leetcode_ai/
├── lua/
│   ├── vim_leetcode_ai/        # Main plugin code
│   │   ├── init.lua            # Entry point & commands
│   │   ├── config.lua          # Configuration & system prompt
│   │   ├── state.lua           # Global state management
│   │   ├── layout.lua          # Three-pane layout creation
│   │   ├── terminal.lua        # AI agent terminal
│   │   ├── highlight.lua       # Code line highlighting
│   │   ├── keybindings.lua     # Vim keybindings setup
│   │   └── health.lua          # Health check diagnostics
│   └── slideshow/              # Slideshow program (runs via `nvim -l`)
│       ├── main.lua            # Entry point
│       ├── navigation.lua      # Slide navigation
│       ├── rpc_client.lua      # RPC to parent Neovim
│       ├── tui.lua             # Terminal UI rendering
│       ├── parser.lua          # JSON parsing
│       └── query.lua           # Buffer queries
├── plugin/
│   └── vim_leetcode_ai.vim     # Vimscript entry point
├── scripts/                    # Helper shell scripts
│   ├── launch_slideshow.sh     # Launch slideshow from JSON
│   ├── get_code_file.sh        # Extract code with line numbers
│   ├── open_file.sh            # Open files in code pane
│   └── run_tool.sh             # Execute programs in tool pane
├── tests/
│   ├── unit/                   # Unit tests for each module
│   ├── integration/            # End-to-end workflow tests
│   └── fixtures/               # Test data & demo files
└── specs/                      # Specification & design docs
    └── 001-ai-slideshow/       # Feature spec, plan, tasks
```

## Features Explained

### Three-Pane Layout

The plugin creates a split layout optimized for the coding + AI workflow:

```
┌─────────────────┬──────────────────────┐
│  Tool Output    │   Code Editor        │
│  (animations,   │   (your LeetCode     │
│   slideshows)   │    problem)          │
├─────────────────┴──────────────────────┤
│         AI Agent Terminal               │
│  (type questions, read responses)       │
└────────────────────────────────────────┘
```

### Interactive Slideshows

Slideshows are JSON-based interactive presentations:

```json
{
  "title": "Understanding Two Sum",
  "slides": [
    {
      "title": "Problem",
      "content": "Given an array of integers...",
      "lines": [1, 2, 3]
    },
    {
      "title": "Approach: Hash Map",
      "content": "Use a hash map for O(n) solution...",
      "lines": [5, 6, 7]
    }
  ]
}
```

Lines are automatically highlighted in your code editor as you navigate through slides.

**Navigation**: Slideshows use Vim's native quickfix list, so you navigate with:
- `]q` — Next slide
- `[q` — Previous slide
- `:copen` — View all slides in the quickfix window
- `:cc 3` — Jump to slide 3

### Socratic Method Coaching

The built-in system prompt guides users toward solutions:

- Asks clarifying questions about the problem
- Suggests approaches without giving away the answer
- Requests step-by-step code explanations
- Points to relevant data structures or algorithms
- Encourages problem-solving over copy-paste

### Tool Pane Visualizations

Run custom programs in the tool pane. Built-in examples include:

- **Triforce 3D Carousel**: Rotating 3D visualization using braille characters
- **Mode 7 Terrain Flyover**: Classic SNES-style scrolling effect
- **Sorting Animations**: Visualize algorithms like quicksort with animated bar charts

Launch a visualization by requesting it from Claude: "Show me a visualization of quicksort"

## Testing

The plugin includes comprehensive unit and integration tests using the `busted` framework.

### Run All Tests

```bash
cd vim_leetcode_ai
busted
```

### Run Specific Test Suite

```bash
busted tests/unit/layout_spec.lua
busted tests/integration/full_workflow_spec.lua
```

### Test Coverage

- **Unit Tests**: Layout creation, terminal spawning, highlighting, slideshow navigation, keybindings, configuration
- **Integration Tests**: Complete workflow from open → interact → launch slideshow → close

All tests are deterministic and isolated (no external dependencies).

## Examples

### Example 1: Get Socratic Guidance on Two Sum

```
You (in terminal):
  "I'm stuck on the Two Sum problem. Can you guide me?"

Claude (response):
  "Let me ask you some questions first:
   1. What's the constraint on the input array size?
   2. Can there be duplicate targets?
   3. What data structures do you know that can look up elements quickly?
   ..."
```

### Example 2: Get a Visual Slideshow

```
You (in terminal):
  "Show me a slideshow of the two-pointer approach"

Claude (response):
  "[Launches slideshow in the tool pane]
   Your code is highlighted at each step."
```

### Example 3: Run a Visualization

```
You (in terminal):
  "Visualize how quicksort works on this array"

Claude (response):
  "[Runs visualization in tool pane]
   Watch as the algorithm partitions and sorts the array..."
```

## Architecture

### Plugin Components

- **`layout.lua`** — Creates and manages the three-pane split layout
- **`terminal.lua`** — Spawns and manages the AI agent terminal buffer
- **`highlight.lua`** — Highlights code lines using Neovim extmarks
- **`config.lua`** — Manages configuration and system prompt
- **`state.lua`** — Tracks global state (window IDs, buffer IDs, layout status)
- **`keybindings.lua`** — Sets up Vim keybindings for navigation

### Slideshow Program

The slideshow runs as a standalone `nvim -l` Lua script that:

1. Parses JSON slide data
2. Renders slides in the terminal
3. Communicates via RPC to the parent Neovim instance
4. Sends highlight commands for code lines
5. Receives navigation commands (next, prev, goto) from stdin

This design allows slideshows to run independently while maintaining editor integration.

## Project Principles

This project follows these core principles:

1. **Code Quality**: Each function does one thing well with descriptive names
2. **Testing Standards**: All features backed by deterministic, isolated tests
3. **Vim-First**: Keyboard-driven with no context switching required
4. **YAGNI**: No speculative features—only what's needed for the task

## Contributing

Contributions are welcome! Please ensure:

- All tests pass (`busted`)
- Code follows the project structure and naming conventions
- New features are backed by tests
- Commit messages include a descriptive body (not just subject line)

## Troubleshooting

### Layout won't open
Run `:checkhealth vim_leetcode_ai` to diagnose dependency issues.

### Highlights aren't working
Ensure your Neovim version is 0.9 or higher: `nvim --version`

### AI terminal appears empty
Check that your AI command is configured correctly in `setup()` and is available in your PATH.

### Slideshow won't display
Verify the JSON data is valid and includes required fields: `title`, `content`, `slides[]`

## License

This project is open source. See LICENSE file for details.

## Support

- **Documentation**: See `specs/001-ai-slideshow/` for detailed specification
- **Issue Tracker**: Report bugs and suggest features on GitHub
- **Quick Start Guide**: Check `specs/001-ai-slideshow/quickstart.md`

---

Happy problem-solving! 🧠

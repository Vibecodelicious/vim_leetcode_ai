# Data Model: AI Slideshow Assistant

## Entities

### Slide

A single unit of explanation in a slideshow.

| Field | Type | Description |
|-------|------|-------------|
| content | string | Text content to display (may include ASCII art, formatting) |
| lines | number[] | Line numbers to highlight in code editor (1-indexed) |

**Validation**:
- `content` must not be empty
- `lines` must be non-negative integers (empty array is valid)

### Slideshow

An ordered collection of slides.

| Field | Type | Description |
|-------|------|-------------|
| slides | Slide[] | Array of slides in display order |

**Validation**:
- Must contain at least one slide

### WindowDimensions

Dimensions of the tool output pane.

| Field | Type | Description |
|-------|------|-------------|
| cols | number | Width in columns |
| rows | number | Height in rows |

### HighlightCommand

Command sent from slideshow to Neovim to update highlights.

| Field | Type | Description |
|-------|------|-------------|
| action | string | "set" or "clear" |
| lines | number[] | Lines to highlight (for "set" action) |
| buffer | number | Buffer ID to highlight in (optional, defaults to code buffer) |

### NavigationCommand

Command sent from Neovim to slideshow via stdin.

| Field | Type | Description |
|-------|------|-------------|
| command | string | One of: "next", "prev", "goto", "quit" |
| arg | number? | Slide number for "goto" command (1-indexed) |

**Text protocol** (what actually goes over stdin):
- `next\n`
- `prev\n`
- `goto 3\n`
- `quit\n`

## State

### Plugin State (in Neovim)

| Field | Type | Description |
|-------|------|-------------|
| layout_open | boolean | Whether the three-pane layout is active |
| ai_terminal_job | number | Job ID of the AI agent terminal |
| tool_terminal_job | number | Job ID of the tool output terminal |
| code_buffer | number | Buffer ID of the code editor pane |
| code_window | number | Window ID of the code editor pane |
| highlight_ns | number | Namespace ID for line highlights |

### Slideshow State (in slideshow process)

| Field | Type | Description |
|-------|------|-------------|
| slides | Slide[] | All slides |
| current_index | number | Current slide index (0-indexed internally) |
| nvim_channel | number | RPC channel to parent Neovim |

## Relationships

```
┌─────────────────┐     launches      ┌─────────────────┐
│  Neovim Plugin  │──────────────────▶│  AI Agent       │
│                 │                   │  (terminal)     │
└────────┬────────┘                   └────────┬────────┘
         │                                     │
         │ manages                             │ runs shell command
         ▼                                     ▼
┌─────────────────┐     stdin/RPC     ┌─────────────────┐
│  Tool Output    │◀─────────────────▶│  Slideshow      │
│  Pane           │                   │  (nvim -l)      │
└─────────────────┘                   └─────────────────┘
         │
         │ highlights
         ▼
┌─────────────────┐
│  Code Editor    │
│  Pane           │
└─────────────────┘
```

## Data Flow

1. **AI creates slideshow**: AI agent runs `slideshow --data '{"slides":[...]}'`
2. **Slideshow starts**: Connects to `$NVIM` socket, displays first slide
3. **Slideshow sends highlights**: RPC call to plugin with line numbers
4. **Plugin highlights lines**: Uses `nvim_buf_add_highlight` on code buffer
5. **User navigates**: Presses `]s`, plugin sends `next\n` via `chansend()`
6. **Slideshow advances**: Updates display, sends new highlight RPC
7. **User closes**: Plugin sends `quit\n`, clears highlights

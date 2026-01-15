# Quickfix Navigation Design

## Overview

Replace terminal-based slideshow navigation with vim's native quickfix system.
This provides consistent navigation (`]q`/`[q`) that integrates with vim's existing
keybinding system and doesn't conflict with user mappings.

## Architecture

Quickfix serves as the **navigation hub** for all tools:

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   Quickfix      │────▶│  Navigation      │────▶│  Tool Action    │
│   ]q / [q       │     │  Handler         │     │                 │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                                                         │
                                    ┌────────────────────┼────────────────────┐
                                    ▼                    ▼                    ▼
                             ┌────────────┐      ┌────────────┐      ┌────────────┐
                             │ Slideshow  │      │ Animation  │      │  Terminal  │
                             │ (buffer)   │      │ (terminal) │      │   Tool     │
                             └────────────┘      └────────────┘      └────────────┘
```

## Tool Types

### 1. Slideshow (Buffer-based) - Phase 1
- Quickfix entries contain slide metadata
- Navigation updates:
  - Code buffer highlights (via `entry.user_data.lines`)
  - Content display buffer (slide explanation text)
- No terminal involved - pure vim buffers

### 2. Terminal Tools (Animation/Demo) - Phase 2
- Quickfix entries represent "steps" or "frames"
- Navigation sends commands to running terminal program
- Terminal program receives 'n'/'p'/etc. via chansend

## Implementation Plan

### Phase 1: Buffer-based Slideshow

1. **Create slideshow buffer module**
   - Display slide content in a regular buffer (not terminal)
   - Buffer is read-only, controlled by plugin

2. **Populate quickfix from slide data**
   ```lua
   vim.fn.setqflist({}, ' ', {
     title = 'Slideshow',
     items = {
       { text = 'Slide 1: Introduction', user_data = { lines = {1,2,3}, content = '...' }},
       { text = 'Slide 2: Algorithm', user_data = { lines = {5,6}, content = '...' }},
     }
   })
   ```

3. **Hook quickfix navigation**
   ```lua
   vim.api.nvim_create_autocmd('CursorMoved', {
     buffer = qf_bufnr,
     callback = function()
       local idx = vim.fn.line('.')
       local entry = vim.fn.getqflist()[idx]
       if entry and entry.user_data then
         highlight.set_lines(entry.user_data.lines)
         update_content_buffer(entry.user_data.content)
       end
     end
   })
   ```

4. **Update launch_slideshow.sh**
   - Instead of spawning Lua terminal, call Lua function directly
   - Parse JSON, populate quickfix, open content buffer

5. **Remove terminal-based slideshow code**
   - Delete `lua/slideshow/` directory (or repurpose)
   - Update keybindings (remove `send_key_to_tool` for slideshows)

### Phase 2: Terminal Tool Navigation

1. **Extend quickfix handler for terminal tools**
   ```lua
   if state.tool_type == 'terminal' then
     vim.fn.chansend(state.tool_terminal_job, 'n')
   end
   ```

2. **Terminal tools provide step metadata**
   - Animation can register "frames" with quickfix
   - Each frame entry triggers navigation command to terminal

3. **Bidirectional sync (optional)**
   - Terminal tool can update quickfix position when user navigates directly
   - Via RPC callback to parent neovim

## Benefits

- **Native vim navigation**: `]q`/`[q` work out of the box
- **No keybinding conflicts**: Users keep their existing mappings
- **Consistent UX**: Same navigation pattern for all tool types
- **Simpler slideshow**: No terminal, no raw mode, no escape sequences

## Migration Path

1. Implement Phase 1 alongside existing terminal slideshow
2. Test with real usage
3. Remove old terminal slideshow once stable
4. Implement Phase 2 for advanced tools

## Open Questions

- Should quickfix window be visible or hidden?
- How to handle slide content that's longer than one screen?
- Should we use location list instead of quickfix (per-window)?

# Implementation Plan: AI Slideshow Assistant

**Branch**: `001-ai-slideshow` | **Date**: 2026-01-12 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-ai-slideshow/spec.md`

## Summary

A Neovim plugin that provides an AI-assisted LeetCode solving experience with a three-pane layout: tool output (top-left), code editor (top-right), and AI agent terminal (bottom). The AI can launch a slideshow program that walks users through code step-by-step, with line highlighting synchronized between the slideshow and editor. All components are written in Lua and run within the Neovim ecosystem.

## Technical Context

**Language/Version**: Lua 5.1 (LuaJIT via Neovim)
**Primary Dependencies**: Neovim 0.9+ APIs (`vim.api`, `vim.fn`, `vim.rpcrequest`)
**Storage**: N/A (stateless within session; slideshow data passed via CLI args)
**Testing**: busted (Lua testing framework) + plenary.nvim for Neovim-specific tests
**Target Platform**: Linux, macOS, Windows (anywhere Neovim 0.9+ runs)
**Project Type**: Single project (Neovim plugin + companion Lua scripts)
**Performance Goals**: <100ms for layout changes, <50ms for highlight updates
**Constraints**: Must not block Neovim UI; slideshow TUI must be responsive
**Scale/Scope**: Single user, single Neovim instance, single AI session at a time

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Code Quality | ✅ Pass | Lua with clear module boundaries, descriptive names |
| II. Testing Standards | ✅ Pass | TDD with busted/plenary; tests before implementation |
| III. Vim-First | ✅ Pass | All features usable within Neovim; keyboard-driven |
| IV. YAGNI | ✅ Pass | Building only what's needed: layout, slideshow, highlights |

## Project Structure

### Documentation (this feature)

```text
specs/001-ai-slideshow/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (RPC message formats)
└── checklists/          # Quality checklists
```

### Source Code (repository root)

```text
lua/
├── vim_leetcode_ai/
│   ├── init.lua           # Plugin entry point, setup(), commands
│   ├── layout.lua         # Three-pane layout management
│   ├── terminal.lua       # Terminal buffer management (AI agent, tool output)
│   ├── highlight.lua      # Line highlighting in code buffer
│   ├── keybindings.lua    # Slideshow navigation keybindings
│   ├── rpc.lua            # RPC server for slideshow communication
│   └── config.lua         # User configuration handling
├── slideshow/
│   ├── main.lua           # Slideshow entry point (run via nvim -l)
│   ├── tui.lua            # Terminal UI rendering
│   ├── navigation.lua     # Slide navigation logic
│   └── rpc_client.lua     # RPC client to communicate with parent Neovim

plugin/
└── vim_leetcode_ai.vim    # Vim command definitions (calls into Lua)

tests/
├── unit/
│   ├── layout_spec.lua
│   ├── highlight_spec.lua
│   └── slideshow_spec.lua
└── integration/
    └── full_workflow_spec.lua
```

**Structure Decision**: Single project with plugin code in `lua/vim_leetcode_ai/` and slideshow code in `lua/slideshow/`. Tests use busted conventions (`*_spec.lua`).

## Complexity Tracking

> No constitution violations to justify.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| (none) | - | - |

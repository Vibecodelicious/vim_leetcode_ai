# Feature Specification: AI Slideshow Assistant for LeetCode

**Feature Branch**: `001-ai-slideshow`
**Created**: 2026-01-12
**Status**: Draft
**Input**: User description: "AI agent with interactive slideshow for leetcode.vim"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Open AI Assistant Layout (Priority: P1)

A user is stuck on a LeetCode problem and wants guidance. They invoke the AI assistant, which opens a three-pane layout: tool output (top-left), code editor (top-right), and a terminal running an AI coding agent (bottom). The user interacts with the AI agent in the terminal as they normally would.

**Why this priority**: Core value proposition - users need the layout and terminal integration before any slideshow features matter.

**Independent Test**: Can be fully tested by opening a LeetCode problem, invoking the AI assistant command, and verifying the three-pane layout appears with a functional terminal running the configured AI agent.

**Acceptance Scenarios**:

1. **Given** a LeetCode problem is open in Vim, **When** the user invokes the AI assistant command, **Then** the three-pane layout appears with the code editor preserved in the top-right.
2. **Given** the layout is open, **When** the user focuses the terminal pane, **Then** they can interact with the AI agent normally (type messages, receive responses).
3. **Given** the layout is open, **When** the user runs standard AI agent commands in the terminal, **Then** the AI agent functions as expected.

---

### User Story 2 - Navigate AI-Generated Slideshow (Priority: P2)

The AI agent creates a slideshow by running a shell command that launches the slideshow program with slide data. The program appears in the tool output pane. Each slide explains a concept and references specific lines in the code. The slideshow program sends messages to Vim to highlight the referenced lines. The user navigates slides with keybindings that work from any pane.

**Why this priority**: The slideshow is the core differentiating feature, but requires the basic layout (P1) to function first.

**Independent Test**: Can be tested by asking the AI to create a walkthrough, then using keybindings to navigate slides and observing line highlights change in the code editor.

**Acceptance Scenarios**:

1. **Given** the AI assistant layout is open, **When** the AI agent runs a shell command to launch the slideshow program, **Then** the slideshow program launches in the tool output pane.
2. **Given** a slideshow is active with slides referencing lines 5-8, **When** the user views that slide, **Then** the slideshow program sends a message to Vim and lines 5-8 are highlighted in the code editor.
3. **Given** a slideshow is active, **When** the user presses the "next slide" key from any pane, **Then** Vim sends a command to the slideshow program, the slide advances, and line highlights update.
4. **Given** a slideshow is active, **When** the user presses the "previous slide" key from any pane, **Then** the slideshow goes back and line highlights update.

---

### User Story 3 - AI Launches Visualization Programs (Priority: P3)

The AI agent can launch arbitrary visualization programs in the tool output pane (not just slideshows) using shell commands. For example, the AI might launch an algorithm visualizer or data structure viewer to help the user understand a concept.

**Why this priority**: Extends the tool output pane beyond slideshows, but slideshows (P2) should work first.

**Independent Test**: Can be tested by asking the AI to visualize a data structure, verifying a visualization program launches in the tool output pane.

**Acceptance Scenarios**:

1. **Given** the AI assistant layout is open, **When** the AI agent runs a shell command to launch a visualization program, **Then** the program appears in the tool output pane.
2. **Given** a visualization program is running, **When** the user interacts with it (if interactive), **Then** the program responds as expected.
3. **Given** a visualization program is running, **When** the AI runs a command to launch a different program, **Then** the tool output pane switches to the new program.

---

### User Story 4 - Close and Restore Layout (Priority: P4)

The user can close the AI assistant to return to a normal editing view, and can reopen it later. The terminal session with the AI agent persists within the Vim session.

**Why this priority**: Quality-of-life feature that improves usability but is not core functionality.

**Independent Test**: Can be tested by opening the AI assistant, having a conversation, closing it, reopening it, and verifying the terminal session is still active.

**Acceptance Scenarios**:

1. **Given** the AI assistant is open, **When** the user closes it, **Then** the layout returns to the standard code editor view.
2. **Given** the AI assistant was previously opened in this session, **When** the user reopens it, **Then** the terminal buffer with conversation history is restored.

---

### Edge Cases

- ~~What happens when the slideshow references lines that don't exist in the current code?~~ → Resolved: FR-028
- ~~How does the system handle when the user modifies code while a slideshow is active?~~ → Resolved: FR-029
- ~~What happens when the AI assistant is invoked without a LeetCode problem open?~~ → Resolved: FR-005 (works on any buffer)
- What happens when the configured AI agent command fails to start? → Show error message with troubleshooting hints
- What happens when the slideshow program fails to connect to Neovim for highlighting? → Slideshow continues without highlights, shows warning
- ~~What happens when the terminal buffer is accidentally closed by the user?~~ → Resolved: FR-010
- What happens when the AI launches a program that crashes? → Tool output pane shows exit status, user can launch another program

## Requirements *(mandatory)*

### Functional Requirements

**Layout & Panes**

- **FR-001**: Plugin MUST create a three-pane layout: tool output (top-left), code editor (top-right), terminal (bottom).
- **FR-002**: The code editor pane MUST display the current buffer (any code file).
- **FR-003**: Pane proportions MUST be sensible defaults (approximately 50/50 horizontal split for top panes, 70/30 vertical split favoring code).
- **FR-004**: Users MUST be able to close the AI assistant and return to normal layout.
- **FR-005**: The plugin MUST work with any code buffer, not just LeetCode problems.

**Terminal Integration**

- **FR-006**: The bottom pane MUST be a terminal buffer running a configurable AI agent command.
- **FR-007**: Users MUST be able to configure which AI agent to run (e.g., `claude`, `aider`, custom command).
- **FR-008**: The terminal buffer MUST persist within the Vim session when the layout is closed and reopened.
- **FR-009**: Users MUST be able to interact with the terminal normally (input, scrolling, copy/paste).
- **FR-010**: When the AI agent exits or crashes, the plugin MUST display a message with instructions for restarting the agent and closing the pane.

**Tool Output Pane**

- **FR-011**: The tool output pane MUST be able to display a terminal running the slideshow program.
- **FR-012**: The tool output pane MUST be able to display other visualization programs launched by the AI.
- **FR-013**: The AI agent MUST be able to launch programs in the tool output pane using standard shell commands.

**Slideshow Program**

- **FR-014**: The slideshow MUST be a standalone terminal program (Lua script run via `nvim -l`).
- **FR-015**: The slideshow program MUST accept navigation commands via stdin (e.g., `next`, `prev`, `goto N`).
- **FR-016**: The slideshow program MUST send highlight commands to Neovim via RPC.
- **FR-017**: Each slide MUST be able to reference zero or more line numbers or line ranges.
- **FR-018**: The slideshow MUST display current slide content and navigation indicator (e.g., "Slide 2/5").

**Navigation Keybindings**

- **FR-019**: Users MUST be able to navigate slides using keybindings (e.g., `]s` / `[s`).
- **FR-020**: Navigation keybindings MUST work from any pane (not just the slideshow pane).
- **FR-021**: Neovim MUST send navigation commands to the slideshow program via `chansend()`.
- **FR-022**: When navigating past the last slide or before the first, the slideshow MUST show a subtle "end of slideshow" indicator and stay on the current slide.

**Line Highlighting**

- **FR-023**: When a slide references lines, those lines MUST be highlighted in the code editor.
- **FR-024**: Line highlighting MUST use full-line background color (not just gutter markers).
- **FR-025**: Line highlights MUST update when the slideshow program sends new highlight commands.
- **FR-026**: Line highlights MUST be cleared when the slideshow is closed or dismissed.
- **FR-027**: When highlighted lines are outside the viewport, the code editor MUST scroll to show them.
- **FR-028**: When a slide references invalid lines (out of range or deleted), the plugin MUST show a non-blocking warning with refresh instructions and highlight only valid lines.
- **FR-029**: When the code buffer is modified while a slideshow is active, the plugin MUST display a "stale" indicator and continue showing the slideshow.

**Integration**

- **FR-030**: Plugin MUST work alongside leetcode.vim without interfering with its functionality.
- **FR-031**: AI assistance MUST be on-demand only (no automatic triggers).

### Key Entities

- **Slide**: A single unit of explanation containing text content and optional line references (single lines or ranges).
- **Slideshow**: An ordered collection of slides, rendered by a standalone terminal program.
- **Slideshow Program**: A Lua script (run via `nvim -l`) that displays slides in a TUI, accepts navigation via stdin, and sends highlight commands to Neovim via RPC.
- **Tool Output Pane**: The top-left pane that can display the slideshow program or other visualization programs.
- **Line Reference**: A pointer to one or more lines in the code editor (e.g., line 5, lines 10-15).
- **AI Agent**: An external terminal-based coding assistant (e.g., Claude Code, Aider) that runs in the bottom pane.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can open the AI assistant layout and see the terminal with AI agent running within 2 seconds.
- **SC-002**: Users can navigate through a 5-slide slideshow in under 30 seconds using keybindings.
- **SC-003**: Line highlights update within 100ms of slide navigation (perceived as instant).
- **SC-004**: Navigation keybindings work correctly regardless of which pane is focused.
- **SC-005**: Plugin does not interfere with leetcode.vim's `:LeetCodeTest` and `:LeetCodeSubmit` commands.
- **SC-006**: Users can complete a full workflow (open problem, open AI assistant, ask for slideshow, navigate it, close assistant) without errors.

## Clarifications

### Session 2026-01-12

- Q: What should happen when slideshow references lines that no longer exist? → A: Show non-blocking warning about stale code view with refresh instructions, but continue highlighting valid lines.
- Q: What should happen when user modifies code while slideshow is active? → A: Keep slideshow active but show a "stale" indicator; highlights may be inaccurate.
- Q: What should happen when navigating past the last slide or before the first? → A: Show subtle "end of slideshow" indicator, stay on current slide.
- Q: What should happen when AI assistant is invoked without a LeetCode problem open? → A: Open layout with current buffer as code pane (works on any file, not just LeetCode).
- Q: What should happen when the AI agent terminal crashes or exits? → A: Show a message with instructions for restarting the agent and closing the pane.

## Assumptions

- The AI agent (Claude Code, Aider, etc.) is already installed and configured on the user's system.
- The AI agent can execute shell commands (e.g., Claude Code's Bash tool, Aider's shell access).
- Neovim 0.9+ is required (for `nvim -l` Lua script execution and RPC support).
- Neovim has terminal buffer support (`:terminal`).
- The slideshow program will be developed as part of this project (in Lua, run via `nvim -l`).

# Tasks: AI Slideshow Assistant

**Input**: Design documents from `/specs/001-ai-slideshow/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: TDD approach per constitution - tests written before implementation.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

Based on plan.md:
- Plugin code: `lua/vim_leetcode_ai/`
- Slideshow code: `lua/slideshow/`
- Commands: `plugin/`
- Tests: `tests/unit/`, `tests/integration/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Create project directory structure per plan.md
- [x] T002 [P] Create plugin entry point in plugin/vim_leetcode_ai.vim
- [x] T003 [P] Create Lua module entry point in lua/vim_leetcode_ai/init.lua
- [x] T004 [P] Create configuration module in lua/vim_leetcode_ai/config.lua
- [x] T005 [P] Setup test infrastructure with busted/plenary in tests/

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T006 Implement plugin state management in lua/vim_leetcode_ai/state.lua
- [x] T007 [P] Create highlight namespace setup in lua/vim_leetcode_ai/highlight.lua (stub)
- [x] T008 [P] Create terminal management utilities in lua/vim_leetcode_ai/terminal.lua (stub)
- [x] T009 Define user commands (:AIOpen, :AIClose, :AIRestart) in lua/vim_leetcode_ai/init.lua
- [x] T010 Define keybinding setup function in lua/vim_leetcode_ai/keybindings.lua (stub)

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Open AI Assistant Layout (Priority: P1) 🎯 MVP

**Goal**: Create three-pane layout with AI agent terminal

**Independent Test**: Open any file, run :AIOpen, verify three-pane layout appears with AI agent terminal running

### Tests for User Story 1

- [x] T011 [P] [US1] Unit test for layout creation in tests/unit/layout_spec.lua
- [x] T012 [P] [US1] Unit test for terminal spawn in tests/unit/terminal_spec.lua
- [x] T013 [P] [US1] Unit test for config defaults in tests/unit/config_spec.lua

### Implementation for User Story 1

- [x] T014 [US1] Implement layout.create() for three-pane split in lua/vim_leetcode_ai/layout.lua
- [x] T015 [US1] Implement layout.get_tool_pane_size() in lua/vim_leetcode_ai/layout.lua
- [x] T016 [US1] Implement layout.get_code_buffer_info() in lua/vim_leetcode_ai/layout.lua
- [x] T017 [US1] Implement terminal.spawn_ai_agent() in lua/vim_leetcode_ai/terminal.lua
- [x] T018 [US1] Implement terminal.on_exit_callback() with restart/close message in lua/vim_leetcode_ai/terminal.lua
- [x] T019 [US1] Implement config.setup() with ai_command option in lua/vim_leetcode_ai/config.lua
- [x] T020 [US1] Wire :AIOpen command to layout.create() in lua/vim_leetcode_ai/init.lua
- [x] T021 [US1] Wire :AIRestart command to terminal.restart() in lua/vim_leetcode_ai/init.lua

**Checkpoint**: User Story 1 complete - can open three-pane layout with AI agent

---

## Phase 4: User Story 2 - Navigate AI-Generated Slideshow (Priority: P2)

**Goal**: Slideshow program with navigation and line highlighting

**Independent Test**: Launch slideshow with test data, navigate with ]s/[s, verify highlights update

### Tests for User Story 2

- [x] T022 [P] [US2] Unit test for slideshow JSON parsing in tests/unit/slideshow_spec.lua
- [x] T023 [P] [US2] Unit test for navigation logic in tests/unit/slideshow_spec.lua
- [x] T024 [P] [US2] Unit test for highlight.set_lines() in tests/unit/highlight_spec.lua
- [x] T025 [P] [US2] Unit test for keybinding dispatch in tests/unit/keybindings_spec.lua

### Implementation for User Story 2

**Slideshow Program (lua/slideshow/)**

- [x] T026 [P] [US2] Implement CLI argument parsing in lua/slideshow/main.lua
- [x] T027 [P] [US2] Implement JSON slideshow data parsing in lua/slideshow/parser.lua
- [x] T028 [US2] Implement RPC client connection to parent Neovim in lua/slideshow/rpc_client.lua
- [x] T029 [US2] Implement slide rendering (text display) in lua/slideshow/tui.lua
- [x] T030 [US2] Implement navigation indicator ("Slide 2/5") in lua/slideshow/tui.lua
- [x] T031 [US2] Implement stdin command reading (next/prev/goto/quit) in lua/slideshow/navigation.lua
- [x] T032 [US2] Implement end-of-slideshow indicator in lua/slideshow/navigation.lua
- [x] T033 [US2] Send highlight RPC on slide change in lua/slideshow/main.lua
- [x] T034 [US2] Send slide change notification RPC in lua/slideshow/main.lua

**Plugin Highlight Support (lua/vim_leetcode_ai/)**

- [x] T035 [US2] Implement highlight.set_lines() with full-line background in lua/vim_leetcode_ai/highlight.lua
- [x] T036 [US2] Implement highlight.clear() in lua/vim_leetcode_ai/highlight.lua
- [x] T037 [US2] Implement scroll-to-highlight logic in lua/vim_leetcode_ai/highlight.lua
- [x] T038 [US2] Implement invalid line warning (FR-028) in lua/vim_leetcode_ai/highlight.lua
- [x] T039 [US2] Implement stale indicator on buffer change (FR-029) in lua/vim_leetcode_ai/highlight.lua

**Navigation Keybindings**

- [x] T040 [US2] Implement keybindings.setup() with ]s/[s mappings in lua/vim_leetcode_ai/keybindings.lua
- [x] T041 [US2] Implement send_to_slideshow() using chansend() in lua/vim_leetcode_ai/keybindings.lua
- [x] T042 [US2] Wire keybindings to work from any pane in lua/vim_leetcode_ai/keybindings.lua

**Query Command**

- [x] T043 [US2] Implement query.lua for window-size query in lua/slideshow/query.lua
- [x] T044 [US2] Implement query.lua for code-buffer query in lua/slideshow/query.lua

**Checkpoint**: User Story 2 complete - slideshow navigation with highlights works

---

## Phase 5: User Story 3 - AI Launches Visualization Programs (Priority: P3)

**Goal**: Tool output pane can run arbitrary programs launched by AI

**Independent Test**: From AI terminal, run a command that launches a program in tool output pane

### Tests for User Story 3

- [x] T045 [P] [US3] Unit test for tool pane program launch in tests/unit/terminal_spec.lua
- [x] T046 [P] [US3] Unit test for tool pane program switch in tests/unit/terminal_spec.lua

### Implementation for User Story 3

- [x] T047 [US3] Implement terminal.launch_in_tool_pane(cmd) in lua/vim_leetcode_ai/terminal.lua
- [x] T048 [US3] Implement tool pane program replacement logic in lua/vim_leetcode_ai/terminal.lua
- [x] T049 [US3] Handle tool pane program exit gracefully in lua/vim_leetcode_ai/terminal.lua

**Checkpoint**: User Story 3 complete - AI can launch any program in tool pane

---

## Phase 6: User Story 4 - Close and Restore Layout (Priority: P4)

**Goal**: Layout can be closed and reopened with session persistence

**Independent Test**: Open layout, close it, reopen it, verify AI terminal history preserved

### Tests for User Story 4

- [x] T050 [P] [US4] Unit test for layout close in tests/unit/layout_spec.lua
- [x] T051 [P] [US4] Unit test for terminal buffer persistence in tests/unit/terminal_spec.lua

### Implementation for User Story 4

- [x] T052 [US4] Implement layout.close() preserving terminal buffers in lua/vim_leetcode_ai/layout.lua
- [x] T053 [US4] Implement layout.restore() reopening existing buffers in lua/vim_leetcode_ai/layout.lua
- [x] T054 [US4] Wire :AIClose command to layout.close() in lua/vim_leetcode_ai/init.lua
- [x] T055 [US4] Track layout state for restore in lua/vim_leetcode_ai/state.lua

**Checkpoint**: User Story 4 complete - full open/close/restore cycle works

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T056 [P] Integration test for full workflow in tests/integration/full_workflow_spec.lua
- [x] T057 [P] Validate quickstart.md scenarios work end-to-end
- [x] T058 Code cleanup and refactoring across all modules
- [x] T059 Performance validation (<100ms layout, <50ms highlights)
- [x] T060 [P] Add health check (:checkhealth vim_leetcode_ai) in lua/vim_leetcode_ai/health.lua

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - US1 must complete before US2 (US2 needs layout)
  - US2 must complete before US3 (US3 extends tool pane from US2)
  - US4 can run in parallel with US2/US3 (independent close/restore logic)
- **Polish (Phase 7)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Foundational only - MVP baseline
- **User Story 2 (P2)**: Depends on US1 (needs layout and tool pane)
- **User Story 3 (P3)**: Depends on US2 (extends tool pane program launching)
- **User Story 4 (P4)**: Depends on US1 (needs layout to close/restore)

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Stubs/interfaces before implementations
- Core logic before integration
- Story complete before moving to next priority

### Parallel Opportunities

**Phase 1 (Setup):**
```
T002, T003, T004, T005 can run in parallel
```

**Phase 2 (Foundational):**
```
T007, T008, T010 can run in parallel (after T006)
```

**User Story 1:**
```
T011, T012, T013 (tests) can run in parallel
```

**User Story 2:**
```
T022, T023, T024, T025 (tests) can run in parallel
T026, T027 (slideshow CLI) can run in parallel
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test three-pane layout independently
5. Deploy/demo if ready - users can already use AI agent in layout

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. User Story 1 → MVP! Users can use AI assistant layout
3. User Story 2 → Slideshow feature complete
4. User Story 3 → Visualization programs work
5. User Story 4 → Full close/restore UX
6. Each story adds value without breaking previous stories

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story
- TDD required per constitution - write failing tests first
- Commit after each task or logical group
- Stop at any checkpoint to validate independently
- Total: 60 tasks across 7 phases

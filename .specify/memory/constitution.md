<!--
Sync Impact Report
==================
Version change: 0.0.0 → 1.0.0
Modified principles: N/A (initial version)
Added sections:
  - I. Code Quality
  - II. Testing Standards
  - III. Vim-First
  - IV. YAGNI (You Aren't Gonna Need It)
  - Development Workflow
  - Quality Gates
Removed sections: N/A (initial version)
Templates requiring updates:
  - .specify/templates/plan-template.md ✅ (Constitution Check section compatible)
  - .specify/templates/spec-template.md ✅ (no changes needed)
  - .specify/templates/tasks-template.md ✅ (TDD workflow compatible)
Follow-up TODOs: None
-->

# vim_leetcode_ai Constitution

## Core Principles

### I. Code Quality

All code MUST be readable, maintainable, and self-documenting.

- Functions MUST do one thing and do it well
- Names MUST be descriptive and intention-revealing
- Code MUST follow consistent formatting (enforced by tooling)
- Magic numbers and strings MUST be named constants
- Cyclomatic complexity MUST remain low; extract functions when complexity grows
- Dead code MUST be deleted, not commented out

**Rationale**: Code is read far more often than written. Clarity prevents bugs and
reduces onboarding friction.

### II. Testing Standards

Tests are mandatory and MUST follow the Red-Green-Refactor cycle.

- Tests MUST be written before implementation (TDD)
- Tests MUST fail before implementation passes them
- Each test MUST verify a single behavior
- Tests MUST be deterministic and isolated (no shared state)
- Test names MUST describe the scenario and expected outcome
- Integration tests MUST cover critical paths; unit tests cover logic

**Rationale**: Tests document intended behavior and catch regressions early.
Writing tests first forces clear API design.

### III. Vim-First

This project exists to enhance the Vim/Neovim LeetCode workflow.

- All features MUST be usable entirely within Vim/Neovim
- Keyboard-driven interaction is the primary interface
- No feature MUST require leaving the editor
- Plugin architecture MUST integrate with Vim's native patterns (buffers, quickfix, etc.)
- Performance MUST not degrade editor responsiveness

**Rationale**: The target user lives in Vim. Context-switching to browser or other
tools breaks flow state and defeats the project's purpose.

### IV. YAGNI (You Aren't Gonna Need It)

Build only what is needed now, not what might be needed later.

- No speculative features or "just in case" abstractions
- Prefer inline code over premature extraction
- Prefer simple solutions over flexible/extensible ones
- Three similar instances MUST exist before abstracting
- Configuration options MUST address proven needs, not hypothetical ones
- Delete code that is no longer used; version control preserves history

**Rationale**: Unused code has maintenance cost with zero benefit. Premature
abstraction often guesses wrong about future needs.

## Development Workflow

- Branches MUST be short-lived and focused on a single feature or fix
- Commits MUST be atomic and include meaningful messages with body text
- All changes MUST pass linting, type checks, and tests before merge
- Code review is encouraged for non-trivial changes

## Quality Gates

Before any code is merged:

1. **Lint check**: Code MUST pass all linting rules
2. **Type check**: Code MUST pass type checking (if applicable)
3. **Test suite**: All tests MUST pass
4. **Coverage**: New code SHOULD have test coverage
5. **Constitution compliance**: Changes MUST not violate these principles

## Governance

This constitution defines the non-negotiable standards for the vim_leetcode_ai
project. All contributors and AI agents MUST comply.

- Amendments require documented justification and update to this file
- Version follows semantic versioning (MAJOR.MINOR.PATCH)
- MAJOR: Principle removal or incompatible redefinition
- MINOR: New principle or significant expansion
- PATCH: Clarifications and wording fixes

**Version**: 1.0.0 | **Ratified**: 2026-01-12 | **Last Amended**: 2026-01-12

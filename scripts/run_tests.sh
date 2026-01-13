#!/bin/bash
# Run tests for vim_leetcode_ai

cd "$(dirname "$0")/.."

# Run all unit tests
nvim --headless -u tests/minimal_init.lua \
  -c "PlenaryBustedDirectory tests/unit/ {minimal_init = 'tests/minimal_init.lua'}"

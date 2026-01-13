#!/bin/bash
# Interactive test script

cd "$(dirname "$0")/.."

nvim -u NONE \
  --cmd "set runtimepath+=." \
  --cmd "lua require('vim_leetcode_ai').setup({ ai_command = 'echo test' })" \
  test_code.lua

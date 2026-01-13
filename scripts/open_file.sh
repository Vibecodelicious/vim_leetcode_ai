#!/bin/bash
# Open a file in the code pane (not the AI terminal or tool pane)
# Usage: ./open_file.sh <file_path>
#
# This script must be run from within a Neovim terminal where $NVIM is set.

if [ -z "$NVIM" ]; then
    echo "Error: \$NVIM is not set. This script must be run from within a Neovim terminal."
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage: $0 <file_path>"
    echo ""
    echo "Open a file in the code editor pane."
    exit 1
fi

FILE_PATH="$1"

# Make path absolute if relative
if [[ "$FILE_PATH" != /* ]]; then
    FILE_PATH="$PWD/$FILE_PATH"
fi

# Use RPC to open the file in the code window
# This Lua code:
# 1. Gets the code window from plugin state
# 2. Switches to that window
# 3. Opens the file
# 4. Updates the code_buffer in state
nvim --server "$NVIM" --remote-expr "luaeval(\"(function()
  local state = require('vim_leetcode_ai.state')
  local s = state.get()
  if s.code_window and vim.api.nvim_win_is_valid(s.code_window) then
    vim.api.nvim_set_current_win(s.code_window)
    vim.cmd('edit ' .. vim.fn.fnameescape([[${FILE_PATH}]]))
    state.update({ code_buffer = vim.api.nvim_get_current_buf() })
    return 'ok'
  else
    return 'error: code window not found'
  end
end)()\")"

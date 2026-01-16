#!/bin/bash
# Run any command in the vim_leetcode_ai tool pane
# Usage: ./run_tool.sh <command> [args...]
#
# This script must be run from within a Neovim terminal where $NVIM is set.
# The command will be launched in the tool output pane with access to $NVIM
# for RPC communication back to the parent Neovim instance.
#
# Examples:
#   ./run_tool.sh python my_visualization.py
#   ./run_tool.sh ./my_custom_tool --arg value
#   ./run_tool.sh nvim -l some_lua_script.lua

if [ -z "$NVIM" ]; then
    echo "Error: \$NVIM is not set. This script must be run from within a Neovim terminal."
    exit 1
fi

if [ $# -eq 0 ]; then
    echo "Usage: $0 <command> [args...]"
    echo ""
    echo "Run any command in the tool output pane."
    echo "The command will have access to \$NVIM for RPC communication."
    exit 1
fi

# Build the command string, escaping for Lua
# We use Lua's [[...]] syntax for the outer string to avoid shell escaping issues
CMD="$*"

# Send command to parent Neovim to launch in tool pane
# Use --remote-send to avoid displaying return value
nvim --server "$NVIM" --remote-send "<Cmd>lua require('vim_leetcode_ai.terminal').launch_in_tool_pane([[${CMD}]])<CR>" 2>/dev/null

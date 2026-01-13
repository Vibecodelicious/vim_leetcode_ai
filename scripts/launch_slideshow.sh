#!/bin/bash
# Launch a slideshow in the vim_leetcode_ai tool pane
# Usage: ./launch_slideshow.sh <slideshow.json>
#
# This script must be run from within a Neovim terminal where $NVIM is set

if [ -z "$NVIM" ]; then
    echo "Error: \$NVIM is not set. This script must be run from within a Neovim terminal."
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage: $0 <slideshow.json>"
    exit 1
fi

SLIDESHOW_FILE="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"

# Make path absolute if relative
if [[ "$SLIDESHOW_FILE" != /* ]]; then
    SLIDESHOW_FILE="$PWD/$SLIDESHOW_FILE"
fi

# Send command to parent Neovim to launch slideshow in tool pane
# Using --remote-expr with luaeval() and [[...]] strings to avoid quote escaping issues
nvim --server "$NVIM" --remote-expr "luaeval(\"require('vim_leetcode_ai.terminal').launch_in_tool_pane([[nvim -l $PLUGIN_DIR/lua/slideshow/main.lua --file $SLIDESHOW_FILE]])\")"

#!/bin/bash
# Launch a slideshow in the vim_leetcode_ai tool pane
# Usage: ./launch_slideshow.sh <slideshow.json>
#    or: ./launch_slideshow.sh --data '{"slides":[...]}'
#    or: echo '{"slides":[...]}' | ./launch_slideshow.sh --stdin
#
# This script must be run from within a Neovim terminal where $NVIM is set

if [ -z "$NVIM" ]; then
    echo "Error: \$NVIM is not set. This script must be run from within a Neovim terminal."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"

# Parse arguments
if [ "$1" = "--data" ]; then
    # JSON passed as argument - write to temp file
    if [ -z "$2" ]; then
        echo "Error: --data requires JSON argument"
        exit 1
    fi
    SLIDESHOW_FILE="$(mktemp --suffix=.json)"
    echo "$2" > "$SLIDESHOW_FILE"
elif [ "$1" = "--stdin" ]; then
    # JSON from stdin - write to temp file
    SLIDESHOW_FILE="$(mktemp --suffix=.json)"
    cat > "$SLIDESHOW_FILE"
elif [ -n "$1" ]; then
    # File path provided
    SLIDESHOW_FILE="$1"
    # Make path absolute if relative
    if [[ "$SLIDESHOW_FILE" != /* ]]; then
        SLIDESHOW_FILE="$PWD/$SLIDESHOW_FILE"
    fi
else
    echo "Usage: $0 <slideshow.json>"
    echo "   or: $0 --data '{\"slides\":[...]}'"
    echo "   or: echo '{...}' | $0 --stdin"
    exit 1
fi

# Send command to parent Neovim to launch slideshow in tool pane
# Using --remote-expr with luaeval() and [[...]] strings to avoid quote escaping issues
nvim --server "$NVIM" --remote-expr "luaeval(\"require('vim_leetcode_ai.terminal').launch_in_tool_pane([[nvim -l $PLUGIN_DIR/lua/slideshow/main.lua --file $SLIDESHOW_FILE]])\")"

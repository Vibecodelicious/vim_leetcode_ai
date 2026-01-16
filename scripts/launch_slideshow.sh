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

# Read the slideshow JSON file
SLIDESHOW_JSON=$(cat "$SLIDESHOW_FILE" 2>/dev/null)
if [ -z "$SLIDESHOW_JSON" ]; then
    echo "Error: Failed to read slideshow file"
    exit 1
fi

# Use base64 encoding to avoid shell escaping issues
ENCODED_JSON=$(echo -n "$SLIDESHOW_JSON" | base64 -w0)

# Send command to parent Neovim to launch quickfix slideshow
# Write Lua command to temp file to avoid escaping issues and command-line display
TEMP_LUA="$(mktemp --suffix=.lua)"
cat > "$TEMP_LUA" <<EOF
require('vim_leetcode_ai.terminal').launch_quickfix_slideshow_b64('$ENCODED_JSON')
EOF

# Execute the Lua file in parent Neovim (silently)
nvim --server "$NVIM" --remote-send "<Cmd>luafile $TEMP_LUA<CR>" 2>/dev/null

# Clean up
rm -f "$TEMP_LUA"

# Clean up temp file if it was created
if [ "$1" = "--data" ] || [ "$1" = "--stdin" ]; then
    rm -f "$SLIDESHOW_FILE"
fi

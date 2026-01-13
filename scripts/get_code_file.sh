#!/bin/bash
# Get the contents of the code buffer in the vim_leetcode_ai layout
# Usage: ./get_code_file.sh
#
# This script must be run from within a Neovim terminal where $NVIM is set
# Returns the buffer contents (including unsaved changes)

if [ -z "$NVIM" ]; then
    echo "Error: \$NVIM is not set. This script must be run from within a Neovim terminal." >&2
    exit 1
fi

# Query parent Neovim for the code buffer's contents using vimscript
# This avoids lua string escaping issues
nvim --server "$NVIM" --remote-expr "join(getbufline(luaeval('require(\"vim_leetcode_ai.state\").get().code_buffer or 0'), 1, '$'), \"\n\")"

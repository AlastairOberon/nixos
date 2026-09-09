#!/usr/bin/env bash

# File where we will save our scale string (e.g., "DP-1=1.5;eDP-1=1.0")
SCALE_FILE="$HOME/.cache/quickshell_scales"

# Read the file if it exists, otherwise default to nothing
if [ -f "$SCALE_FILE" ]; then
    export QT_SCREEN_SCALE_FACTORS=$(cat "$SCALE_FILE")
fi

# Kill any running instances
killall quickshell

# Launch Quickshell
quickshell &

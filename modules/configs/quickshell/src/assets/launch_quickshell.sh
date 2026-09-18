#!/usr/bin/env bash

# File where we save our persistent settings
CONFIG_FILE="$HOME/.cache/quickshell_JellyfishDungeon.json"
SCALE_FILE="$HOME/.cache/quickshell_scales"

if [ -f "$CONFIG_FILE" ] && command -v jq >/dev/null 2>&1; then
    SCALES=$(jq -r '.monitorScales // {} | to_entries | map("\(.key)=\(.value)") | join(";")' "$CONFIG_FILE" 2>/dev/null)
    if [ -n "$SCALES" ]; then
        export QT_SCREEN_SCALE_FACTORS="$SCALES"
    fi
elif [ -f "$SCALE_FILE" ]; then
    export QT_SCREEN_SCALE_FACTORS=$(cat "$SCALE_FILE")
fi

# Kill any running instances
killall quickshell 2>/dev/null

# Launch Quickshell
quickshell &

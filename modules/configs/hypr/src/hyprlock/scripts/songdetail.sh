#!/bin/bash
# ~/.config/hypr/hyprlock/scripts/songdetail.sh

# Single playerctl call formatting artist and title
if command -v playerctl &> /dev/null; then
    metadata=$(playerctl metadata --format '{{artist}} - {{title}}' 2>/dev/null)
    if [[ -n "$metadata" && "$metadata" != " - " ]]; then
        echo "$metadata"
    elif playerctl status &> /dev/null; then
        echo "♪ Music Playing"
    else
        echo ""
    fi
else
    echo ""
fi


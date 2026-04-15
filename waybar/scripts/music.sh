#!/bin/bash

player=$(playerctl -l 2>/dev/null | while read p; do playerctl -p "$p" status 2>/dev/null | grep -q Playing && echo "$p"; done | head -n 1)

if [ -z "$player" ]; then
    echo ""
    exit 0
fi

metadata=$(playerctl -p "$player" metadata --format "{{artist}} - {{title}}" 2>/dev/null)

case "$player" in
    spotify*)
        icon="🎧"
        ;;
    youtube-music*|ytmdesktop*|youtube*)
        icon="▶️"
        ;;
    *)
        icon="🎶"
        ;;
esac

echo "$icon $metadata"
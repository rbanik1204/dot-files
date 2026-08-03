#!/bin/bash

player=$(playerctl -l 2>/dev/null | while read p; do
    playerctl -p "$p" status 2>/dev/null | grep -q Playing && echo "$p"
done | head -n 1)

echo "$(date +%T) | players: $(playerctl -l 2>/dev/null | tr '\n' ',') | selected: $player" >> /tmp/music_debug.log

if [ -z "$player" ]; then
    player=$(playerctl -l 2>/dev/null | while read p; do
        playerctl -p "$p" status 2>/dev/null | grep -q Paused && echo "$p"
    done | head -n 1)
    paused=true
fi

if [ -z "$player" ]; then
    echo '{"text": "", "class": "stopped", "tooltip": ""}'
    exit 0
fi

artist=$(playerctl -p "$player" metadata artist 2>/dev/null)
title=$(playerctl -p "$player" metadata title 2>/dev/null)
metadata="$artist - $title"

case "$player" in
    spotify*)  icon="󰓇"; class="spotify" ;;
    youtube-music*|ytmdesktop*|youtube*) icon="󰗃"; class="youtube" ;;
    *) icon="󰝚"; class="music" ;;
esac

if [ "$paused" = true ]; then
    echo "{\"text\": \"󰏤  Paused\", \"class\": \"paused\", \"tooltip\": \"$metadata\"}"
else
    # Truncate to 35 chars
    max=20
    display="$metadata"
    if [ ${#metadata} -gt $max ]; then
        display="${metadata:0:$max}…"
    fi
    echo "{\"text\": \"$icon  $display\", \"class\": \"$class\", \"tooltip\": \"$artist\\n$title\"}"
fi
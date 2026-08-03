#!/bin/bash

set -euo pipefail

wall_root="$HOME/Pictures/Wallpapers"

pick_random_wall() {
    find "$wall_root" -type f \
        \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
        ! -path "*/Live/*" \
        2>/dev/null | shuf -n 1
}

if [[ $# -ge 1 ]]; then
    wall_path="$1"
else
    cache="$HOME/.cache/current_wallpaper"

    current=""
    [[ -f "$cache" ]] && current=$(<"$cache")

    wall_count=$(find "$wall_root" -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
    ! -path "*/Live/*" | wc -l)

if (( wall_count <= 1 )); then
    wall_path=$(pick_random_wall)
else
    while :; do
        wall_path=$(pick_random_wall)
        [[ "$wall_path" != "$current" ]] && break
    done
fi

    echo "$wall_path" > "$cache"
fi

if [[ -z "$wall_path" || ! -f "$wall_path" ]]; then
    echo "Wallpaper not found: $wall_path" >&2
    exit 1
fi

if ! command -v awww &>/dev/null; then
    echo "awww not found in PATH" >&2
    exit 1
fi

if ! pgrep -x awww-daemon >/dev/null; then
    awww-daemon >/dev/null 2>&1 &

    until pgrep -x awww-daemon >/dev/null; do
        sleep 0.1
    done
fi
# sleep 0.2

transitions=(
    fade
    center
    wipe
)

transition_cache="$HOME/.cache/current_transition"

last_transition=""
[[ -f "$transition_cache" ]] && last_transition=$(<"$transition_cache")

if (( ${#transitions[@]} <= 1 )); then
    transition="${transitions[0]}"
else
    while :; do
        transition="${transitions[RANDOM % ${#transitions[@]}]}"
        [[ "$transition" != "$last_transition" ]] && break
    done
fi

echo "$transition" > "$transition_cache"

echo "Chosen transition: $transition" >&2

echo "Wallpaper : $wall_path"
echo "Transition: $transition"

if ! awww img "$wall_path" \
    --transition-type "$transition" \
    --transition-duration 8 \
    --transition-step 1 \
    --transition-fps 144
then
    echo "awww failed!"
    exit 1
fi

sleep 0.5

echo "Running Matugen..."
schemes=(
    scheme-tonal-spot
    scheme-vibrant
    scheme-expressive
    scheme-rainbow
    scheme-fruit-salad
    scheme-content
    scheme-fidelity
)

scheme=${schemes[RANDOM % ${#schemes[@]}]}
source_index=$((RANDOM % 5))

echo "Scheme: $scheme"
echo "Source Color Index: $source_index"

matugen image "$wall_path" \
    --config ~/.config/matugen/config.toml \
    --type "$scheme" \
    --source-color-index "$source_index" \
    --mode dark || {
    echo "Matugen failed!"
    exit 1
}
mkdir -p ~/.cache/matugen

matugen image "$wall_path" \
    --config ~/.config/matugen/config.toml \
    --type "$scheme" \
    --source-color-index "$source_index" \
    --mode dark \
    --json hex \
    --old-json-output \
    > ~/.cache/matugen/colors.json || {
        echo "Failed to generate colors.json!"
        exit 1
}
pkill waybar 2>/dev/null || true

while pgrep -x waybar >/dev/null; do
    sleep 0.1
done
hyprctl reload
sleep 0.2
echo "Restarting Waybar..."
waybar >/dev/null 2>&1 &
waybar -c ~/.config/waybar/config-bottom.jsonc \
       -s ~/.config/waybar/style-bottom.css >/dev/null 2>&1 &
#!/bin/bash

pgrep swww-daemon || swww-daemon &
sleep 0.5

img=$(find ~/Pictures/Wallpapers -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) | shuf -n 1)

swww img "$img" --transition-type grow --transition-pos $(hyprctl cursorpos | tr , ' ' | awk '{print $1/1600","$2/900}') --transition-duration 1 --transition-fps 60

matugen image "$img" --mode dark --source-color-index 0
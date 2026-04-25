#!/bin/bash

pgrep awww-daemon || awww-daemon &
sleep 0.5

img=$(find ~/Pictures/Wallpapers -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) | shuf -n 1)

pos=$(hyprctl cursorpos | tr ',' ' ' | awk '{print $1/1920","$2/1080}')

awww img "$img" \
  --transition-type grow \
  --transition-pos "$pos" \
  --transition-duration 1 \
  --transition-fps 60

preferences=(darkness lightness saturation less-saturation value)
prefer=${preferences[$RANDOM % ${#preferences[@]}]}

matugen image "$img" --mode dark --prefer "$prefer"

pkill -x rofi
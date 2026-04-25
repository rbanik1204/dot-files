#!/bin/bash

killall -9 waybar

#waybar ~/.config/waybar/themes/ultra-minimal/config.jsonc -s ~/.config/waybar/themes/ultra-minimal/style.css &
curl -sf 'https://wttr.in/?format=%c+%t' | cat -v
waybar &
waybar -c ~/.config/waybar/config-bottom.jsonc -s ~/.config/waybar/style-bottom.css &g
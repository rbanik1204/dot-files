#!/bin/bash
cava -p ~/.config/cava/waybar.ini 2>/dev/null | while read -r line; do
    BAR=""
    IFS=';' read -ra VALS <<< "$line"
    for val in "${VALS[@]}"; do
        case $val in
            0) BAR+="▁" ;;
            1) BAR+="▂" ;;
            2) BAR+="▃" ;;
            3) BAR+="▄" ;;
            4) BAR+="▅" ;;
            5) BAR+="▆" ;;
            6) BAR+="▇" ;;
            7) BAR+="█" ;;
        esac
    done
    echo "{\"text\": \"$BAR\", \"tooltip\": \"visualizer\"}" || break
done

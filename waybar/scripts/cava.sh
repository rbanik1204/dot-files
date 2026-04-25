#!/bin/bash

BARS=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")

cava -p ~/.config/cava/config | while IFS= read -r line; do
    values=$(echo "$line" | tr -d '\n' | sed 's/;$//')
    result=""
    IFS=';' read -ra nums <<< "$values"
    count=0
    for num in "${nums[@]}"; do
        [ $count -ge 8 ] && break
        if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -gt 0 ]; then
            result+="${BARS[$num]}"
        else
            result+=" "
        fi
        ((count++))
    done
    echo "{\"text\": \"$result\"}"
done
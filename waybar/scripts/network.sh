#!/bin/bash

STATE_FILE="/tmp/waybar_network_mode"

# Toggle mode on click
if [ "$1" = "toggle" ]; then
    MODE=$(cat "$STATE_FILE" 2>/dev/null || echo "speed")
    [ "$MODE" = "speed" ] && echo "ip" > "$STATE_FILE" || echo "speed" > "$STATE_FILE"
    exit
fi

MODE=$(cat "$STATE_FILE" 2>/dev/null || echo "speed")

# Get active network interface
IFACE=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $5; exit}')

if [ -z "$IFACE" ]; then
    echo '{"text": "󰤭 offline", "tooltip": "No connection", "class": "disconnected"}'
    exit
fi

# ── Interface type detection ──────────────────────────────────────────────────
IS_WIFI=false
IS_VPN=false

if [[ "$IFACE" == w* ]]; then
    IS_WIFI=true
elif [[ "$IFACE" == tun* || "$IFACE" == wg* || "$IFACE" == vpn* ]]; then
    IS_VPN=true
fi

# ── Wi-Fi details (only when on wireless) ────────────────────────────────────
WIFI_INFO=""
SSID=""
SIGNAL=""
SIGNAL_ICON=""

if $IS_WIFI; then
    if command -v iwctl &>/dev/null; then
        SSID=$(iwctl station "$IFACE" show 2>/dev/null | awk '/Connected network/ {print $NF}')
    fi
    if [ -z "$SSID" ] && command -v iw &>/dev/null; then
        SSID=$(iw dev "$IFACE" link 2>/dev/null | awk '/SSID/ {print $2}')
    fi

    SIGNAL_DBM=$(awk -v iface="$IFACE" \
        '$1 == iface":" { gsub(/\./, "", $4); print $4 }' \
        /proc/net/wireless 2>/dev/null)

    if [ -n "$SIGNAL_DBM" ]; then
        ABS=${SIGNAL_DBM#-}
        if   [ "$ABS" -le 50 ]; then SIGNAL_ICON="󰤨"; SIGNAL_PCT="100%"
        elif [ "$ABS" -le 60 ]; then SIGNAL_ICON="󰤥"; SIGNAL_PCT="75%"
        elif [ "$ABS" -le 70 ]; then SIGNAL_ICON="󰤢"; SIGNAL_PCT="50%"
        elif [ "$ABS" -le 80 ]; then SIGNAL_ICON="󰤟"; SIGNAL_PCT="25%"
        else                         SIGNAL_ICON="󰤯"; SIGNAL_PCT="<10%"
        fi
        SIGNAL="${SIGNAL_DBM} dBm (${SIGNAL_PCT})"
    fi

    ICON="${SIGNAL_ICON:-󰤨}"
    [ -n "$SSID" ]   && WIFI_INFO="${WIFI_INFO}SSID: $SSID\n"
    [ -n "$SIGNAL" ] && WIFI_INFO="${WIFI_INFO}Signal: $SIGNAL\n"

elif $IS_VPN; then
    ICON="󰦝"
else
    ICON="󰊗"
fi

# ── Bandwidth sampling over 1 second ─────────────────────────────────────────
RX1=$(awk -v iface="$IFACE:" '$1==iface {print $2}'  /proc/net/dev)
TX1=$(awk -v iface="$IFACE:" '$1==iface {print $10}' /proc/net/dev)
sleep 1
RX2=$(awk -v iface="$IFACE:" '$1==iface {print $2}'  /proc/net/dev)
TX2=$(awk -v iface="$IFACE:" '$1==iface {print $10}' /proc/net/dev)

RX_BYTES=$(( RX2 - RX1 ))
TX_BYTES=$(( TX2 - TX1 ))

format_speed() {
    local bytes=$1
    if   [ "$bytes" -ge 1048576 ]; then awk "BEGIN {printf \"%.1fMB/s\", $bytes/1048576}"
    elif [ "$bytes" -ge 1024 ];    then awk "BEGIN {printf \"%.0fKB/s\", $bytes/1024}"
    else echo "${bytes}B/s"
    fi
}

DOWN=$(format_speed "$RX_BYTES")
UP=$(format_speed "$TX_BYTES")

# ── Today's usage via vnstat ──────────────────────────────────────────────────
VNSTAT=$(vnstat --oneline 2>/dev/null | awk -F';' '{print "↓ "$10"  ↑ "$11}')
[ -z "$VNSTAT" ] && VNSTAT="vnstat not ready yet"

# ── Top app by TCP connection count ──────────────────────────────────────────
TOP=$(ss -tnp 2>/dev/null \
    | awk 'NR>1 && $NF~/pid/ {
        match($NF, /pid=([0-9]+)/, a); print a[1]
      }' \
    | sort | uniq -c | sort -rn \
    | head -1 \
    | awk '{print $2}' \
    | xargs -I{} cat /proc/{}/comm 2>/dev/null)
[ -z "$TOP" ] && TOP="idle"

# ── Display text ──────────────────────────────────────────────────────────────
if [ "$MODE" = "ip" ]; then
    IP=$(ip addr show "$IFACE" | awk '/inet / {print $2}' | head -1)
    TEXT="$ICON $IP"
else
    TEXT="$ICON ${DOWN} ↓ ${UP} ↑"
fi

# ── Tooltip & JSON output (jq handles all escaping safely) ───────────────────
TOOLTIP="Interface: $IFACE\n${WIFI_INFO}Today: $VNSTAT\nTop app: $TOP"
CLASS=$( $IS_WIFI && echo wifi || ( $IS_VPN && echo vpn || echo ethernet ) )

jq -cn \
    --arg text    "$TEXT" \
    --arg tooltip "$TOOLTIP" \
    --arg class   "$CLASS" \
    '{text: $text, tooltip: $tooltip, class: $class}'

#!/bin/bash
# weather-strip.sh — hyprlock weather  (~/.config/hypr/scripts/weather-strip.sh)
# All Nerd Font glyphs are embedded as literal UTF-8 — no escape sequences needed.

CACHE_CURRENT="$HOME/.cache/hyprlock_weather_current"
CACHE_STRIP="$HOME/.cache/hyprlock_weather_strip"
LOCATION="Kolkata"

PYTHON_SCRIPT='
import sys, json
from datetime import datetime
from collections import Counter

try:
    data = json.load(sys.stdin)
except:
    sys.exit(1)

ICONS = {
    113: "",   116: "",
    119: "",  122: "",
    143: "",     248: "",     260: "",
    176: "", 263: "", 266: "",
    293: "", 296: "", 353: "",
    182: "",    185: "",    281: "",
    284: "",    299: "",    302: "",
    305: "",    308: "",    311: "",
    314: "",    356: "",    359: "",
    179: "",    227: "",    230: "",
    317: "",    320: "",    323: "",
    326: "",    329: "",    332: "",
    335: "",    338: "",    350: "",
    362: "",    365: "",    368: "",
    371: "",    374: "",    377: "",    395: "",
    200: "", 386: "", 389: "",
    392: "",
}

def get_icon(code):
    return ICONS.get(int(code), "")

def dominant_code(hourly):
    slots = [h for h in hourly if int(h["time"]) in [900, 1200, 1500, 1800]]
    if not slots: slots = hourly
    codes = [int(h["weatherCode"]) for h in slots]
    return Counter(codes).most_common(1)[0][0]

cur    = data["current_condition"][0]
c_icon = get_icon(cur["weatherCode"])
c_desc = cur["weatherDesc"][0]["value"]
c_temp = cur["temp_C"]
c_feel = cur["FeelsLikeC"]
c_hum  = cur["humidity"]
c_wind = cur["windspeedKmph"]

print(f"CURRENT|{c_icon}  {c_desc}   {c_temp}°C (feels {c_feel}°C)   {c_hum}%   {c_wind} km/h")

days = []
for i, day in enumerate(data["weather"]):
    hi    = day["maxtempC"]
    lo    = day["mintempC"]
    icon  = get_icon(dominant_code(day["hourly"]))
    label = "Today" if i == 0 else datetime.strptime(day["date"], "%Y-%m-%d").strftime("%A")
    days.append(f"{label} {icon} {hi}°/{lo}°")

print("STRIP|" + "  ·  ".join(days))
'

fetch_weather() {
    raw=$(curl -s --max-time 8 -H "Accept-Language: en" "https://wttr.in/${LOCATION}?format=j1" 2>/dev/null)
    [ -z "$raw" ] && return 1
    echo "$raw" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null || return 1
    parsed=$(echo "$raw" | python3 -c "$PYTHON_SCRIPT" 2>/dev/null)
    [ -z "$parsed" ] && return 1
    echo "$parsed" | grep "^CURRENT|" | cut -d'|' -f2- > "$CACHE_CURRENT"
    echo "$parsed" | grep "^STRIP|"   | cut -d'|' -f2- > "$CACHE_STRIP"
}

fetch_weather

if [ "${1:-strip}" = "current" ]; then
    cat "$CACHE_CURRENT" 2>/dev/null || echo "  unavailable"
else
    cat "$CACHE_STRIP"   2>/dev/null || echo "  unavailable"
fi
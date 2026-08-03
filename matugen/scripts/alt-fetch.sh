#!/bin/bash
# alt-fetch.sh — alternative wallpaper sources (no auth required)

ALT_CACHE_DIR="$HOME/.cache/wallpaper-picker/alt-thumbs"
ALT_JSON_CACHE="$HOME/.cache/wallpaper-picker/alt-json"
ALT_JSON_TTL=900
ALT_THUMB_SIZE=320
ALT_MAX_RESULTS=60

mkdir -p "$ALT_CACHE_DIR" "$ALT_JSON_CACHE"

_alt_im() { command -v magick &>/dev/null && magick "$@" || convert "$@"; }
_base_cat() { echo "${1%_live}"; }

# ── Cache helpers ─────────────────────────────────────────────────────────────
_alt_cache_path() { echo "${ALT_JSON_CACHE}/${1}.json"; }

_alt_cache_valid() {
    local p="$1"
    [[ ! -f "$p" ]] && return 1
    local age=$(( $(date +%s) - $(stat -c %Y "$p" 2>/dev/null || echo 0) ))
    (( age < ALT_JSON_TTL ))
}

_alt_cache_get() {
    local p; p=$(_alt_cache_path "$1")
    _alt_cache_valid "$p" && cat "$p"
}

# Reads JSON from stdin, writes to cache only if non-empty/non-null
_alt_cache_put() {
    local key="$1"
    local tmp; tmp=$(mktemp)
    cat > "$tmp"
    local size; size=$(wc -c < "$tmp")
    local first; first=$(head -c 10 "$tmp" | tr -d '[:space:]')
    if (( size < 5 )) || [[ "$first" = "null" ]] || [[ "$first" = "[]" ]]; then
        rm -f "$tmp"
        return 0
    fi
    mv "$tmp" "$(_alt_cache_path "$key")"
}

# ── Thumbnail maker ───────────────────────────────────────────────────────────
_alt_make_thumb() {
    local url="$1"
    local hash; hash=$(printf '%s' "$url" | md5sum | cut -d' ' -f1)
    local thumb="$ALT_CACHE_DIR/${hash}.jpg"
    [[ -f "$thumb" ]] && { echo "$thumb"; return 0; }

    local tmp="${thumb}.dl"
    curl -sf --max-time 20 -L --compressed \
        -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:124.0) Gecko/20100101 Firefox/124.0" \
        -o "$tmp" "$url" 2>/dev/null || { rm -f "$tmp"; return 1; }

    local mime; mime=$(file --mime-type -b "$tmp" 2>/dev/null)
    case "$mime" in
        image/gif|video/*)
            if command -v ffmpeg &>/dev/null; then
                ffmpeg -loglevel error -i "$tmp" -frames:v 1 \
                    -vf "scale=${ALT_THUMB_SIZE}:${ALT_THUMB_SIZE}:force_original_aspect_ratio=increase,crop=${ALT_THUMB_SIZE}:${ALT_THUMB_SIZE}" \
                    -y "$thumb" 2>/dev/null
            else
                _alt_im "${tmp}[0]" -thumbnail "${ALT_THUMB_SIZE}x${ALT_THUMB_SIZE}^" \
                    -gravity center -extent "${ALT_THUMB_SIZE}x${ALT_THUMB_SIZE}" \
                    -quality 85 "$thumb" 2>/dev/null
            fi ;;
        *)
            _alt_im "$tmp" -thumbnail "${ALT_THUMB_SIZE}x${ALT_THUMB_SIZE}^" \
                -gravity center -extent "${ALT_THUMB_SIZE}x${ALT_THUMB_SIZE}" \
                -quality 85 "$thumb" 2>/dev/null ;;
    esac
    rm -f "$tmp"
    [[ -f "$thumb" ]] && echo "$thumb"
}

# ── Python runner: reads JSON from a file, avoids all pipe/echo issues ────────
# Usage: _alt_parse_json <tmpfile> <parser_name> [extra_args...]
# Each parser is a self-contained python3 heredoc function below.
_parse_gelbooru() {
    local f="$1" category="$2" subcat="$3"
    python3 - "$category" "$subcat" "$f" << 'PYEOF'
import sys, json
category, subcat, fpath = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    with open(fpath) as fh:
        raw = fh.read().strip()
    if not raw or raw == "null":
        sys.exit(0)
    d = json.loads(raw)
    if d is None:
        sys.exit(0)
    posts = d.get("post", d) if isinstance(d, dict) else d
    if not isinstance(posts, list):
        sys.exit(0)
    for p in posts:
        url   = p.get("file_url", "") or ""
        thumb = p.get("sample_url", "") or p.get("preview_url", "") or url
        if not url:
            continue
        low = url.lower()
        kind = "video" if low.endswith((".mp4",".webm")) else ("gif" if low.endswith(".gif") else "static")
        w = p.get("width",0) or 0; h = p.get("height",0) or 0
        if w and h and (w < 300 or h < 200):
            continue
        tags = (p.get("tags","") or "")[:40].replace("\t"," ")
        print(f"{url}\t{thumb}\t{tags}\t{kind}")
except (json.JSONDecodeError, KeyError, TypeError, OSError):
    sys.exit(0)
PYEOF
}

_parse_danbooru() {
    local f="$1"
    python3 - "$f" << 'PYEOF'
import sys, json
try:
    with open(sys.argv[1]) as fh:
        raw = fh.read().strip()
    if not raw or raw == "null":
        sys.exit(0)
    posts = json.loads(raw)
    if posts is None or not isinstance(posts, list):
        sys.exit(0)
    for p in posts:
        url   = p.get("file_url","") or ""
        large = p.get("large_file_url","") or url
        if not url:
            continue
        low = url.lower()
        if low.endswith(".zip"):
            continue
        kind = "video" if low.endswith((".mp4",".webm")) else ("gif" if low.endswith(".gif") else "static")
        w = p.get("image_width",0) or 0; h = p.get("image_height",0) or 0
        if w and h and (w < 300 or h < 200):
            continue
        tags = (p.get("tag_string","") or "")[:40].replace("\t"," ")
        print(f"{url}\t{large}\t{tags}\t{kind}")
except (json.JSONDecodeError, KeyError, TypeError, OSError):
    sys.exit(0)
PYEOF
}

_parse_yandere() {
    local f="$1"
    python3 - "$f" << 'PYEOF'
import sys, json
try:
    with open(sys.argv[1]) as fh:
        raw = fh.read().strip()
    if not raw or raw == "null":
        sys.exit(0)
    posts = json.loads(raw)
    if posts is None or not isinstance(posts, list):
        sys.exit(0)
    for p in posts:
        url    = p.get("file_url","") or ""
        sample = p.get("sample_url","") or url
        if not url:
            continue
        low = url.lower()
        kind = "video" if low.endswith((".mp4",".webm")) else ("gif" if low.endswith(".gif") else "static")
        w = p.get("width",0) or 0; h = p.get("height",0) or 0
        if w and h and (w < 640 or h < 360):
            continue
        tags = (p.get("tags","") or "")[:40].replace("\t"," ")
        print(f"{url}\t{sample}\t{tags}\t{kind}")
except (json.JSONDecodeError, KeyError, TypeError, OSError):
    sys.exit(0)
PYEOF
}

_parse_safebooru() {
    local f="$1"
    python3 - "$f" << 'PYEOF'
import sys, json
try:
    with open(sys.argv[1]) as fh:
        raw = fh.read().strip()
    if not raw or raw == "null":
        sys.exit(0)
    d = json.loads(raw)
    if d is None:
        sys.exit(0)
    posts = d if isinstance(d, list) else d.get("post", [])
    for p in posts:
        d2   = p.get("directory","") or ""
        img  = p.get("image","") or ""
        if not img:
            continue
        url   = f"https://safebooru.org/images/{d2}/{img}"
        thumb = f"https://safebooru.org/thumbnails/{d2}/thumbnail_{img}"
        low = img.lower()
        kind = "video" if low.endswith((".mp4",".webm")) else ("gif" if low.endswith(".gif") else "static")
        tags = (p.get("tags","") or "")[:40].replace("\t"," ")
        print(f"{url}\t{thumb}\t{tags}\t{kind}")
except (json.JSONDecodeError, KeyError, TypeError, OSError):
    sys.exit(0)
PYEOF
}

_parse_redgifs() {
    local f="$1"
    python3 - "$f" << 'PYEOF'
import sys, json
try:
    with open(sys.argv[1]) as fh:
        raw = fh.read().strip()
    if not raw or raw == "null":
        sys.exit(0)
    d = json.loads(raw)
    if d is None:
        sys.exit(0)
    gifs = d.get("gifs", []) or []
    for g in gifs:
        urls  = g.get("urls", {}) or {}
        vid   = urls.get("hd","") or urls.get("sd","") or urls.get("vthumbnail","")
        thumb = urls.get("thumbnail","") or urls.get("poster","")
        if not vid:
            continue
        low  = vid.lower()
        kind = "video" if (".mp4" in low or ".webm" in low) else "gif"
        w = g.get("width",0) or 0; h = g.get("height",0) or 0
        if w and h and (w < 300 or h < 200):
            continue
        title = (g.get("description","") or g.get("id",""))[:40].replace("\t"," ")
        print(f"{vid}\t{thumb}\t{title}\t{kind}")
except (json.JSONDecodeError, KeyError, TypeError, OSError):
    sys.exit(0)
PYEOF
}

# ══════════════════════════════════════════════════════════════════════════════
#  TAG MAPS
# ══════════════════════════════════════════════════════════════════════════════

_gelbooru_tags_for() {
    local category; category=$(_base_cat "$1"); local subcat="$2"
    case "$category" in
        anime)
            case "$subcat" in
                sfw)     echo "rating:general animated" ;;
                waifu)   echo "rating:general 1girl solo highres" ;;
                scenery) echo "rating:general scenery no_humans wallpaper" ;;
                mecha)   echo "rating:general mecha robot" ;;
                *)       echo "rating:general highres" ;;
            esac ;;
        hentai)
            case "$subcat" in
                ahegao)        echo "ahegao" ;;
                animebreasts)  echo "large_breasts" ;;
                body)          echo "thighs" ;;
                bondage)       echo "bondage" ;;
                milf)          echo "mature_female" ;;
                *)             echo "large_breasts animated" ;;
            esac ;;
        ahegaogif|ahegaovid)  echo "ahegao animated" ;;
        hentaiahegao)         echo "ahegao hentai" ;;
        sloppyahegao)         echo "ahegao saliva tongue_out animated" ;;
        tonguesaliva)         echo "tongue_out saliva animated" ;;
        boobsmilk)            echo "large_breasts milk lactation" ;;
        nature)               echo "landscape scenery no_humans" ;;
        building)             echo "city architecture" ;;
        clouds)               echo "sky clouds" ;;
        wallpaper)            echo "wallpaper highres" ;;
        *)                    echo "ahegao animated" ;;
    esac
}

_danbooru_tags_for() {
    local category; category=$(_base_cat "$1"); local subcat="$2"
    case "$category" in
        anime)
            case "$subcat" in
                sfw)     echo "rating:general" ;;
                waifu)   echo "rating:general 1girl" ;;
                scenery) echo "rating:general scenery" ;;
                mecha)   echo "mecha" ;;
                *)       echo "rating:general" ;;
            esac ;;
        hentai)
            case "$subcat" in
                ahegao)       echo "ahegao" ;;
                animebreasts) echo "large_breasts" ;;
                bondage)      echo "bondage" ;;
                milf)         echo "mature_female" ;;
                *)            echo "rating:explicit" ;;
            esac ;;
        ahegaogif|ahegaovid)  echo "ahegao animated" ;;
        hentaiahegao)         echo "ahegao" ;;
        sloppyahegao)         echo "ahegao saliva tongue_out" ;;
        tonguesaliva)         echo "tongue_out saliva" ;;
        boobsmilk)            echo "large_breasts lactation" ;;
        nature)               echo "scenery no_humans" ;;
        wallpaper)            echo "wallpaper" ;;
        *)                    echo "ahegao" ;;
    esac
}

_yandere_tags_for() {
    local category; category=$(_base_cat "$1"); local subcat="$2"
    case "$category" in
        anime)
            case "$subcat" in
                sfw)     echo "rating:safe" ;;
                waifu)   echo "rating:safe 1girl" ;;
                scenery) echo "rating:safe landscape" ;;
                mecha)   echo "mecha" ;;
                *)       echo "rating:safe" ;;
            esac ;;
        hentai)
            case "$subcat" in
                ahegao)       echo "ahegao" ;;
                animebreasts) echo "large_breasts rating:explicit" ;;
                bondage)      echo "bondage" ;;
                milf)         echo "mature_female" ;;
                *)            echo "rating:explicit" ;;
            esac ;;
        ahegaogif|ahegaovid)  echo "ahegao animated" ;;
        hentaiahegao)         echo "ahegao" ;;
        sloppyahegao)         echo "ahegao saliva tongue_out" ;;
        tonguesaliva)         echo "tongue_out saliva" ;;
        boobsmilk)            echo "large_breasts lactation" ;;
        wallpaper)            echo "wallpaper" ;;
        *)                    echo "ahegao rating:explicit" ;;
    esac
}

_redgifs_tags_for() {
    local category; category=$(_base_cat "$1"); local subcat="$2"
    case "$category" in
        ahegaogif|ahegaovid)  echo "ahegao hentai" ;;
        hentaiahegao)         echo "ahegao hentai" ;;
        sloppyahegao)         echo "sloppy ahegao blowjob" ;;
        tonguesaliva)         echo "tongue saliva ahegao" ;;
        boobsmilk)            echo "big boobs milk lactation" ;;
        nature)
            case "$subcat" in
                landscape) echo "nature landscape" ;;
                waves)     echo "ocean waves" ;;
                aurora)    echo "aurora" ;;
                fire)      echo "fire" ;;
                rain)      echo "rain" ;;
                snow)      echo "snow winter" ;;
                *)         echo "nature" ;;
            esac ;;
        anime)
            case "$subcat" in
                waifu) echo "anime girl" ;;
                mecha) echo "mecha robot" ;;
                *)     echo "anime" ;;
            esac ;;
        hentai)
            case "$subcat" in
                ahegao)       echo "ahegao" ;;
                animebreasts) echo "anime big boobs" ;;
                bondage)      echo "anime bondage" ;;
                milf)         echo "anime milf" ;;
                *)            echo "hentai" ;;
            esac ;;
        adult)
            case "$subcat" in
                boobs) echo "big boobs" ;;
                ass)   echo "big ass" ;;
                milf)  echo "milf" ;;
                bdsm)  echo "bdsm" ;;
                *)     echo "nsfw" ;;
            esac ;;
        clouds)   echo "clouds timelapse" ;;
        space)    echo "space galaxy" ;;
        *)        echo "hentai ahegao" ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
#  FETCH FUNCTIONS  — all write to tmpfile, parse from file (no echo|python)
# ══════════════════════════════════════════════════════════════════════════════

fetch_gelbooru_posts() {
    local category="$1" subcat="$2"
    local tags; tags=$(_gelbooru_tags_for "$category" "$subcat")
    local enc; enc=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$tags")
    local key="gelbooru_${category}_${subcat//\//_}"
    local cached; cached=$(_alt_cache_path "$key")
    local tmp; tmp=$(mktemp /tmp/wp-gel.XXXXXX)

    if _alt_cache_valid "$cached"; then
        cp "$cached" "$tmp"
    else
        curl -sf --max-time 15 -L --compressed \
            -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:124.0) Gecko/20100101 Firefox/124.0" \
            -o "$tmp" \
            "https://gelbooru.com/index.php?page=dapi&s=post&q=index&json=1&limit=${ALT_MAX_RESULTS}&tags=${enc}&pid=0" \
            2>/dev/null || { rm -f "$tmp"; return 0; }
        [[ ! -s "$tmp" ]] && { rm -f "$tmp"; return 0; }
        cat "$tmp" | _alt_cache_put "$key"
    fi

    _parse_gelbooru "$tmp" "$category" "$subcat"
    rm -f "$tmp"
}

fetch_danbooru_posts() {
    local category="$1" subcat="$2"
    local tags; tags=$(_danbooru_tags_for "$category" "$subcat")
    local enc; enc=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$tags")
    local key="danbooru_${category}_${subcat//\//_}"
    local cached; cached=$(_alt_cache_path "$key")
    local tmp; tmp=$(mktemp /tmp/wp-dan.XXXXXX)

    if _alt_cache_valid "$cached"; then
        cp "$cached" "$tmp"
    else
        curl -sf --max-time 15 -L --compressed \
            -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:124.0) Gecko/20100101 Firefox/124.0" \
            -H "Accept: application/json" \
            -o "$tmp" \
            "https://danbooru.donmai.us/posts.json?tags=${enc}&limit=20&page=1" \
            2>/dev/null || { rm -f "$tmp"; return 0; }
        [[ ! -s "$tmp" ]] && { rm -f "$tmp"; return 0; }
        cat "$tmp" | _alt_cache_put "$key"
    fi

    _parse_danbooru "$tmp"
    rm -f "$tmp"
}

fetch_yandere_posts() {
    local category="$1" subcat="$2"
    local tags; tags=$(_yandere_tags_for "$category" "$subcat")
    local enc; enc=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$tags")
    local key="yandere_${category}_${subcat//\//_}"
    local cached; cached=$(_alt_cache_path "$key")
    local tmp; tmp=$(mktemp /tmp/wp-yan.XXXXXX)

    if _alt_cache_valid "$cached"; then
        cp "$cached" "$tmp"
    else
        curl -sf --max-time 15 -L --compressed \
            -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:124.0) Gecko/20100101 Firefox/124.0" \
            -o "$tmp" \
            "https://yande.re/post.json?tags=${enc}&limit=${ALT_MAX_RESULTS}&page=1" \
            2>/dev/null || { rm -f "$tmp"; return 0; }
        [[ ! -s "$tmp" ]] && { rm -f "$tmp"; return 0; }
        cat "$tmp" | _alt_cache_put "$key"
    fi

    _parse_yandere "$tmp"
    rm -f "$tmp"
}

fetch_safebooru_posts() {
    local category="$1" subcat="$2"
    local base; base=$(_base_cat "$category")
    case "$base" in
        nature|anime|wallpaper|clouds|building|space) : ;;
        *) return 0 ;;
    esac

    local tags
    case "$base" in
        anime)
            case "$subcat" in
                waifu)   tags="1girl solo" ;;
                scenery) tags="scenery no_humans" ;;
                mecha)   tags="mecha" ;;
                *)       tags="highres" ;;
            esac ;;
        nature)    tags="scenery no_humans landscape" ;;
        wallpaper) tags="wallpaper" ;;
        *)         tags="highres" ;;
    esac

    local enc; enc=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$tags")
    local key="safebooru_${category}_${subcat//\//_}"
    local cached; cached=$(_alt_cache_path "$key")
    local tmp; tmp=$(mktemp /tmp/wp-safe.XXXXXX)

    if _alt_cache_valid "$cached"; then
        cp "$cached" "$tmp"
    else
        curl -sf --max-time 15 -L --compressed \
            -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:124.0) Gecko/20100101 Firefox/124.0" \
            -o "$tmp" \
            "https://safebooru.org/index.php?page=dapi&s=post&q=index&json=1&limit=${ALT_MAX_RESULTS}&tags=${enc}" \
            2>/dev/null || { rm -f "$tmp"; return 0; }
        [[ ! -s "$tmp" ]] && { rm -f "$tmp"; return 0; }
        cat "$tmp" | _alt_cache_put "$key"
    fi

    _parse_safebooru "$tmp"
    rm -f "$tmp"
}

# ── Redgifs token ─────────────────────────────────────────────────────────────
REDGIFS_TOKEN=""
REDGIFS_TOKEN_TS=0
REDGIFS_TOKEN_TTL=3600

_redgifs_token() {
    local now; now=$(date +%s)
    if [[ -z "$REDGIFS_TOKEN" ]] || (( now - REDGIFS_TOKEN_TS > REDGIFS_TOKEN_TTL )); then
        local tmp; tmp=$(mktemp)
        curl -sf --max-time 10 \
            "https://api.redgifs.com/v2/auth/temporary" \
            -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:124.0) Gecko/20100101 Firefox/124.0" \
            -o "$tmp" 2>/dev/null || { rm -f "$tmp"; return 1; }
        REDGIFS_TOKEN=$(python3 -c "
import sys,json
try:
    print(json.load(open(sys.argv[1])).get('token',''))
except: pass
" "$tmp" 2>/dev/null)
        rm -f "$tmp"
        REDGIFS_TOKEN_TS=$now
    fi
    [[ -n "$REDGIFS_TOKEN" ]] && echo "$REDGIFS_TOKEN" || return 1
}

fetch_redgifs_posts() {
    local category="$1" subcat="$2"
    local base; base=$(_base_cat "$category")
    case "$base" in
        ahegaogif|ahegaovid|hentaiahegao|sloppyahegao|tonguesaliva|boobsmilk|\
        nature|anime|hentai|adult|clouds|space|wallpaper) : ;;
        *) return 0 ;;
    esac

    local search; search=$(_redgifs_tags_for "$category" "$subcat")
    local token; token=$(_redgifs_token) || return 0
    local enc; enc=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$search")
    local key="redgifs_${category}_${subcat//\//_}"
    local cached; cached=$(_alt_cache_path "$key")
    local tmp; tmp=$(mktemp /tmp/wp-rgf.XXXXXX)

    if _alt_cache_valid "$cached"; then
        cp "$cached" "$tmp"
    else
        curl -sf --max-time 15 -L \
            -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:124.0) Gecko/20100101 Firefox/124.0" \
            -H "Authorization: Bearer ${token}" \
            -H "Accept: application/json" \
            -o "$tmp" \
            "https://api.redgifs.com/v2/gifs/search?search_text=${enc}&count=${ALT_MAX_RESULTS}&order=trending" \
            2>/dev/null || { rm -f "$tmp"; return 0; }
        [[ ! -s "$tmp" ]] && { rm -f "$tmp"; return 0; }
        cat "$tmp" | _alt_cache_put "$key"
    fi

    _parse_redgifs "$tmp"
    rm -f "$tmp"
}

# ══════════════════════════════════════════════════════════════════════════════
#  SOURCES PER CATEGORY
# ══════════════════════════════════════════════════════════════════════════════

_alt_sources_for() {
    local base; base=$(_base_cat "$1")
    case "$base" in
        ahegaogif|ahegaovid|hentaiahegao) echo "gelbooru danbooru yandere redgifs" ;;
        sloppyahegao|tonguesaliva|boobsmilk) echo "gelbooru danbooru redgifs" ;;
        anime)    echo "gelbooru danbooru yandere safebooru" ;;
        hentai)   echo "gelbooru danbooru yandere" ;;
        nature)   echo "safebooru redgifs" ;;
        wallpaper) echo "gelbooru safebooru" ;;
        adult)    echo "redgifs" ;;
        clouds|building|space) echo "safebooru gelbooru" ;;
        *)        echo "gelbooru safebooru" ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
#  WORKER
# ══════════════════════════════════════════════════════════════════════════════

_alt_source_worker() {
    local source_name="$1" category="$2" subcat="$3" \
          rofi_out="$4" map_out="$5" lock="$6"

    echo "[alt] ${source_name} → ${category}/${subcat}" >&2

    local -a file_urls thumb_urls labels kinds
    while IFS=$'\t' read -r file_url thumb_url label kind; do
        [[ -z "$file_url" ]] && continue
        file_urls+=("$file_url"); thumb_urls+=("$thumb_url")
        labels+=("$label"); kinds+=("$kind")
    done < <(
        case "$source_name" in
            gelbooru)  fetch_gelbooru_posts  "$category" "$subcat" ;;
            danbooru)  fetch_danbooru_posts  "$category" "$subcat" ;;
            yandere)   fetch_yandere_posts   "$category" "$subcat" ;;
            safebooru) fetch_safebooru_posts "$category" "$subcat" ;;
            redgifs)   fetch_redgifs_posts   "$category" "$subcat" ;;
        esac
    )

    [[ ${#file_urls[@]} -eq 0 ]] && { echo "[alt] ${source_name}: 0 results" >&2; return; }
    echo "[alt] ${source_name}: ${#file_urls[@]} posts" >&2

    local tmp_dir; tmp_dir=$(mktemp -d)
    local pids=() sem=0 max_jobs=16

    for i in "${!file_urls[@]}"; do
        local hash; hash=$(printf '%s' "${thumb_urls[$i]:-${file_urls[$i]}}" | md5sum | cut -d' ' -f1)
        if [[ -f "$ALT_CACHE_DIR/${hash}.jpg" ]]; then
            echo "$ALT_CACHE_DIR/${hash}.jpg" > "${tmp_dir}/${i}"
            continue
        fi
        (
            local t; t=$(_alt_make_thumb "${thumb_urls[$i]:-${file_urls[$i]}}")
            [[ -n "$t" ]] && echo "$t" > "${tmp_dir}/${i}"
        ) &
        pids+=($!)
        (( ++sem >= max_jobs )) && { wait "${pids[0]}"; pids=("${pids[@]:1}"); sem=$(( max_jobs-1 )); }
    done
    wait "${pids[@]}"

    (
        flock 9
        for i in "${!file_urls[@]}"; do
            [[ ! -f "${tmp_dir}/${i}" ]] && continue
            local thumb; thumb=$(cat "${tmp_dir}/${i}")
            [[ -z "$thumb" || ! -f "$thumb" ]] && continue
            local icon="󰋩"
            [[ "${kinds[$i]}" == "gif" ]]   && icon="󰐊"
            [[ "${kinds[$i]}" == "video" ]] && icon="󰕧"
            local lbl="${source_name}: ${labels[$i]}"
            [[ ${#lbl} -gt 35 ]] && lbl="${lbl:0:32}…"
            printf '%s %s\0icon\x1f%s\n' "$icon" "$lbl" "$thumb"   >> "$rofi_out"
            printf 'alt_url\t%s\t%s\t%s\t%s\n' \
                "${file_urls[$i]}" "$category" "$subcat" "${kinds[$i]}" >> "$map_out"
        done
    ) 9>"$lock"

    rm -rf "$tmp_dir"
}

# ══════════════════════════════════════════════════════════════════════════════
#  PUBLIC ENTRY POINT
# ══════════════════════════════════════════════════════════════════════════════

alt_fetch_all() {
    local rofi_out="$1" map_out="$2" \
          filter_cat="${3:-all}" filter_subcat="${4:-all}"

    local lock; lock=$(mktemp /tmp/wp-alt-lock.XXXXXX)
    local -a pids=()
    local max_jobs=8

    local -a cats_to_query=()
    if [[ "$filter_cat" == "all" ]]; then
        cats_to_query=(anime nature wallpaper)
    else
        cats_to_query=("$filter_cat")
    fi

    for cat in "${cats_to_query[@]}"; do
        local sources; sources=$(_alt_sources_for "$cat")
        for src in $sources; do
            while (( ${#pids[@]} >= max_jobs )); do
                local new_pids=()
                for p in "${pids[@]}"; do kill -0 "$p" 2>/dev/null && new_pids+=("$p"); done
                pids=("${new_pids[@]}")
                (( ${#pids[@]} >= max_jobs )) && sleep 0.1
            done
            _alt_source_worker "$src" "$cat" "$filter_subcat" \
                "$rofi_out" "$map_out" "$lock" &
            pids+=($!)
        done
    done

    wait "${pids[@]}"
    rm -f "$lock"
    echo "[alt] Done (cat=$filter_cat sub=$filter_subcat)" >&2
}

# ── Cache pruner ──────────────────────────────────────────────────────────────
prune_alt_cache() {
    local count
    count=$(find "$ALT_CACHE_DIR" -name "*.jpg" 2>/dev/null | wc -l)
    (( count > 600 )) && \
        find "$ALT_CACHE_DIR" -name "*.jpg" -printf '%T+ %p\n' \
        | sort | head -n $(( count - 600 )) | awk '{print $2}' | xargs -r rm -f
    find "$ALT_JSON_CACHE" -name "*.json" -mmin +$(( ALT_JSON_TTL * 2 / 60 )) -delete 2>/dev/null
}

if [[ -n "${BASH_VERSION-}" ]]; then
    export -f _alt_im _base_cat \
        _alt_cache_path _alt_cache_valid _alt_cache_get _alt_cache_put \
        _alt_make_thumb \
        _parse_gelbooru _parse_danbooru _parse_yandere _parse_safebooru _parse_redgifs \
        _gelbooru_tags_for fetch_gelbooru_posts \
        _danbooru_tags_for fetch_danbooru_posts \
        _yandere_tags_for  fetch_yandere_posts \
        fetch_safebooru_posts \
        _redgifs_token _redgifs_tags_for fetch_redgifs_posts \
        _alt_source_worker _alt_sources_for alt_fetch_all prune_alt_cache
fi
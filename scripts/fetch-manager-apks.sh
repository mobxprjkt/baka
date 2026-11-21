#!/usr/bin/env bash
set -euo pipefail
REPOSITORY="${1:-SukiSU-Nova/SukiSU-Nova}"
OUTPUT_DIR="${2:-manager-apks}"
mkdir -p "$OUTPUT_DIR"
HEADERS=(-H "Accept: application/vnd.github+json")
[[ -z "${GH_TOKEN:-}" ]] || HEADERS+=(-H "Authorization: Bearer ${GH_TOKEN}")
JSON="$(curl -fsSL "${HEADERS[@]}" "https://api.github.com/repos/${REPOSITORY}/releases/latest")"
URL="$(jq -r '[.assets[] | select((.name | ascii_downcase | endswith(".apk")))] | sort_by(.name) | first | .browser_download_url // empty' <<< "$JSON")"
NAME="$(jq -r '[.assets[] | select((.name | ascii_downcase | endswith(".apk")))] | sort_by(.name) | first | .name // empty' <<< "$JSON")"
[[ -n "$URL" && -n "$NAME" ]] || { echo "::error::No APK found in latest release"; exit 1; }
curl -fL --retry 3 "$URL" -o "$OUTPUT_DIR/$NAME"
test -s "$OUTPUT_DIR/$NAME"
echo "Downloaded $OUTPUT_DIR/$NAME"

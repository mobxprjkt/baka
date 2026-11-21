#!/usr/bin/env bash
set -euo pipefail

REPOSITORY="${1:-SukiSU-Nova/SukiSU-Nova}"
OUTPUT_DIR="${2:-manager-apks}"

mkdir -p "$OUTPUT_DIR"

API_URL="https://api.github.com/repos/${REPOSITORY}/releases/latest"
HEADERS=(-H "Accept: application/vnd.github+json")

if [[ -n "${GH_TOKEN:-}" ]]; then
  HEADERS+=(-H "Authorization: Bearer ${GH_TOKEN}")
fi

echo "Fetching latest SukiSU Nova manager release from $REPOSITORY"
RELEASE_JSON="$(curl -fsSL "${HEADERS[@]}" "$API_URL")"

APK_URL="$(
  jq -r '
    [.assets[]
      | select((.name | ascii_downcase | endswith(".apk")))]
    | sort_by(.name)
    | first
    | .browser_download_url // empty
  ' <<< "$RELEASE_JSON"
)"

APK_NAME="$(
  jq -r '
    [.assets[]
      | select((.name | ascii_downcase | endswith(".apk")))]
    | sort_by(.name)
    | first
    | .name // empty
  ' <<< "$RELEASE_JSON"
)"

if [[ -z "$APK_URL" || -z "$APK_NAME" ]]; then
  echo "::error::No APK asset found in the latest release of $REPOSITORY."
  exit 1
fi

curl -fL --retry 3 "$APK_URL" -o "$OUTPUT_DIR/$APK_NAME"
test -s "$OUTPUT_DIR/$APK_NAME"

echo "Manager APK downloaded: $OUTPUT_DIR/$APK_NAME"

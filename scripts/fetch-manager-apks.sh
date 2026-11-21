#!/usr/bin/env bash
set -euo pipefail

REPOSITORY="${1:-SukiSU-Ultra/SukiSU-Ultra}"
OUTPUT_DIR="${2:-manager-apks}"

mkdir -p "$OUTPUT_DIR"

API_URL="https://api.github.com/repos/${REPOSITORY}/releases/latest"
API_HEADERS=(-H "Accept: application/vnd.github+json")

if [[ -n "${GH_TOKEN:-}" ]]; then
  API_HEADERS+=(-H "Authorization: Bearer ${GH_TOKEN}")
fi

echo "Fetching latest manager release: $REPOSITORY"
RELEASE_JSON="$(curl -fsSL "${API_HEADERS[@]}" "$API_URL")"

DOWNLOAD_URL="$(
  jq -r '
    [.assets[]
      | select((.name | ascii_downcase | endswith(".apk")))]
    | sort_by(.name)
    | first
    | .browser_download_url // empty
  ' <<< "$RELEASE_JSON"
)"

ASSET_NAME="$(
  jq -r '
    [.assets[]
      | select((.name | ascii_downcase | endswith(".apk")))]
    | sort_by(.name)
    | first
    | .name // empty
  ' <<< "$RELEASE_JSON"
)"

if [[ -z "$DOWNLOAD_URL" || -z "$ASSET_NAME" ]]; then
  echo "::error::No APK asset found in the latest release of $REPOSITORY."
  exit 1
fi

curl -fL --retry 3 "$DOWNLOAD_URL" -o "$OUTPUT_DIR/$ASSET_NAME"
test -s "$OUTPUT_DIR/$ASSET_NAME"

echo "Manager APK saved to: $OUTPUT_DIR/$ASSET_NAME"

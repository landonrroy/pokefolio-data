#!/usr/bin/env bash
# Mirror one day of tcgcsv's TCGplayer price dump, keeping only Pokemon categories.
#
# Usage:  scripts/fetch-day.sh YYYY-MM-DD
# Env:    SEVENZIP  path to a 7-Zip binary with PPMd support (default: 7zz).
#                   Note: the reduced "7zr" build cannot decode these archives.
# Exit:   0 = written (or already present), 2 = upstream has no archive for that date
#
# Output: data/YYYY/prices-YYYY-MM-DD.tar.gz containing the raw, unmodified
#         per-group price JSON files under  YYYY-MM-DD/{categoryId}/{groupId}/prices
set -euo pipefail

DATE="${1:?usage: fetch-day.sh YYYY-MM-DD}"
CATEGORIES="3 85"   # 3 = Pokemon (EN), 85 = Pokemon Japan (absent upstream before mid-2024)
YEAR="${DATE:0:4}"
OUT="data/$YEAR/prices-$DATE.tar.gz"
SEVENZIP="${SEVENZIP:-7zz}"

if [ -f "$OUT" ]; then
  echo "$DATE: already archived"
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

URL="https://tcgcsv.com/archive/tcgplayer/prices-$DATE.ppmd.7z"
STATUS="$(curl -sL --retry 3 -w '%{http_code}' -o "$TMP/day.7z" "$URL")"
if [ "$STATUS" != "200" ]; then
  echo "$DATE: no upstream archive (HTTP $STATUS)"
  exit 2
fi

FILTERS=""
for c in $CATEGORIES; do FILTERS="$FILTERS $DATE/$c/*"; done
# set -f: the filters are 7-Zip wildcards, not shell globs
set -f
# shellcheck disable=SC2086
"$SEVENZIP" x -y -o"$TMP/x" "$TMP/day.7z" $FILTERS > /dev/null
set +f

if [ ! -d "$TMP/x/$DATE" ]; then
  echo "$DATE: upstream archive contains no Pokemon categories" >&2
  exit 2
fi

mkdir -p "data/$YEAR"
tar -C "$TMP/x" -czf "$OUT" "$DATE"
echo "$DATE: wrote $OUT ($(du -h "$OUT" | cut -f1))"

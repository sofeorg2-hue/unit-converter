#!/usr/bin/env bash
set -euo pipefail

SITEMAP_URL="${1:-https://theuniversalconverter.com/sitemap.xml}"

echo "Fetching sitemap $SITEMAP_URL"
urls=$(curl -sSf "$SITEMAP_URL" | grep -oP '(?<=<loc>)[^<]+' || echo "")
if [[ -z "$urls" ]]; then
  echo "No URLs found in sitemap"
  exit 1
fi

count=$(echo "$urls" | wc -l | tr -d ' ')
printf "Found %d urls\n" "$count"
printf "%-120s %s\n" "Sitemap URL" "Final URL"

while IFS= read -r url; do
  # follow redirects and print final URL
  final=$(curl -s -L -o /dev/null -w "%{url_effective}" "$url")
  ok="OK"
  if [[ "$final" =~ "/#converter$" ]]; then ok="WARN: generic"; fi
  if [[ "$final" =~ "/converter\?" ]]; then
    # ensure it has category, from and to
    query=${final#*\?}
    # strip fragment
    query=${query%%#*}
    if [[ ! "$query" =~ category= ]] || [[ ! "$query" =~ from= ]] || [[ ! "$query" =~ to= ]]; then ok="WARN: missing params"; fi
  fi
  printf "%-120s %s %s\n" "$url" "$final" "$ok"
done <<< "$urls"

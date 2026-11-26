#!/usr/bin/env bash
# Renders art/make-icon.swift and writes every macOS AppIcon size into the asset catalog,
# plus copies for the website.
set -euo pipefail
cd "$(dirname "$0")/.."

SET="App/Resources/Assets.xcassets/AppIcon.appiconset"
mkdir -p "$SET" build site
swift art/make-icon.swift build/icon-1024.png >/dev/null

images=""
for size in 16 32 128 256 512; do
    for scale in 1 2; do
        px=$((size * scale))
        name="icon_${size}x${size}@${scale}x.png"
        sips -z "$px" "$px" build/icon-1024.png --out "$SET/$name" >/dev/null
        images+="{\"idiom\":\"mac\",\"size\":\"${size}x${size}\",\"scale\":\"${scale}x\",\"filename\":\"$name\"},"
    done
done
printf '{"images":[%s],"info":{"version":1,"author":"xcode"}}\n' "${images%,}" > "$SET/Contents.json"
printf '{"info":{"version":1,"author":"xcode"}}\n' > App/Resources/Assets.xcassets/Contents.json
echo "icon set written to $SET"

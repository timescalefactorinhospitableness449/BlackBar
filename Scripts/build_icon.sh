#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

mkdir -p Assets/Icon.iconset Resources

while read -r size name; do
  magick Assets/Icon.png -resize "${size}x${size}" "Assets/Icon.iconset/${name}"
done <<'SIZES'
16 icon_16x16.png
32 icon_16x16@2x.png
32 icon_32x32.png
64 icon_32x32@2x.png
128 icon_128x128.png
256 icon_128x128@2x.png
256 icon_256x256.png
512 icon_256x256@2x.png
512 icon_512x512.png
1024 icon_512x512@2x.png
SIZES

iconutil -c icns Assets/Icon.iconset -o Resources/Icon.icns
echo "Wrote Resources/Icon.icns"

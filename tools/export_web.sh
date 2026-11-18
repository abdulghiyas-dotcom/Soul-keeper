#!/usr/bin/env bash
# Builds the browser version into build/web/. Usage: GODOT=/path/to/godot tools/export_web.sh
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
"$GODOT" --headless --import >/dev/null 2>&1 || true
timeout 120 "$GODOT" --headless --script res://tools/build_theme.gd
timeout 120 "$GODOT" --headless --script res://tools/build_icons.gd
mkdir -p build/web
touch build/.gdignore  # keep Godot from importing its own build output
"$GODOT" --headless --export-release "Web" build/web/index.html
# Offline from the very first visit: cache the whole game when the service worker
# installs (Godot's default waits for a second visit) and take control immediately.
SW=build/web/index.service.worker.js
sed -i 's/cache.addAll(CACHED_FILES)));/cache.addAll(FULL_CACHE)).then(() => self.skipWaiting()));/' "$SW"
sed -i "s/^self.addEventListener('activate', (event) => {/&\n\tevent.waitUntil(self.clients.claim());/" "$SW"
sed -i 's/^const CACHEABLE_FILES = \["index.wasm","index.pck"\];/const CACHEABLE_FILES = ["index.wasm","index.pck","index.png"];/' "$SW"
grep -q "addAll(FULL_CACHE)" "$SW" || { echo "Service worker patch failed" >&2; exit 1; }
echo "Built build/web/index.html"

#!/usr/bin/env bash
# Builds the browser version into build/web/. Usage: GODOT=/path/to/godot tools/export_web.sh
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
"$GODOT" --headless --import >/dev/null 2>&1 || true
"$GODOT" --headless --script res://tools/build_theme.gd
mkdir -p build/web
"$GODOT" --headless --export-release "Web" build/web/index.html
echo "Built build/web/index.html"

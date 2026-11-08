#!/usr/bin/env bash
# Rendered evidence. Uses the real display if present, else Xvfb (+ Mesa lavapipe for Vulkan).
set -euo pipefail
cd "$(dirname "$0")/../.."
GODOT="${GODOT:-godot}"
if [ -n "${DISPLAY:-}" ]; then
  "$GODOT" --path . --rendering-driver vulkan res://tests/CaptureRunner.tscn -- --qa "$@"
else
  xvfb-run -a -s "-screen 0 1280x720x24" "$GODOT" --path . --rendering-driver vulkan res://tests/CaptureRunner.tscn -- --qa "$@"
fi

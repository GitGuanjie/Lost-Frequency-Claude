#!/usr/bin/env bash
# Engine-executed QA for LOST FREQUENCY. Usage: scripts/qa/run_all.sh [--levels=L000,L005]
set -euo pipefail
cd "$(dirname "$0")/../.."
GODOT="${GODOT:-godot}"
"$GODOT" --headless --path . --import
timeout "${QA_TIMEOUT:-3600}" "$GODOT" --headless --path . --fixed-fps 60 res://tests/QARunner.tscn -- --qa "$@"

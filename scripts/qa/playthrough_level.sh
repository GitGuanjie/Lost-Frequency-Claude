#!/usr/bin/env bash
# One level: QA suite (load/spawn/exits/nav/bot/determinism) + rendered stills.
# Usage: scripts/qa/playthrough_level.sh L000
set -euo pipefail
cd "$(dirname "$0")/../.."
L="${1:?stable id, e.g. L000}"
scripts/qa/run_all.sh --suite=levels --levels="$L"
scripts/qa/capture.sh --levels="$L"

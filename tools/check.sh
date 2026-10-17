#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
test_dir="$(mktemp -d /tmp/pixel-panic-check.XXXXXX)"
trap 'rm -rf -- "$test_dir"' EXIT
export XDG_CONFIG_HOME="$test_dir/config"
export XDG_DATA_HOME="$test_dir/data"
export XDG_CACHE_HOME="$test_dir/cache"
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME"
cd "$project_dir"
godot --headless --editor --import --quit > "$test_dir/import.log" 2>&1
if rg -n 'SCRIPT ERROR|ERROR:' "$test_dir/import.log"; then exit 1; fi
godot --headless --script tests/smoke.gd -- --test > "$test_dir/tests.log" 2>&1
cat "$test_dir/tests.log"
if rg -n 'SCRIPT ERROR|ERROR:|FAIL ' "$test_dir/tests.log"; then exit 1; fi
godot --headless --script tests/playability.gd -- --test > "$test_dir/playability.log" 2>&1
cat "$test_dir/playability.log"
if rg -n 'SCRIPT ERROR|ERROR:|PLAYABILITY FAIL' "$test_dir/playability.log"; then exit 1; fi

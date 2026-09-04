#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ -n "${GODOT_BIN:-}" ]]; then
  godot_bin="$GODOT_BIN"
elif command -v godot >/dev/null 2>&1; then
  godot_bin="$(command -v godot)"
elif [[ -x /Applications/Godot.app/Contents/MacOS/Godot ]]; then
  godot_bin=/Applications/Godot.app/Contents/MacOS/Godot
else
  echo 'Install Godot 4.7 or set GODOT_BIN to its executable.' >&2
  exit 1
fi

log_dir="$(mktemp -d "${TMPDIR:-/tmp}/water-carrier-tests.XXXXXX")"
trap 'rm -rf "$log_dir"' EXIT

run_godot() {
  if ! "$godot_bin" --headless --path . "$@" >"$log_dir/output" 2>&1; then
    cat "$log_dir/output"
    return 1
  fi
  # Godot can report script-load errors while returning a successful exit code.
  if grep -Eq '^(SCRIPT ERROR|ERROR):' "$log_dir/output"; then
    cat "$log_dir/output"
    return 1
  fi
}

run_godot --editor --import --quit
for script in scripts/*.gd tools/*.gd; do
  run_godot --check-only --script "$script"
done
echo 'GDScript checks passed.'
for test in tools/test_*.gd tools/smoke_*.gd; do
  run_godot --script "$test"
  cat "$log_dir/output"
done

#!/usr/bin/env bash
# Load the vimrc headlessly and check that the custom keybindings are defined.
# Runs against the repo's vimrc, so it works before and after 'vim-mgr install'.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$(mktemp)"
trap 'rm -f "$OUT"' EXIT

echo "=> Testing keybindings in vimrc..."
status=0
VIM_MGR_TEST_OUT="$OUT" vim -E -s -u "$ROOT/vimrc" -i NONE -S "$ROOT/tests/check-mappings.vim" </dev/null || status=$?
cat "$OUT"

if [ "$status" -ne 0 ]; then
    echo "Some checks failed."
    exit 1
fi
echo "All custom keybindings are properly defined!"

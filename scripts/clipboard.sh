#!/usr/bin/env bash
# Platform-agnostic "copy to system clipboard" filter.
#
# Reads the selection on stdin and hands it to whatever native clipboard tool
# this OS provides. Used by <leader>y when Vim has no working +clipboard.
#
# This only covers the *native local* clipboard. Over SSH, vim-mgr also emits
# an OSC 52 escape, which carries the selection to your local terminal (or to
# tmux with set-clipboard on). Together they mean "always reach the system
# clipboard" no matter where Vim is running.
#
# exec is used so stdin streams straight through byte-for-byte (no trailing
# newline mangling from a command substitution).
set -euo pipefail

if command -v pbcopy >/dev/null 2>&1; then
  exec pbcopy                                   # macOS
elif [ -n "${WAYLAND_DISPLAY:-}" ] && command -v wl-copy >/dev/null 2>&1; then
  exec wl-copy                                  # Linux / Wayland
elif [ -n "${DISPLAY:-}" ] && command -v xclip >/dev/null 2>&1; then
  exec xclip -selection clipboard               # Linux / X11
elif [ -n "${DISPLAY:-}" ] && command -v xsel >/dev/null 2>&1; then
  exec xsel --clipboard --input                 # Linux / X11 (alternate)
elif command -v clip.exe >/dev/null 2>&1; then
  exec clip.exe                                 # Windows / WSL
else
  # No native tool here (e.g. a headless SSH host). Drain stdin so the pipe
  # closes cleanly; the OSC 52 escape still delivers the copy over SSH.
  exec cat >/dev/null
fi

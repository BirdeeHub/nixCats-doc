#!/usr/bin/env bash
SRCPATH="$(dirname "$(realpath "$0")")"
OUTPATH=${1:-"$SRCPATH/tmp"}
if [ -n "$2" ]; then
    nix run --show-trace --override-input nixCats "$2" "$SRCPATH" -- "$OUTPATH"
else
    nix run --show-trace "$SRCPATH" -- "$OUTPATH"
fi

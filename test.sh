#!/usr/bin/env bash
[ "$1" == "--remote" ] && shift 1 && remoteUp="true"
SRCPATH="$(dirname "$(realpath "$0")")"
OUTPATH=${1:-"$SRCPATH/tmp"}
if [ -n "$NIXCATSPATH" ]; then
    nix run --refresh --show-trace --no-write-lock-file --override-input nixCats "$NIXCATSPATH" "$SRCPATH" -- "$OUTPATH"
elif [ "$remoteUp" == "true" ]; then
    nix run --refresh --show-trace --no-write-lock-file github:BirdeeHub/nixCats-doc -- "$OUTPATH"
else
    nix run --refresh --show-trace --no-write-lock-file "$SRCPATH" -- "$OUTPATH"
fi

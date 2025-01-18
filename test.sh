#!/usr/bin/env bash
[ "$1" == "--remote" ] && shift 1 && remoteUp="true"
SRCPATH="$(dirname "$(realpath "$0")")"
OUTPATH=${1:-"$SRCPATH/tmp"}
refresh=${2:-"false"}
if [ -n "$NIXCATSPATH" ]; then
    if [ "$refresh" == "true" ]; then
        nix run --refresh --show-trace --no-write-lock-file --override-input nixCats "$NIXCATSPATH" "$SRCPATH" -- "$OUTPATH"
    else
        nix run --show-trace --no-write-lock-file --override-input nixCats "$NIXCATSPATH" "$SRCPATH" -- "$OUTPATH"
    fi
elif [ "$remoteUp" == "true" ]; then
    if [ "$refresh" == "true" ]; then
        nix run --refresh --show-trace --no-write-lock-file github:BirdeeHub/nixCats-doc -- "$OUTPATH"
    else
        nix run --show-trace --no-write-lock-file github:BirdeeHub/nixCats-doc -- "$OUTPATH"
    fi
else
    if [ "$refresh" == "true" ]; then
        nix run --refresh --show-trace --no-write-lock-file "$SRCPATH" -- "$OUTPATH"
    else
        nix run --show-trace --no-write-lock-file "$SRCPATH" -- "$OUTPATH"
    fi
fi

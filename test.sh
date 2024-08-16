#!/usr/bin/env bash
OUTPATH=${1:-"$(dirname "$(realpath "$0")")/tmp"}
# nix run --refresh --show-trace --no-write-lock-file github:BirdeeHub/nixCats-site-gen -- "$OUTPATH"
nix run --refresh --show-trace --no-write-lock-file . -- "$OUTPATH"

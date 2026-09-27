#!/usr/bin/env bash
# Wrapper for the vendored Godot binary (see docs/ENVIRONMENT.md).
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec "$DIR/.tools/godot/Godot_v4.7.2-stable_linux.x86_64" "$@"

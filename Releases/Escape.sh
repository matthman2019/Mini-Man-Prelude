#!/bin/sh
printf '\033c\033]0;%s\a' Escape
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Escape.x86_64" "$@"

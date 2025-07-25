#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_FILE="$SCRIPT_DIR/.latest-save"
ROLES=("quarry")

if [[ "${1:-}" == "--set-save" ]]; then
    NEW_ROOT="$2"
    if [[ ! -d "$NEW_ROOT" ]]; then
        echo "Error: '$NEW_ROOT' is not a directory" >&2
        exit 1
    fi
    echo "$NEW_ROOT" > "$CACHE_FILE"
    echo "Save folder set to: $NEW_ROOT"
    exit 0
fi

ROLE="$1"
TARGET_ID="$2"

if [[ ! -f "$CACHE_FILE" ]]; then
    echo "Error: Save cache file doesn't exist. Run: $0 --set-save <SAVE_DIR>" >&2
    exit 1
fi

SAVE_DIR="$(cat "$CACHE_FILE")"
TARGET_DIR=$(find "$SAVE_DIR/computercraft" -type d -name "$TARGET_ID" 2>/dev/null | head -n 1 || true)

if [[ -z "$TARGET_DIR" || ! -d "$TARGET_DIR" ]]; then
    echo "Error: Computer dir '$TARGET_ID' not found in save '$SAVE_DIR'" >&2
    exit 1
fi

role_valid=false
for r in "${ROLES[@]}"; do
    if [[ "$r" == "$ROLE" ]]; then
        role_valid=true
        break
    fi
done

if [[ "$role_valid" == false ]]; then
    echo "Error: Role '$ROLE' is not supported" >&2
    exit 1
fi

for role in "$ROLE" "shared"; do
    if [[ ! -d "$role" ]]; then
        echo "Warning: role dir '$role' does not exist, skipping."
        continue
    fi

    find "$role" -type f | while read -r file; do
        target_path="$TARGET_DIR/$(basename "$file")"

        if [[ -e "$target_path" ]]; then
            if [[ -L "$target_path" ]]; then
                rm "$target_path"
            else
                echo "Error: '$target_path' exists and is not a symlink" >&2
                exit 1
            fi
        fi

        ln -s "$(realpath "$file")" "$target_path"
        echo "Linked: $file → $target_path"
    done
done


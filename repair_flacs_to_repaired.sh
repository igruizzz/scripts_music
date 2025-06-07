#!/bin/bash

# Set root directory to current folder or provided argument
ROOT_DIR="${1:-.}"
REPAIRED_DIR="$ROOT_DIR/repaired"

# Create repaired root folder
mkdir -p "$REPAIRED_DIR"
TMP_DIR=$(mktemp -d)

echo "Scanning for FLACs in: $ROOT_DIR"
echo "Saving repaired FLACs to: $REPAIRED_DIR"
echo "Temporary working dir: $TMP_DIR"

find "$ROOT_DIR" -type f -iname "*.flac" | while read -r flac_file; do
    echo ""
    echo "🔧 Processing: $flac_file"

    # Build path under repaired/ with the same relative structure
    rel_path="${flac_file#$ROOT_DIR/}"
    repaired_path="$REPAIRED_DIR/$rel_path"
    repaired_dir="$(dirname "$repaired_path")"
    base_name="$(basename "$flac_file" .flac)"

    # Prepare temporary WAV
    wav_file="$TMP_DIR/$base_name.wav"
    flac -d -o "$wav_file" "$flac_file"
    if [ $? -ne 0 ]; then
        echo "❌ Failed to decode $flac_file"
        continue
    fi

    # Encode clean FLAC
    mkdir -p "$repaired_dir"
    flac -o "$repaired_path" "$wav_file"
    if [ $? -ne 0 ]; then
        echo "❌ Failed to encode $base_name.wav"
        continue
    fi

    # Copy tags
    if command -v metaflac >/dev/null 2>&1; then
        TAGS_FILE="$TMP_DIR/tags.txt"
        metaflac --export-tags-to="$TAGS_FILE" "$flac_file"
        metaflac --remove-all-tags "$repaired_path"
        metaflac --import-tags-from="$TAGS_FILE" "$repaired_path"
    fi

    echo "✅ Repaired file saved to: $repaired_path"
done

# Cleanup
rm -rf "$TMP_DIR"
echo ""
echo "🎉 All done! Repaired FLACs are in: $REPAIRED_DIR"

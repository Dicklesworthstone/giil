#!/usr/bin/env bash
# Generate binary test fixtures for magic byte detection tests
# Run once to create the fixture files

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAGIC_DIR="$SCRIPT_DIR/magic-bytes"
IMAGES_DIR="$SCRIPT_DIR/images"

mkdir -p "$MAGIC_DIR" "$IMAGES_DIR"

echo "Generating magic byte fixtures..."

# JPEG magic bytes: FF D8 FF E0 (JFIF) or FF D8 FF E1 (EXIF)
printf '\xFF\xD8\xFF\xE0\x00\x10JFIF\x00\x01' > "$MAGIC_DIR/jpeg-magic.bin"
echo "  Created jpeg-magic.bin"

# PNG magic bytes: 89 50 4E 47 0D 0A 1A 0A
printf '\x89PNG\r\n\x1A\n' > "$MAGIC_DIR/png-magic.bin"
echo "  Created png-magic.bin"

# GIF magic bytes: GIF89a or GIF87a
printf 'GIF89a' > "$MAGIC_DIR/gif-magic.bin"
echo "  Created gif-magic.bin"

# WebP magic bytes: RIFF....WEBP
printf 'RIFF\x00\x00\x00\x00WEBP' > "$MAGIC_DIR/webp-magic.bin"
echo "  Created webp-magic.bin"

# HEIC magic bytes: ....ftypheic or ....ftypmif1
printf '\x00\x00\x00\x18ftypheic' > "$MAGIC_DIR/heic-magic.bin"
echo "  Created heic-magic.bin"

# HTML document start
printf '<!DOCTYPE html>\n<html>' > "$MAGIC_DIR/html-magic.bin"
echo "  Created html-magic.bin"

# XML document start
printf '<?xml version="1.0"' > "$MAGIC_DIR/xml-magic.bin"
echo "  Created xml-magic.bin"

# BMP magic bytes
printf 'BM' > "$MAGIC_DIR/bmp-magic.bin"
echo "  Created bmp-magic.bin"

# TIFF little-endian
printf 'II\x2A\x00' > "$MAGIC_DIR/tiff-le-magic.bin"
echo "  Created tiff-le-magic.bin"

# TIFF big-endian
printf 'MM\x00\x2A' > "$MAGIC_DIR/tiff-be-magic.bin"
echo "  Created tiff-be-magic.bin"

echo ""
echo "Generating minimal sample images..."

# Create minimal valid PNG (1x1 red pixel)
# This is a complete valid PNG file
printf '\x89PNG\r\n\x1A\n' > "$IMAGES_DIR/sample-png.png"
# IHDR chunk (13 bytes data)
printf '\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xDE' >> "$IMAGES_DIR/sample-png.png"
# IDAT chunk (minimal deflate of raw RGB pixel)
printf '\x00\x00\x00\x0CIDAT\x08\xD7c\xF8\xCF\xC0\x00\x00\x00\x03\x00\x01\x00\x18\xDD\x8D\xB4' >> "$IMAGES_DIR/sample-png.png"
# IEND chunk
printf '\x00\x00\x00\x00IEND\xAEB`\x82' >> "$IMAGES_DIR/sample-png.png"
echo "  Created sample-png.png (1x1 red pixel)"

echo ""
echo "Done! Fixtures are in: $SCRIPT_DIR"
echo ""
echo "Note: For JPEG with EXIF, use a real photo or ImageMagick:"
echo "  convert -size 1x1 xc:red -set EXIF:DateTimeOriginal '2025:01:01 12:00:00' sample-jpeg-with-exif.jpg"

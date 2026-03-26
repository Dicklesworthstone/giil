# Four-Tier Capture Strategy

## Table of Contents
- [Overview](#overview)
- [Tier 1: Download Button](#tier-1-download-button)
- [Tier 2: Network Interception](#tier-2-network-interception)
- [Tier 3: Element Screenshot](#tier-3-element-screenshot)
- [Tier 4: Viewport Screenshot](#tier-4-viewport-screenshot)
- [Verification Pipeline](#verification-pipeline)
- [Image Processing](#image-processing)

---

## Overview

giil implements a fallback strategy to maximize reliability across different cloud platforms and page states.

```
Tier 1: Download Button (Highest Quality)
    ↓ (if fails)
Tier 2: Network Interception (Full Resolution)
    ↓ (if fails)
Tier 3: Element Screenshot
    ↓ (if fails)
Tier 4: Viewport Screenshot (Last Resort)
```

---

## Tier 1: Download Button

**Quality:** Highest (original file)

- Locates visible Download button using 9 selector patterns
- Clicks and waits for browser download event
- Obtains **original file** (no re-encoding losses)
- Works with HEIC/HEIF originals

---

## Tier 2: Network Interception

**Quality:** Full resolution

- Monitors all HTTP responses for CDN patterns (`cvws.icloud-content.com`, etc.)
- Filters by content-type (image formats only)
- Captures largest image buffer (>10KB threshold to skip thumbnails)
- Works even if UI elements are obscured

---

## Tier 3: Element Screenshot

**Quality:** Display resolution

- Queries for image elements using 10 selector patterns
- Verifies element is visible and ≥100×100 pixels
- Takes PNG screenshot of the element

---

## Tier 4: Viewport Screenshot

**Quality:** Viewport size (1920×1080)

- Captures visible viewport
- Always succeeds if page loads
- Useful for debugging page state

---

## Verification Pipeline

### 1. Content-Type Validation
Validates HTTP `Content-Type` matches expected image types.

### 2. Magic Bytes Detection
Verifies binary signature regardless of server claims:

| Format | Magic Bytes |
|--------|-------------|
| JPEG | `FF D8 FF` |
| PNG | `89 50 4E 47` |
| GIF | `47 49 46 38` |
| WebP | RIFF container with WEBP |
| HEIC/HEIF | ISO base media file (ftyp box) |

### 3. HTML Error Page Detection
Rejects HTML content that indicates an error page instead of an image.

---

## Image Processing

### EXIF Datetime Extraction

Priority order for filename generation:
1. `DateTimeOriginal` (when photo was taken)
2. `CreateDate`
3. `DateTimeDigitized`
4. `ModifyDate`
5. Current time (fallback)

### HEIC/HEIF Conversion

| Platform | Tool | Notes |
|----------|------|-------|
| macOS | `sips` | Built-in, always available |
| Linux | `heif-convert` | Requires `libheif-examples` package |

### MozJPEG Compression (Default)

By default, giil compresses with MozJPEG for optimal size/quality:
- **40-50% smaller** than standard JPEG at equivalent quality
- **Quality 85** (configurable via `--quality`)
- Use `--preserve` to keep original bytes

### Filename Format

```
icloud_YYYYMMDD_HHMMSS[_NNN][_counter].jpg
        │              │      │
        │              │      └── Collision counter (if file exists)
        │              └── Album index (--all mode only)
        └── Date/time from EXIF or capture time
```

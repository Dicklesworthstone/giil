---
name: giil
description: >-
  Download full-resolution images from iCloud, Dropbox, Google Photos share links.
  Use when extracting images from cloud share URLs, remote debugging with screenshots,
  or downloading shared photo albums.
---

<!-- TOC: Quick Start | THE EXACT PROMPT | Supported Platforms | Output Modes | References -->

# GIIL — Get Image [from] Internet Link

> **Core Capability:** Zero-setup CLI that downloads full-resolution images from cloud photo shares. The missing link between iPhone screenshots and remote AI coding sessions.

## Quick Start

```bash
# Install
curl -fsSL "https://raw.githubusercontent.com/Dicklesworthstone/giil/main/install.sh?v=3.0.0" | bash

# Download single image
giil "https://share.icloud.com/photos/02cD9okNHvVd-uuDnPCH3ZEEA"

# JSON output (best for AI workflows)
giil "https://share.icloud.com/photos/..." --json

# Download entire album
giil "https://share.icloud.com/photos/..." --all --output ~/album
```

**Note:** First run downloads Playwright Chromium (~200MB, cached in `~/.cache/giil/`).

---

## THE EXACT PROMPT — Remote AI Debugging Workflow

```
iPhone Screenshot → iCloud Sync → Photos.app Share Link → Paste to SSH → giil Downloads → AI Analyzes
```

```bash
# Get image for AI analysis
IMAGE_PATH=$(giil "https://share.icloud.com/photos/XXX" --output /tmp 2>/dev/null)
# AI can now read the image at $IMAGE_PATH
```

---

## THE EXACT PROMPT — Output Modes

```bash
# Default: file path to stdout
giil "https://share.icloud.com/photos/XXX"
# stdout: /current/dir/icloud_20240115_143245.jpg

# JSON mode (best for programmatic use)
giil "..." --json
# {"ok": true, "path": "/absolute/path/...", "width": 4032, "height": 3024}

# Base64 mode (no file saved)
giil "..." --base64 | base64 -d > image.jpg

# URL-only mode (get CDN URL without downloading)
giil "..." --print-url
```

---

## Supported Platforms

| Platform | URL Patterns | Browser Required |
|----------|--------------|------------------|
| **iCloud** | `share.icloud.com/photos/*` | Yes |
| **Dropbox** | `dropbox.com/s/*`, `dropbox.com/scl/fi/*` | **No** (fast) |
| **Google Photos** | `photos.app.goo.gl/*`, `photos.google.com/share/*` | Yes |
| **Google Drive** | `drive.google.com/file/d/*` | Yes |

**Dropbox Fast Path:** Direct curl download, 1-2 seconds, no browser overhead.

---

## Essential Options

| Flag | Description |
|------|-------------|
| `--output DIR` | Output directory (default: `.`) |
| `--json` | Output JSON metadata |
| `--all` | Download all photos from album |
| `--preserve` | Keep original bytes (skip compression) |
| `--convert FMT` | Convert to: `jpeg`, `png`, `webp` |
| `--quality N` | JPEG quality 1-100 (default: 85) |
| `--base64` | Output base64 to stdout |
| `--timeout N` | Page load timeout in seconds (default: 60) |
| `--debug` | Save debug artifacts on failure |

---

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success |
| `10` | Network error |
| `11` | Auth required (link not public) |
| `12` | Not found (expired/deleted) |
| `13` | Unsupported type (video, doc) |

---

## References

| Topic | Reference |
|-------|-----------|
| Full command reference | [COMMANDS.md](references/COMMANDS.md) |
| Four-tier capture strategy | [CAPTURE-STRATEGY.md](references/CAPTURE-STRATEGY.md) |
| Troubleshooting | [TROUBLESHOOTING.md](references/TROUBLESHOOTING.md) |

# GIIL Commands — Complete Reference

## Table of Contents
- [Basic Usage](#basic-usage)
- [All Options](#all-options)
- [Output Modes](#output-modes)
- [Album Mode](#album-mode)
- [Environment Variables](#environment-variables)
- [File Locations](#file-locations)

---

## Basic Usage

```bash
giil <url> [options]
```

---

## All Options

| Flag | Default | Description |
|------|---------|-------------|
| `--output DIR` | `.` | Output directory |
| `--preserve` | off | Keep original bytes (skip MozJPEG compression) |
| `--convert FMT` | — | Convert to: `jpeg`, `png`, `webp` |
| `--quality N` | `85` | JPEG quality 1-100 |
| `--base64` | off | Output base64 to stdout (no file saved) |
| `--json` | off | Output JSON metadata |
| `--all` | off | Download all photos from album |
| `--timeout N` | `60` | Page load timeout in seconds |
| `--debug` | off | Save debug artifacts on failure |
| `--verbose` | off | Show detailed progress |
| `--trace` | off | Enable Playwright tracing for deep debugging |
| `--print-url` | off | Output resolved CDN URL (don't download) |
| `--debug-dir DIR` | `.` | Directory for debug artifacts |
| `--update` | off | Force reinstall dependencies |

---

## Output Modes

### Default: File Path

```bash
giil "https://share.icloud.com/photos/XXX"
# stdout: /current/dir/icloud_20240115_143245.jpg

# Scripting
IMAGE_PATH=$(giil "..." --output ~/Downloads 2>/dev/null)
```

### JSON Mode

```bash
giil "https://share.icloud.com/photos/XXX" --json
```

**Success:**
```json
{
  "ok": true,
  "schema_version": "1",
  "platform": "icloud",
  "path": "/absolute/path/to/icloud_20240115_143245.jpg",
  "datetime": "2024-01-15T14:32:45.000Z",
  "sourceUrl": "https://cvws.icloud-content.com/...",
  "method": "network",
  "size": 245678,
  "width": 4032,
  "height": 3024
}
```

**Error:**
```json
{
  "ok": false,
  "schema_version": "1",
  "platform": "icloud",
  "error": {
    "code": "AUTH_REQUIRED",
    "message": "Login required - link is not publicly shared",
    "remediation": "The file is not publicly shared. The owner must enable public access."
  }
}
```

### Base64 Mode

```bash
# Decode to file
giil "..." --base64 | base64 -d > image.jpg

# Create data URI
echo "data:image/jpeg;base64,$(giil '...' --base64)" > uri.txt

# Pipe to API
giil "..." --base64 | curl -X POST -d @- https://api.example.com/upload
```

### URL-Only Mode

```bash
giil "https://share.icloud.com/photos/XXX" --print-url
# stdout: https://cvws.icloud-content.com/B/...
```

---

## Album Mode

Download entire shared albums with `--all`:

```bash
giil "https://share.icloud.com/photos/XXX" --all --output ~/album
```

### How It Works

1. Load album page
2. Detect thumbnail grid (11 selector strategies)
3. For each thumbnail: click → capture → close → next
4. Output one path/JSON per photo

### Features

- **Resilient:** Continues to next photo if one fails
- **Indexed filenames:** `_001`, `_002`, etc. for ordering
- **Rate limiting:** 1 second delay between photos
- **Exponential backoff:** Automatic retry on rate limit signals

### Output

```bash
# Default
/path/to/album/icloud_20240115_143245_001.jpg
/path/to/album/icloud_20240115_143246_002.jpg

# With --json
{"path": "...001.jpg", "method": "download", "width": 4032, ...}
{"path": "...002.jpg", "method": "network", "width": 3024, ...}
```

---

## Environment Variables

### Runtime Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `XDG_CACHE_HOME` | Base cache directory | `~/.cache` |
| `GIIL_HOME` | giil runtime directory | `$XDG_CACHE_HOME/giil` |
| `PLAYWRIGHT_BROWSERS_PATH` | Custom Chromium cache | `$GIIL_HOME/ms-playwright` |
| `GIIL_NO_GUM` | Disable gum styling | unset |
| `GIIL_CHECK_UPDATES` | Enable update checking | unset |

### Installer Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DEST` | Custom install directory | `~/.local/bin` |
| `GIIL_SYSTEM` | Install to `/usr/local/bin` | unset |
| `GIIL_VERIFY` | Verify SHA256 checksum | unset |
| `GIIL_VERSION` | Install specific version | latest |

---

## File Locations

| Path | Purpose |
|------|---------|
| `~/.local/bin/giil` | Main script |
| `~/.cache/giil/` | Runtime directory |
| `~/.cache/giil/node_modules/` | Playwright, Sharp, exifr |
| `~/.cache/giil/extractor.mjs` | Generated Node.js script |
| `~/.cache/giil/ms-playwright/` | Chromium browser cache |

### Debug Artifacts (with `--debug`)

| File | Contents |
|------|----------|
| `giil_debug_<timestamp>.png` | Full-page screenshot |
| `giil_debug_<timestamp>.html` | Page DOM content |

---

## Exit Codes

| Code | Name | Description |
|------|------|-------------|
| `0` | Success | Image captured and saved/output |
| `1` | Capture Failure | All capture strategies failed |
| `2` | Usage Error | Invalid arguments or missing URL |
| `3` | Dependency Error | Node.js, Playwright, or Chromium issue |
| `10` | Network Error | Timeout, DNS failure, unreachable host |
| `11` | Auth Required | Login redirect, password required, not publicly shared |
| `12` | Not Found | Expired link, deleted file, 404 |
| `13` | Unsupported Type | Video, Google Doc, or non-image content |
| `20` | Internal Error | Bug in giil (please report!) |

**Scripting:**
```bash
giil "https://share.icloud.com/photos/XXX" 2>/dev/null
case $? in
    0) echo "Success!" ;;
    10) echo "Network issue - retry later" ;;
    11) echo "Link not public - ask owner to share" ;;
    12) echo "Link expired" ;;
    *) echo "Failed with code $?" ;;
esac
```

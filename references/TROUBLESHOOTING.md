# GIIL Troubleshooting

## Table of Contents
- [Common Errors](#common-errors)
- [Debugging Commands](#debugging-commands)
- [Installation Issues](#installation-issues)
- [Performance](#performance)

---

## Common Errors

### "Auth required" error
The link isn't publicly shared. Owner must enable public access in their cloud settings.

### Timeout errors
Increase timeout:
```bash
giil "..." --timeout 120
```

### Wrong/small image captured
Run with `--debug` to see page state. Report issue with debug artifacts.

### HEIC conversion fails on Linux
```bash
sudo apt-get install libheif-examples  # Debian/Ubuntu
sudo dnf install libheif-tools         # Fedora
```

### Chromium fails to launch
```bash
giil "..." --update
# Or manually:
cd ~/.cache/giil && npx playwright install --with-deps chromium
```

---

## Debugging Commands

```bash
# Verbose output
giil "..." --verbose

# Debug artifacts on failure
giil "..." --debug

# Playwright trace (generates trace.zip)
giil "..." --trace
npx playwright show-trace ~/.cache/giil/trace.zip
```

---

## Installation Issues

### Install
```bash
# One-liner (recommended)
curl -fsSL "https://raw.githubusercontent.com/Dicklesworthstone/giil/main/install.sh?v=3.0.0" | bash

# Verified installation
GIIL_VERIFY=1 curl -fsSL .../install.sh | bash

# System-wide
GIIL_SYSTEM=1 curl -fsSL .../install.sh | bash

# Manual
curl -fsSL https://raw.githubusercontent.com/Dicklesworthstone/giil/main/giil -o ~/.local/bin/giil
chmod +x ~/.local/bin/giil
```

### Uninstall
```bash
rm ~/.local/bin/giil
rm -rf ~/.cache/giil
rm -rf ~/.cache/ms-playwright  # If no other Playwright tools
```

---

## Performance

| Phase | First Run | Subsequent |
|-------|-----------|------------|
| Chromium download | 30-60s | Skipped (cached) |
| Browser launch | 2-3s | 2-3s |
| Page load | 3-10s | 3-10s |
| Image capture | 1-5s | 1-5s |
| **Total** | **40-80s** | **5-15s** |

**Dropbox:** 1-2 seconds (direct curl, no browser).

---

## Security & Privacy

- **Local execution:** All processing happens on your machine
- **No telemetry:** No data sent anywhere except to cloud services
- **No authentication stored:** Uses public share mechanism
- **No cookies saved:** Browser context is ephemeral
- **Temp file cleanup:** Downloaded files cleaned up after processing

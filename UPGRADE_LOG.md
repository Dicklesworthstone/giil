# Dependency Upgrade Log

**Date:** 2026-11-22  |  **Project:** giil  |  **Language:** Bash + Embedded Node.js (npm)

## Summary
- **Updated:** 2 embedded runtime dependencies (`playwright`, `sharp`)
- **Already latest:** 1 (`exifr` at `7.1.3` in both embedded runtime and dev manifest)
- **Skipped / Failed:** 0
- **Security audit (`npm audit`):** 0 vulnerabilities

## Runtime Dependency Upgrades (`giil` embedded `$GIIL_HOME/package.json`)

| Package | Old | New | Minimum Node.js | Notes |
|---------|-----|-----|-----------------|-------|
| playwright | 1.40.0 | 1.65.1 | >=20 | Installs Chromium 1255; verified on macOS arm64 and Ubuntu 22.04/24.04 x86_64 |
| sharp | 0.33.0 | 0.35.5 | >=20.10.0 (ESM) | Prebuilt platform binaries verified on macOS arm64 and Linux x86_64 (`dist/utility.mjs` uses `with { type: "json" }`) |
| exifr | 7.1.3 | 7.1.3 | — | Already latest stable in both `package.json` and embedded runtime |

## Migration & Compatibility Changes

- **Node.js minimum enforced (`>=20.10.0`)**: `ensure_node()` now checks the full semver triple via `node_version_meets_minimum()` and fails closed with exit code 3 (`EXIT_DEPENDENCY_ERROR`) and upgrade instructions on older Node.js releases (verified on Node 18.20.8 and Node 20.9.0 -> exit 3, and on Node 20.10.0 / 26.8.1 / 26.13.1 -> pass). Sharp's `ensure_playwright()` check also exercises the ESM `import 'sharp'` path matching `extractor.mjs`.
- **In-place cache adoption**: `$GIIL_HOME/.installed` now records the runtime spec (`playwright@1.65.1 sharp@0.35.5 exifr@7.1.3`). Existing caches with an empty legacy stamp or older pins automatically trigger an in-place reinstall on the next run.
- **First-run stdout cleanliness**: All `gum spin` and installer steps in `ensure_playwright()` redirect stdout to stderr so `--json`, `--format toon`, and bare path output are never corrupted on first run.
- **Minimal Linux & GNU Bash 4.0 compatibility**:
  - Guarded empty `_dropbox_urls[@]` array expansion under `set -u` for GNU Bash 4.0–4.3.
  - Added `detect_file_mime_type()` magic-byte and HTML/XML inspection so direct Dropbox downloads accurately reject HTML error pages (exit 11) and choose correct extensions even in minimal containers without `file(1)`.
- **iCloud share availability detection**: Added `classifyIcloudResolveResponse()` to fail cleanly with `NOT_FOUND` (exit 12) or `AUTH_REQUIRED` (exit 11) on expired/revoked/invalid iCloud links instead of saving a screenshot of the error page with exit 0.

## Verification

- **Unit tests**: 182/182 Node pure-function tests PASS; 46/46 Bash (`bats`) tests PASS.
- **Static analysis**: `shellcheck -S warning -e SC2155 -e SC2034 giil install.sh`, `bash -n`, embedded JS `node --check`, and `ubs` (0 criticals) PASS.
- **Real-service qualification (no mocks)**:
  - Verified on macOS (Node 26.8.1, Bash 5.3.9) and Ubuntu 24.04 with GNU Bash 4.0.0 + Node 26.13.1 (plus Node 20.10.0 ESM sharp verification and Node 20.9.0 / 18.20.8 exit-3 rejection).
  - Real Dropbox, Google Drive, and Google Photos downloads, single-browser multi-URL batching, mixed success/failure, all-failure, `GIIL_NO_BATCH=1`, network failure (`exit 10`), TOON output (`toon 0.3.0`), and in-place cache upgrade adoption all verified.
  - Expired/invalid iCloud links now fail cleanly with `NOT_FOUND` (exit 12); live iCloud success capture requires a fresh (<30-day) link via `GIIL_ICLOUD_TEST_URL`.
- **Paired same-host A/B benchmark (`v3.2.1` + Playwright 1.40.0/Chromium 1091 vs `v3.3.0` + Playwright 1.65.1/Chromium 1255)**:
  - `--help`: 14ms -> 14ms (+0.0%)
  - Google Drive: 5,832ms -> 5,476ms (-6.1% faster)
  - Google Photos: 14,901ms -> 9,187ms (-38.3% faster)
  - 2-URL batch (Drive + Photos): 11,282ms vs 14,663ms sequential (-23.1% faster)

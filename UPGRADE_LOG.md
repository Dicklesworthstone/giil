# Dependency Upgrade Log

**Date:** 2026-01-18  |  **Project:** giil  |  **Language:** Node.js (npm)

## Summary
- **Updated:** 1
- **Skipped:** 0
- **Failed:** 0
- **Needs attention:** 0

## Verification

- `npm update` - Successful (1 package added)

## 2026-10-08 release qualification

No dependency upgrade has been accepted or released in this pass. Direct runtime
and development dependencies were researched individually against the npm registry
and upstream release notes before any source version changes.

| Dependency | Current | Latest stable | Qualification |
|------------|---------|---------------|---------------|
| Playwright | 1.40.0 | 1.64.0 | Candidate runtime starts with its exact Chromium headless shell; full CLI/service and performance gates remain open. |
| Sharp | 0.33.0 | 0.35.5 | Upgrade pending its own runtime tests; requires Node >=20.9.0. |
| exifr | 7.1.3 | 7.1.3 | Already latest in both embedded runtime and development manifest. |

The current runtime pins are embedded in `giil`; `package.json` and its lockfile
only describe exifr for development tests. The source currently accepts Node 18.
Playwright 1.64.0 requires Node >=20, and Sharp 0.35.5 requires Node >=20.9.0.
An upgrade must explicitly migrate the runtime check and documentation, and verify
that an existing `.installed` cache actually adopts the new package versions.

Research sources:

- [Playwright 1.64.0 release](https://github.com/microsoft/playwright/releases/tag/v1.64.0), published 2026-10-07; npm registry `playwright/latest` reports 1.64.0 and Node >=20.
- [Sharp 0.35.0 breaking changes](https://sharp.pixelplumbing.com/changelog/v0.35.0/): Node 18 support and the automatic native build install script were removed; the latest npm stable is 0.35.5.
- npm registry `exifr/latest`: 7.1.3, matching the manifest and lockfile.
- [Official Node distribution index](https://nodejs.org/dist/index.json): latest stable 26.11.1, published 2026-10-07. Its official Darwin arm64 prebuilt was SHA256-verified and used only in retained qualification scratch; no global runtime was changed.

Verification completed:

- 172/172 Node pure-function tests, after repairing the obsolete context-aware JSON formatter extraction and call sites; the prior suite had 151 passes and 20 failures.
- 29/29 Bash tests; `bash -n`, Node syntax checks, and ShellCheck at warning severity with the repository's documented SC2034/SC2155 exclusions.
- Real Dropbox missing-link requests: old multi-URL wrapper returned 0; the corrected wrapper attempted both links and returned 11. Downloaded response files were retained.
- An artificial filesystem denial during embedded extractor generation previously yielded a zero-byte extractor and exit 0. The generation error is now explicitly returned as dependency error 3.

Release holds, without a claim of successful installer or browser E2E:

- Fresh npm installation under a filesystem no-unlink guard failed during cache cleanup. No compiler fallback or file deletion was permitted. Integrity-checked registry tarballs provided separate qualification runtimes, which do not establish fresh-installer success.
- Playwright 1.40.0's exact Chromium 1091 download returned HTTP 400 from both its old AzureEdge endpoint and the current official CDN mirror. An exact old-runtime performance baseline has not been obtained.
- Playwright 1.64.0's exact Chromium 1248 started. A byte-identical extracted JavaScript payload reached the repository's iCloud fixture and emitted a viewport screenshot; this does not establish full-resolution image capture, the expected checksum, or a valid live cloud fixture.
- The no-unlink guard prevents Bash's large heredoc temporary-file lifecycle and Playwright browser cleanup. No full browser exit-status, mixed-success/failure, TOON, supported Bash 4.0, installer, or ACFS acceptance gate is claimed.

Evidence is retained at
`/Users/jemanuel/projects/release_wave_2026_10_07/evidence/giil-qualification-20261008T2140/`
and `/Volumes/USB_NVME/giil-release-qualification-20261008T2140/`.
GitHub issue #5 remains open until the actual service and release gates are met.

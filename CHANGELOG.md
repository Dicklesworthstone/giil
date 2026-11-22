# Changelog

All notable changes to **giil** (Get Image [from] Internet Link) are documented here.

Organized by capability, not diff order. Each entry links to the relevant commit on GitHub.

Repository: <https://github.com/Dicklesworthstone/giil>

---

## [v3.3.0] -- 2026-11-22

**Multi-URL batches, honest exit codes, and a current browser runtime.** Closes [#5](https://github.com/Dicklesworthstone/giil/issues/5); builds on [#4](https://github.com/Dicklesworthstone/giil/issues/4).

### Multi-URL downloads

- Accept multiple URLs in one invocation ([5250df3](https://github.com/Dicklesworthstone/giil/commit/5250df39c39c768fc3c9748c99136fd466aaa90d)).
- Reuse one headless browser across all Playwright-handled URLs, with bounded tab concurrency (`GIIL_BATCH_CONCURRENCY`, default 3) and isolated browser contexts per URL ([d15d7ba](https://github.com/Dicklesworthstone/giil/commit/d15d7ba1b7ea2d8491cf4948842b30cd59f00806)). `GIIL_NO_BATCH=1` keeps the per-URL path.
- Failures are never reported as success: single, batch, and multi-Dropbox paths keep each child's exit status, every URL is still attempted, successful outputs are kept, and the run exits with the highest documented failure code. The Bash 4.3 `local -n` nameref was replaced with positional arguments and empty-array expansions are guarded under `set -u`, restoring GNU Bash 4.0 compatibility ([2af72f6](https://github.com/Dicklesworthstone/giil/commit/2af72f647c6ca040113a099f1b824d5b86c311f1)).
- A failed write of the embedded extractor now exits with dependency error 3 instead of continuing with an empty script ([31386f8](https://github.com/Dicklesworthstone/giil/commit/31386f8247370b52c09f992ae5e9945620b92a39)).
- Direct Dropbox downloads now inspect magic bytes and leading HTML/XML markers (`detect_file_mime_type`) before falling back to `file(1)`, so minimal Linux containers without `file` still reject HTML error pages with exit 11, assign accurate image extensions (including `.png` and `.avif`), and avoid overwriting files saved within the same second.

### iCloud

- Detect expired, revoked, and invalid iCloud shared links. iCloud renders a "Shared photos not available" page for these links, and the screenshot fallback used to save that page and exit 0. giil now reads iCloud's share-resolver status, which does not depend on the page language, and exits `NOT_FOUND` (12). Sign-in or permission failures exit `AUTH_REQUIRED` (11).
- iCloud web-app assets (logos, wallpaper, and the internal `test_images/orientation_test_image.jpeg` probe) are no longer considered as captured content.
- Note: iCloud links expire after 30 days. The default iCloud E2E fixture link has expired. Set `GIIL_ICLOUD_TEST_URL` and `GIIL_ICLOUD_EXPECTED_SHA` to qualify iCloud capture with a current link.

### Runtime and dependencies

- Embedded runtime upgraded: Playwright `1.40.0 -> 1.65.1` (Chromium 1255), Sharp `0.33.0 -> 0.35.5`, exifr `7.1.3` (already latest).
- **Node.js 20.10.0 or newer is now required** (Playwright 1.65 requires Node >= 20; Sharp 0.35's ESM entry uses `import ... with { type: "json" }`, introduced in Node 20.10.0). Older Node versions (including 20.9.0 and 18.x) fail early with exit code 3 and upgrade instructions instead of failing partway through.
- Existing caches built from older pins are upgraded in place on the next run. The runtime spec is recorded in `$GIIL_HOME/.installed`, and a missing or different stamp triggers a reinstall. Previously an existing cache was reused forever.
- First-run installer output (npm, the Chromium download, progress bars) now always goes to stderr. With `gum` installed, the Chromium download progress was written to stdout and corrupted `--json`, `--format toon`, and path output on the first run.

### Tests

- Repaired the obsolete JSON-formatter extraction in the Node suite ([5269a3c](https://github.com/Dicklesworthstone/giil/commit/5269a3cdf4e7335ecaf429323353e78bb7c5cb25)). New iCloud share-status unit tests bring the suite to 182 tests.
- Bash suite grows from 29 to 46 tests, adding Node minimum-version checks, cached-runtime adoption, stdout-leak guards for first-run installer steps, `file(1)`-free MIME/HTML detection, and Bash 4.0 empty-array safety.

---

## [v3.2.1] -- 2026-05-22

**HEIC brand coverage fix.** Follow-up to v3.2.0.

### Google Photos / `detectDownloadKind`

- Widen HEIF / HEIC magic-byte detection to recognize the full set of `ftyp` brands defined by ISO/IEC 23008-12, not just `heic` / `heif` / `mif1`:
  - Still images: `heic`, `heix`, `heim`, `heis` (10-bit and other HEIC variants).
  - Image sequences: `hevc`, `hevx`, `hevm`, `hevs`, `msf1` (Apple Live Photos and other HEIC image sequences).
- Add AVIF support: `ftyp avif` (still) and `ftyp avis` (sequence) are now classified as `image/avif` instead of falling through to `video/mp4`.
- Without this fix, a 10-bit HEIC (brand `heix`) or an Apple Live Photo (brand `msf1`) would be saved with a `.mp4` extension and the image pipeline would be skipped.
- Extension fallback now also accepts `.avif`.
- New unit tests cover `heix`, `msf1`, `hevc`, and `avif` brands.

---

## [v3.2.0] -- 2026-05-21

**Google Photos: download originals, not screenshots.** Fixes [#2](https://github.com/Dicklesworthstone/giil/issues/2).

### Google Photos

- Drive the viewer's native **`Shift+D`** download as the primary capture strategy for `photos.app.goo.gl` / `photos.google.com/share` links. This returns the **original uploaded file**:
  - **Single photo** -> full-quality original image (no longer a low-quality preview/screenshot).
  - **Single video** -> the original video file (previously giil saved a `.jpg`/`.png` poster frame of the first video frame).
  - **Album (`--all`)** -> a single `.zip` archive of all originals (previously each item was saved as an individual low-quality preview).
- **Fail loudly instead of silently downgrading:** when a Google Photos item is a video and no original can be downloaded, giil now exits with `UNSUPPORTED_TYPE` (exit code 13) and a clear message, rather than saving a poster-frame screenshot.
- Non-image originals (videos, ZIP archives) are written straight to disk with the correct extension, bypassing the image (Sharp) pipeline; `--json` reports a `media_kind` field.
- The `=s0` CDN fetch remains as an image-only fallback when the native download is unavailable.

### Maintenance

- Version bumped to 3.2.0 (`VERSION` + `giil` script).

---

## [Unreleased] -- after v3.1.0

19 commits since v3.1.0 (2026-01-13 through 2026-02-22). Rolled into the v3.2.0 release above.

### Image Extraction and Core Enhancements

- Improved image extraction logic with support for additional cloud storage URL patterns ([6aae707](https://github.com/Dicklesworthstone/giil/commit/6aae7076fc268f959bbde009a202b5172618fd2b))
- Enhanced giil script with better image link extraction, improved error handling, and enhanced cloud service support ([e9c247f](https://github.com/Dicklesworthstone/giil/commit/e9c247ff8f5521fb7803430eb1b59d036879d67e))
- Retry logic with exponential backoff for rate-limited requests ([6aae707](https://github.com/Dicklesworthstone/giil/commit/6aae7076fc268f959bbde009a202b5172618fd2b))

### AI Agent Integration

- Claude Code SKILL.md for automatic capability discovery -- enables Claude Code to understand giil's usage, platforms, capture strategies, output modes, and exit codes when opening the project ([c124309](https://github.com/Dicklesworthstone/giil/commit/c124309add5f1db1b2b6ce7731f82f10a902766b))

### Testing

- E2E test script for TOON format support ([e7c03f0](https://github.com/Dicklesworthstone/giil/commit/e7c03f0f978587526e9a102b44496dbd83bbdd7f))

### CI / Infrastructure

- ACFS notification workflow for installer changes ([8d956b7](https://github.com/Dicklesworthstone/giil/commit/8d956b75edfbd56db3e352380bed8297fe8a0ff0))
- notify-acfs workflow for ACFS lesson registry sync ([e148569](https://github.com/Dicklesworthstone/giil/commit/e14856919f017401e8aa846a597fd7b7803fa389))
- ACFS checksum update notification workflow and dispatch ([e513d76](https://github.com/Dicklesworthstone/giil/commit/e513d76c36d8babac9530956f93e6d37073522ca), [ad51850](https://github.com/Dicklesworthstone/giil/commit/ad518507dd36853712b4620d9df1db313a92942c))
- Improved GitHub Actions workflows with best practices ([43def97](https://github.com/Dicklesworthstone/giil/commit/43def97aa2fe51e3cabfe9f736fd2b980f90675e))
- Handle exit code 77 (skip) in E2E tests ([0025925](https://github.com/Dicklesworthstone/giil/commit/00259251041086361b993022d3e75eae87845877))

### Licensing and Branding

- License updated to MIT with OpenAI/Anthropic Rider -- restricts use by OpenAI, Anthropic, and affiliates without express written permission ([4182374](https://github.com/Dicklesworthstone/giil/commit/41823743e7d4bee961cae458b698e1d152af3ec9))
- README updated to reference new license terms ([830459c](https://github.com/Dicklesworthstone/giil/commit/830459cfff5d0fedae9aec2301b72961c3818f79))
- GitHub social preview image added ([72b45be](https://github.com/Dicklesworthstone/giil/commit/72b45be6a966bc7191a9dc91ec266b285f0bbb44))

### Maintenance

- Node.js dependencies updated to latest stable versions ([404e63a](https://github.com/Dicklesworthstone/giil/commit/404e63a952eee11b79656114513a7a9cc29ab84e))
- .DS_Store added to .gitignore ([21e17cc](https://github.com/Dicklesworthstone/giil/commit/21e17cc8b9d30511f16d0d97e3957098f9240b08))
- Ephemeral beads file patterns added to .gitignore ([7182811](https://github.com/Dicklesworthstone/giil/commit/7182811d0296f9a8a9cbb3e964a743612ec7e76e))

---

## [v3.1.0] -- 2026-01-04 (GitHub Release)

**UX Overhaul & Multi-Platform Branding** -- 7 commits over v3.0.0.

Tag: [`v3.1.0`](https://github.com/Dicklesworthstone/giil/releases/tag/v3.1.0) points to commit [`32aad7d`](https://github.com/Dicklesworthstone/giil/commit/32aad7d8a7b63d57a0aee221978d2ec8bc51ce24).

Release: <https://github.com/Dicklesworthstone/giil/releases/tag/v3.1.0> (207 downloads of the giil script as of this writing).

### Identity and Branding

- Project renamed from "Get iCloud Image Link" to **"Get Image [from] Internet Link"** to reflect multi-platform scope ([5562f5b](https://github.com/Dicklesworthstone/giil/commit/5562f5b461cb9b8cecaf851e1a9b42a03b957b22))
- GitHub repository renamed from `get_icloud_image_link` to `giil`
- Icon changed from Apple emoji to platform-agnostic camera emoji
- Complete branding update across all documentation, banners, and help text ([666f459](https://github.com/Dicklesworthstone/giil/commit/666f4595b3c5488a30f46c5d77b5587db4e7dac8), [140a363](https://github.com/Dicklesworthstone/giil/commit/140a363ce30c13a64513791aa46cfd369e55b5c8))

### CLI User Experience

- Gum-styled help output with graceful ASCII fallback ([5562f5b](https://github.com/Dicklesworthstone/giil/commit/5562f5b461cb9b8cecaf851e1a9b42a03b957b22))
- New `--quiet` / `-q` flag for suppressing progress messages
- Gum spinners during npm and Chromium installation
- Consistent logging: `info`/`verbose` helpers respect quiet mode

### Output Naming and Metadata

- Platform-specific filename prefixes: `icloud_`, `dropbox_`, `gphotos_`, `gdrive_` ([d33908a](https://github.com/Dicklesworthstone/giil/commit/d33908a85b07b0c90838d118bbe9933e8a0e5d77))
- Datetime extraction added to Dropbox JSON output ([d33908a](https://github.com/Dicklesworthstone/giil/commit/d33908a85b07b0c90838d118bbe9933e8a0e5d77))

### Bug Fixes

- Install exifr dependency for unit tests ([a99ec13](https://github.com/Dicklesworthstone/giil/commit/a99ec137eacf97162d08515beaf088869f8d4932))
- Wrap test suites in parent `describe` for proper async `before()` handling ([11f1a6a](https://github.com/Dicklesworthstone/giil/commit/11f1a6a90f5dfdeefcf11afe98736f4bb71e0283))

### Supported Platforms (as of v3.1.0)

| Platform | URL Pattern | Capture Method |
|----------|-------------|----------------|
| iCloud Photos | `share.icloud.com/photos/...` | 4-tier capture (download button, CDN interception, element screenshot, viewport) |
| Dropbox | `dropbox.com/s/...` | Direct URL download (no Playwright needed) |
| Google Photos | `photos.app.goo.gl/...` | CDN interception with `=s0` full-resolution modifier |
| Google Drive | `drive.google.com/file/d/...` | Multi-tier (download button, direct URL, thumbnail, screenshot) |

---

## [v3.0.0] -- 2026-01-04 (GitHub Release)

**Multi-Platform Image Downloader** -- major release with breaking changes. 73 commits from initial release through this tag.

Tag: [`v3.0.0`](https://github.com/Dicklesworthstone/giil/releases/tag/v3.0.0) points to commit [`5487824`](https://github.com/Dicklesworthstone/giil/commit/54878248b7f0fb962183e045172f7f275653dd13).

Release: <https://github.com/Dicklesworthstone/giil/releases/tag/v3.0.0>

### BREAKING CHANGES

- **Exit code reorganization**: `EXIT_NETWORK_ERROR` moved from 4 to 10; `EXIT_AUTH_REQUIRED` moved from 5 to 11. New codes added: 12 (not found), 13 (unsupported type), 20 (internal error). ([b302b64](https://github.com/Dicklesworthstone/giil/commit/b302b64d88d0cfa5eb1a777faf02fe4207c77e6f))
- **MozJPEG compression enabled by default**: downloaded images are now re-compressed through MozJPEG for optimal size/quality. Use `--preserve` to keep original bytes. ([7c4b7d2](https://github.com/Dicklesworthstone/giil/commit/7c4b7d2478e0b24c9e8cb47abb6ee7ef3a6f2b14))

### Multi-Platform Support

The tool evolved from iCloud-only to supporting four cloud photo services, built on a new Platform Adapter interface.

- **Platform Adapter interface** with JSDoc typedefs (`ResolvedItem`, `AcquireResult`, `AcquireContext`, `PlatformAdapter`) for pluggable platform backends ([fc09061](https://github.com/Dicklesworthstone/giil/commit/fc0906175e86beae4d1e0d07c62d71db169370c6))
- **Automatic platform detection** in both bash (`detect_platform()`) and JS (`detectPlatform()`) with regex-based URL matching ([b302b64](https://github.com/Dicklesworthstone/giil/commit/b302b64d88d0cfa5eb1a777faf02fe4207c77e6f))
- **Dropbox** -- fast direct download bypassing Playwright entirely; `normalize_dropbox_url()` converts share URLs to `raw=1` direct links for full-resolution images (10x faster than browser-based approach) ([b302b64](https://github.com/Dicklesworthstone/giil/commit/b302b64d88d0cfa5eb1a777faf02fe4207c77e6f))
- **Google Photos** -- CDN URL extraction from `googleusercontent.com` responses; `=s0` modifier for full-resolution download; album mode with URL collection fallback ([6968673](https://github.com/Dicklesworthstone/giil/commit/6968673072a8ea52d995b21bae8eea608423cf07), [cec3823](https://github.com/Dicklesworthstone/giil/commit/cec3823913f89f594187f63a0e8ea5f75567cdfc))
- **Google Drive** -- multi-tier capture strategy: (1) download button click with event capture, (2) direct download via `/uc?export=download`, (3) thumbnail endpoint at max size `w4000`, (4) element/viewport screenshot fallback. Includes file ID extraction, auth detection, and response validation. ([13d2555](https://github.com/Dicklesworthstone/giil/commit/13d2555e50b41db5680a5be120821f84afcee568), [b15f373](https://github.com/Dicklesworthstone/giil/commit/b15f373568c484ecd3f56395611a9b1de59abd0e), [23a964a](https://github.com/Dicklesworthstone/giil/commit/23a964a57742ba0ceabb8c7b3b8bc5451c879d4b))

### Image Processing Pipeline

- MozJPEG compression with 4:2:0 chroma subsampling as default, configurable quality ([7c4b7d2](https://github.com/Dicklesworthstone/giil/commit/7c4b7d2478e0b24c9e8cb47abb6ee7ef3a6f2b14))
- `--preserve` flag to skip recompression and keep original bytes ([bb21c8a](https://github.com/Dicklesworthstone/giil/commit/bb21c8a50bf2295a604548653e2e5ffe233bc7d8))
- `--optimize` and `--convert <format>` flags for explicit compression and format conversion to jpeg, png, or webp ([c13b20d](https://github.com/Dicklesworthstone/giil/commit/c13b20dc10e80edf9c04616cf84149d614d88cec))
- `--quality <N>` for compression quality 1-100 (default 85)
- Normalize `jpeg` to `jpg` for consistent file extensions ([ed48ccf](https://github.com/Dicklesworthstone/giil/commit/ed48ccf7873dbb51bc9946f99d4de74f76f6eb09))

### Album Mode

- `--all` flag for downloading entire shared albums in a single command
- Polite rate limiting: 1-second delay between photos with exponential backoff on rate-limit responses ([fc09061](https://github.com/Dicklesworthstone/giil/commit/fc0906175e86beae4d1e0d07c62d71db169370c6))
- Per-photo error handling with continuation to next image
- Progress tracking and indexed filenames (`_001`, `_002`, ...)

### Output Modes

- `--json` structured JSON output with `schema_version: "1"`, platform, and capture method fields
- `--base64` base64-encoded image output for piping and embedding

### Download Verification and Security

- Magic byte verification to detect HTML error pages masquerading as images ([b302b64](https://github.com/Dicklesworthstone/giil/commit/b302b64d88d0cfa5eb1a777faf02fe4207c77e6f))
- Content-Type header validation
- Automatic rejection of login redirects and error pages
- Google Drive response validation to distinguish successful downloads from auth walls ([381c515](https://github.com/Dicklesworthstone/giil/commit/381c5150c45fdde9dc7e569110b8c0a5b99677cc))
- Domain boundary enforcement in URL detection to prevent spoofing (e.g., `fakedropbox.com` cannot match) ([40a8569](https://github.com/Dicklesworthstone/giil/commit/40a8569fdb4e6af48b7ded6af868a06a9661d859), [d742476](https://github.com/Dicklesworthstone/giil/commit/d742476a2db807057deb49cc19702aec7da55d0a))
- Proper cleanup of temp files on all error paths, including installer ([a86ba86](https://github.com/Dicklesworthstone/giil/commit/a86ba86f2e1d226479988240d94b2501daa593b2))
- ShellCheck compliance and security hardening across all shell scripts ([f2524eb](https://github.com/Dicklesworthstone/giil/commit/f2524ebae625fc9d44aa76e47b8c3efb08264312))

### Update Checking and Distribution

- Opt-in update checking via `GIIL_CHECK_UPDATES=1` -- checks remote VERSION file at most once per day with short timeouts ([8bbcc5d](https://github.com/Dicklesworthstone/giil/commit/8bbcc5d4bc63167dccc5cf0d85b63c66955d37a1))
- SHA256 checksum verification during installation via `GIIL_VERIFY=1` ([8bbcc5d](https://github.com/Dicklesworthstone/giil/commit/8bbcc5d4bc63167dccc5cf0d85b63c66955d37a1))
- Installer upgrade detection: shows current vs. new version during install
- `GIIL_VERSION` environment variable support for installing specific versions ([4fc8172](https://github.com/Dicklesworthstone/giil/commit/4fc817287306802ec20307dd78253b3a235f8096))

### Bug Fixes

- Fix `OUTPUT_DIR` relative path handling (now converts to absolute) ([eeb443c](https://github.com/Dicklesworthstone/giil/commit/eeb443c9099d8a711dd8eb0c54c615ee6c5498bf))
- Fix HEIC conversion with system tools (sips on macOS, heif-convert on Linux) ([4fc8172](https://github.com/Dicklesworthstone/giil/commit/4fc817287306802ec20307dd78253b3a235f8096))
- Fix semver version comparison logic ([4fc8172](https://github.com/Dicklesworthstone/giil/commit/4fc817287306802ec20307dd78253b3a235f8096))
- Fix stream separation: stdout for data, stderr for logs ([fb9be61](https://github.com/Dicklesworthstone/giil/commit/fb9be61ff22f83a3ab446d02eb5de0383c049d6d), [8ab4cf3](https://github.com/Dicklesworthstone/giil/commit/8ab4cf3536d049d36403d9c792493e724bdb4ff9))
- Fix `set -e` arithmetic bug: `((VAR++))` returns exit 1 when VAR is 0 ([528161c](https://github.com/Dicklesworthstone/giil/commit/528161c5ecb3ffd018141e3a70ca1e4499d83121))
- Fix `path.join()` usage in traceMode (use imported `join()`) ([37a8934](https://github.com/Dicklesworthstone/giil/commit/37a8934e0f7861abf580043c2cc54efb32f4aff9))
- Fix `error.code` property in error handler ([d9407dc](https://github.com/Dicklesworthstone/giil/commit/d9407dc449e9f986472d6f4abc03814c1f8eb64f))
- Fix `real_link_test.sh` variable capture and sync VERSION file ([1188f70](https://github.com/Dicklesworthstone/giil/commit/1188f70d0a406d3dd41262d75e3ebf6e8ae8366a))
- Prevent filename collisions in output-modes E2E tests ([e64bf8b](https://github.com/Dicklesworthstone/giil/commit/e64bf8b2ffd9cd117bff1422fa01e5a3ff61c5a2))
- Fix missing `--preserve` flag implementation for skipping MozJPEG ([bb21c8a](https://github.com/Dicklesworthstone/giil/commit/bb21c8a50bf2295a604548653e2e5ffe233bc7d8))
- Redirect npm/playwright install output to stderr ([fb9be61](https://github.com/Dicklesworthstone/giil/commit/fb9be61ff22f83a3ab446d02eb5de0383c049d6d))
- Multiple bug fixes across CI, giil, and E2E tests ([94e90b0](https://github.com/Dicklesworthstone/giil/commit/94e90b0659312bed8921d1cf19efe63219b59059), [8f869d4](https://github.com/Dicklesworthstone/giil/commit/8f869d4363a5978db23c6c5b9412f77d885f1abb))

### Test Infrastructure

A comprehensive test suite was built from scratch for this release.

- Unit test framework for pure functions ([5346459](https://github.com/Dicklesworthstone/giil/commit/5346459da4f9e7f9f3ab7cfc4e252f44e4e93ef6))
- **Unit tests**: JSON formatting ([11ba94f](https://github.com/Dicklesworthstone/giil/commit/11ba94f0a50093d49c0f453be14b317799e3cb03)), Google Photos URL extraction ([da5318e](https://github.com/Dicklesworthstone/giil/commit/da5318ec3f1c7d50295a81fac9aed6af14350237)), Google Drive URLs ([03a9365](https://github.com/Dicklesworthstone/giil/commit/03a93652f61ca61af3dbb617f21c38537486dd33)), Google Drive response validation ([381c515](https://github.com/Dicklesworthstone/giil/commit/381c5150c45fdde9dc7e569110b8c0a5b99677cc)), date formatting ([ef76dac](https://github.com/Dicklesworthstone/giil/commit/ef76dac372136d5acb5c7e3b4c7bf5bd00110c91)), EXIF datetime ([71fd14b](https://github.com/Dicklesworthstone/giil/commit/71fd14b1990b8ec336078a5647de440b3964c10b))
- **Bash unit tests**: `detect_platform` and `normalize_dropbox_url` ([96c794e](https://github.com/Dicklesworthstone/giil/commit/96c794e50cbf2cc5eae1fe4b186ccf69a0305723)), `version_gt` and `detect_os` ([e9248a0](https://github.com/Dicklesworthstone/giil/commit/e9248a00c15f9504ccbd27e515cf8122b5957097))
- **E2E tests**: output modes (`--json`, `--base64`, `--convert`, `--quality`) ([f7db3ee](https://github.com/Dicklesworthstone/giil/commit/f7db3eecbbfb47f8149d97e744e4992b607c16b8)), album mode ([1e25e15](https://github.com/Dicklesworthstone/giil/commit/1e25e157bc5455e83fb710df9350ce7da637dd1d)), error scenarios (timeout, auth, not found) ([aa91df2](https://github.com/Dicklesworthstone/giil/commit/aa91df2a3fefb1d930528662d43f319e59eaedc1))
- Shared `common.sh` E2E library and test runner script ([447ba7e](https://github.com/Dicklesworthstone/giil/commit/447ba7e8914e83314b2e13191ae5f0e540f08161), [c539dbd](https://github.com/Dicklesworthstone/giil/commit/c539dbd0a754ad16013ca9a6d8c8f5fe2b8a7438))
- Test fixtures: sample images and magic bytes ([1bf95e0](https://github.com/Dicklesworthstone/giil/commit/1bf95e0ab51b637866271a2b9a36bbdd7a065869))
- Test infrastructure with structured logging and CI pipeline integration ([b52b82c](https://github.com/Dicklesworthstone/giil/commit/b52b82c86300055502eb56436bd92426a5067103))
- iCloud domain boundary enforcement tests ([5487824](https://github.com/Dicklesworthstone/giil/commit/54878248b7f0fb962183e045172f7f275653dd13))

### CI / CD

- GitHub Actions for linting (ShellCheck), syntax validation, multi-platform install tests, and automated releases with SHA256 checksums ([b0aeb4f](https://github.com/Dicklesworthstone/giil/commit/b0aeb4f3be47a40b304533f1aafef98d7cff0072))
- Real iCloud link integration test with daily schedule ([2543c22](https://github.com/Dicklesworthstone/giil/commit/2543c22f559ff1ac151b8b9fbb8c6e20c7c1abab))
- Release workflow: triggered by `v*` tags, computes SHA256 checksums, attaches artifacts to GitHub release, auto-updates VERSION file ([b0aeb4f](https://github.com/Dicklesworthstone/giil/commit/b0aeb4f3be47a40b304533f1aafef98d7cff0072))

### Documentation

- Comprehensive README expansion with multi-platform support documentation ([a3953a2](https://github.com/Dicklesworthstone/giil/commit/a3953a25d8c1e6e78eaafcd205e91865b60f356c))
- Browser emulation, error classification, and enhanced technical documentation ([f88d2c2](https://github.com/Dicklesworthstone/giil/commit/f88d2c254fa2c3ccce23902a1496b6b88c4eeda8))
- Download verification, rate limiting, and testing sections added to README ([94fd70b](https://github.com/Dicklesworthstone/giil/commit/94fd70bac0fa1538b12bbe9935d17291e9bb9140))

---

## v2.1.0 -- 2026-01-02 (no tag, no GitHub release)

**Hybrid Capture Strategy with Album Mode** -- a major architectural overhaul in a single commit. Version identified by commit message; no git tag was created.

Commit: [`ac97c96`](https://github.com/Dicklesworthstone/giil/commit/ac97c9688c0f4d3368b8542949bac90b221f21ad) (+1,034 lines / -195 lines to the giil script alone)

### Four-Tier Capture Strategy (new)

Maximum reliability through intelligent fallbacks, in priority order:
1. **Download button** -- clicks native iCloud Download button for original file acquisition (preserves HEIC/HEIF without re-encoding)
2. **Network interception** -- monitors CDN responses from `cvws.icloud-content.com`, captures the largest image buffer (>10KB threshold)
3. **Element screenshot** -- locates `<img>` elements using a 10-selector cascade with visibility and size validation (minimum 100x100px)
4. **Viewport screenshot** -- captures the visible viewport as a last-resort fallback

### Album Mode (new)

- `--all` flag iterates the iCloud thumbnail grid, clicks each to open full-size view, captures, closes viewer, continues to next
- Uses 11 selector strategies for thumbnail detection
- Resilient to individual failures (continues to next photo)
- Indexed filenames: `_001`, `_002`, etc.

### Structured Output (new)

- `--json` flag emits `{path, datetime, sourceUrl, method, size, width, height}` with the capture method indicating which strategy succeeded
- `--debug` saves diagnostic artifacts on failure: full-page screenshot and page DOM content

### CLI Polish

- `--timeout N` configurable page load timeout in seconds (default 60)
- `--update` force reinstall of Playwright and dependencies
- Gum integration (charmbracelet) for styled CLI output with auto-install and graceful fallback
- Styled banner and log levels: info, warn, error, step, debug, success
- Quick-start guide shown when invoked without URL argument

### Image Processing

- EXIF datetime extraction using exifr library (priority order: DateTimeOriginal, CreateDate, DateTimeDigitized, ModifyDate, now())
- HEIC/HEIF conversion with platform-aware system tools (sips on macOS, heif-convert on Linux)
- MozJPEG compression via Sharp with 4:2:0 chroma subsampling
- Collision-free filename generation with automatic counter suffix

### Browser Automation

- Cookie banner auto-dismissal with 8 common button text patterns
- Network idle wait with configurable timeout (capped at 30s for settle)
- Realistic viewport (1920x1080) and Chrome user-agent
- Download event interception for original file acquisition
- Album close button detection with 5-selector cascade and Escape key fallback

### Dependency Management

- XDG-compliant cache directory: `~/.cache/giil` (respects `$XDG_CACHE_HOME`, `$GIIL_HOME`, `$PLAYWRIGHT_BROWSERS_PATH`)
- Self-healing: auto-installs Node.js via brew/apt/dnf/yum/pacman
- Validates Node.js version >= 18 with warning for older versions
- Embedded `extractor.mjs` regenerated fresh on each invocation

### Installer and Documentation

- Proper fish shell PATH support in installer ([0bbb1ad](https://github.com/Dicklesworthstone/giil/commit/0bbb1adfb24e06c07cdefac8ec71a95df7bd6212))
- Complete README rewrite with primary use case (remote AI-assisted debugging) and technical deep-dive ([5145170](https://github.com/Dicklesworthstone/giil/commit/514517006bfdfe565083464d95d6710c7fd62a43))

---

## v1.0.0 -- 2026-01-02 (initial release, no tag, no GitHub release)

**Get iCloud Image Link** -- the first commit. A single-file bash CLI that downloads images from iCloud photo share links.

Commit: [`559c8af`](https://github.com/Dicklesworthstone/giil/commit/559c8aff68c3eebb912c8803a574f6e68a16899a) (916 lines across 4 files)

### Core Capabilities

- Single-file bash script with embedded Node.js extractor (`extractor.mjs`)
- Download full-resolution images from iCloud photo share links
- Headless Chromium via Playwright for rendering JavaScript-heavy iCloud SPA
- Smart image capture via CDN network interception
- MozJPEG compression with configurable quality via Sharp
- Base64 output mode for piping to other tools or APIs

### Smart Filenames

- EXIF-aware datetime stamping: extracts `DateTimeOriginal` from image metadata
- Falls back to capture timestamp when EXIF data is unavailable
- Format: `icloud_YYYYMMDD_HHMMSS.jpg`

### Zero-Setup Installation

- Auto-installs Node.js, Playwright, Chromium (~200MB, cached), and Sharp
- `curl -fsSL .../install.sh | bash` one-liner installer
- macOS and Linux support
- Installs to `~/.local/bin/giil` with PATH setup for bash/zsh

### Files Shipped

- `giil` -- main script (486 lines)
- `install.sh` -- curl-pipe-bash installer (180 lines)
- `README.md` -- documentation
- `LICENSE` -- MIT license

---

<!-- Link references -->
[Unreleased]: https://github.com/Dicklesworthstone/giil/compare/v3.1.0...HEAD
[v3.1.0]: https://github.com/Dicklesworthstone/giil/compare/v3.0.0...v3.1.0
[v3.0.0]: https://github.com/Dicklesworthstone/giil/compare/559c8af...v3.0.0

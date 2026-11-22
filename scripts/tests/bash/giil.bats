#!/usr/bin/env bats
# Unit tests for bash functions in giil
#
# Run with: bats scripts/tests/bash/giil.bats
# Or via: scripts/tests/bash/run.sh

# Setup: source the giil functions
setup() {
    # Extract just the functions we want to test from giil
    # We can't source the whole script as it would execute
    GIIL_SCRIPT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)/giil"

    # Extract detect_platform function
    eval "$(sed -n '/^detect_platform() {$/,/^}$/p' "$GIIL_SCRIPT")"

    # Extract normalize_dropbox_url function
    eval "$(sed -n '/^normalize_dropbox_url() {$/,/^}$/p' "$GIIL_SCRIPT")"

    # Extract version_gt function
    eval "$(sed -n '/^version_gt() {$/,/^}$/p' "$GIIL_SCRIPT")"

    # Extract detect_os function
    eval "$(sed -n '/^detect_os() {$/,/^}$/p' "$GIIL_SCRIPT")"

    # Extract runtime version helpers
    eval "$(sed -n '/^node_version_meets_minimum() {$/,/^}$/p' "$GIIL_SCRIPT")"
    eval "$(sed -n '/^runtime_needs_install() {$/,/^}$/p' "$GIIL_SCRIPT")"
    eval "$(sed -n '/^detect_file_mime_type() {$/,/^}$/p' "$GIIL_SCRIPT")"
    eval "$(grep -E '^GIIL_(PLAYWRIGHT|SHARP|EXIFR|MIN_NODE)_VERSION=|^GIIL_RUNTIME_SPEC=' "$GIIL_SCRIPT")"
}

# ============================================================================
# detect_platform tests
# ============================================================================

@test "detect_platform: returns icloud for share.icloud.com/photos" {
    result="$(detect_platform 'https://share.icloud.com/photos/abc123')"
    [ "$result" = "icloud" ]
}

@test "detect_platform: returns icloud for www.icloud.com/photos" {
    result="$(detect_platform 'https://www.icloud.com/photos/abc123')"
    [ "$result" = "icloud" ]
}

@test "detect_platform: returns icloud for icloud.com/photos (no www)" {
    result="$(detect_platform 'https://icloud.com/photos/abc123')"
    [ "$result" = "icloud" ]
}

@test "detect_platform: returns dropbox for dropbox.com/s/" {
    result="$(detect_platform 'https://www.dropbox.com/s/abc123/photo.jpg')"
    [ "$result" = "dropbox" ]
}

@test "detect_platform: returns dropbox for dropbox.com/scl/fi/" {
    result="$(detect_platform 'https://www.dropbox.com/scl/fi/abc123/photo.jpg')"
    [ "$result" = "dropbox" ]
}

@test "detect_platform: returns dropbox for dropbox.com/sh/" {
    result="$(detect_platform 'https://www.dropbox.com/sh/abc123')"
    [ "$result" = "dropbox" ]
}

@test "detect_platform: returns gphotos for photos.app.goo.gl" {
    result="$(detect_platform 'https://photos.app.goo.gl/abc123')"
    [ "$result" = "gphotos" ]
}

@test "detect_platform: returns gphotos for photos.google.com/share" {
    result="$(detect_platform 'https://photos.google.com/share/abc123')"
    [ "$result" = "gphotos" ]
}

@test "detect_platform: returns gdrive for drive.google.com/file/d/" {
    result="$(detect_platform 'https://drive.google.com/file/d/abc123/view')"
    [ "$result" = "gdrive" ]
}

@test "detect_platform: returns gdrive for drive.google.com/open?id=" {
    result="$(detect_platform 'https://drive.google.com/open?id=abc123')"
    [ "$result" = "gdrive" ]
}

@test "detect_platform: returns unknown for unrecognized URL" {
    result="$(detect_platform 'https://example.com/photo.jpg')"
    [ "$result" = "unknown" ]
}

@test "detect_platform: rejects subdomain spoofing (fakedropbox.com)" {
    result="$(detect_platform 'https://fakedropbox.com/s/abc123')"
    [ "$result" = "unknown" ]
}

@test "detect_platform: rejects subdomain spoofing (notdropbox.com)" {
    result="$(detect_platform 'https://dropbox.notdropbox.com/s/abc123')"
    [ "$result" = "unknown" ]
}

# ============================================================================
# normalize_dropbox_url tests
# ============================================================================

@test "normalize_dropbox_url: adds raw=1 to clean URL" {
    result="$(normalize_dropbox_url 'https://www.dropbox.com/s/abc/photo.jpg')"
    [ "$result" = "https://www.dropbox.com/s/abc/photo.jpg?raw=1" ]
}

@test "normalize_dropbox_url: replaces dl=0 with raw=1" {
    result="$(normalize_dropbox_url 'https://www.dropbox.com/s/abc/photo.jpg?dl=0')"
    [[ "$result" == *"raw=1"* ]]
    [[ "$result" != *"dl=0"* ]]
}

@test "normalize_dropbox_url: replaces dl=1 with raw=1" {
    result="$(normalize_dropbox_url 'https://www.dropbox.com/s/abc/photo.jpg?dl=1')"
    [[ "$result" == *"raw=1"* ]]
    [[ "$result" != *"dl=1"* ]]
}

@test "normalize_dropbox_url: handles URL with existing query params" {
    result="$(normalize_dropbox_url 'https://www.dropbox.com/s/abc/photo.jpg?foo=bar')"
    [[ "$result" == *"foo=bar"* ]]
    [[ "$result" == *"raw=1"* ]]
}

@test "normalize_dropbox_url: removes raw=0 and adds raw=1" {
    result="$(normalize_dropbox_url 'https://www.dropbox.com/s/abc/photo.jpg?raw=0')"
    [[ "$result" == *"raw=1"* ]]
    [[ "$result" != *"raw=0"* ]]
}

@test "normalize_dropbox_url: handles scl/fi/ URLs" {
    result="$(normalize_dropbox_url 'https://www.dropbox.com/scl/fi/abc/photo.jpg')"
    [ "$result" = "https://www.dropbox.com/scl/fi/abc/photo.jpg?raw=1" ]
}

@test "normalize_dropbox_url: preserves path structure" {
    input="https://www.dropbox.com/s/long-hash-123/my-photo-file.jpg"
    result="$(normalize_dropbox_url "$input")"
    [[ "$result" == "$input"* ]]
}

# ============================================================================
# version_gt tests
# ============================================================================

@test "version_gt: 2.0.0 > 1.0.0" {
    version_gt "2.0.0" "1.0.0"
}

@test "version_gt: 1.1.0 > 1.0.0" {
    version_gt "1.1.0" "1.0.0"
}

@test "version_gt: 1.0.1 > 1.0.0" {
    version_gt "1.0.1" "1.0.0"
}

@test "version_gt: 10.0.0 > 9.0.0" {
    version_gt "10.0.0" "9.0.0"
}

@test "version_gt: 1.0.0 is NOT > 1.0.0 (equal)" {
    ! version_gt "1.0.0" "1.0.0"
}

@test "version_gt: 1.0.0 is NOT > 2.0.0" {
    ! version_gt "1.0.0" "2.0.0"
}

@test "version_gt: 3.0.0 > 2.9.9" {
    version_gt "3.0.0" "2.9.9"
}

# ============================================================================
# detect_os tests
# ============================================================================

@test "detect_os: returns macos, linux, or unknown" {
    result="$(detect_os)"
    [[ "$result" == "macos" || "$result" == "linux" || "$result" == "unknown" ]]
}

@test "detect_os: output is a single word" {
    result="$(detect_os)"
    [[ "$result" =~ ^[a-z]+$ ]]
}

# ============================================================================
# node_version_meets_minimum tests (embedded runtime requires Node >= 20.10.0)
# ============================================================================

@test "node_version_meets_minimum: pinned minimum is 20.10.0" {
    [ "$GIIL_MIN_NODE_VERSION" = "20.10.0" ]
}

@test "node_version_meets_minimum: equal version passes" {
    node_version_meets_minimum "20.10.0" "20.10.0"
}

@test "node_version_meets_minimum: newer majors and minors pass" {
    node_version_meets_minimum "20.11.0" "20.10.0"
    node_version_meets_minimum "22.0.0" "20.10.0"
    node_version_meets_minimum "26.8.1" "20.10.0"
}

@test "node_version_meets_minimum: older versions fail" {
    ! node_version_meets_minimum "20.9.0" "20.10.0"
    ! node_version_meets_minimum "18.19.0" "20.10.0"
    ! node_version_meets_minimum "12.22.9" "20.10.0"
}

@test "node_version_meets_minimum: numeric not lexical comparison" {
    node_version_meets_minimum "100.0.0" "20.10.0"
    ! node_version_meets_minimum "3.0.0" "20.10.0"
}

@test "node_version_meets_minimum: pre-release suffix ignored, empty or garbage fails" {
    node_version_meets_minimum "21.0.0-nightly20250101" "20.10.0"
    ! node_version_meets_minimum "" "20.10.0"
    ! node_version_meets_minimum "not-a-version" "20.10.0"
}

# ============================================================================
# runtime_needs_install tests (cached runtime adoption of new pins)
# ============================================================================

@test "runtime spec pins current Playwright, Sharp, and exifr" {
    [ "$GIIL_RUNTIME_SPEC" = "playwright@${GIIL_PLAYWRIGHT_VERSION} sharp@${GIIL_SHARP_VERSION} exifr@${GIIL_EXIFR_VERSION}" ]
    [[ "$GIIL_PLAYWRIGHT_VERSION" != "1.40.0" ]]
    [[ "$GIIL_SHARP_VERSION" != "0.33.0" ]]
}

@test "runtime_needs_install: missing stamp requires install" {
    local home="$BATS_TEST_TMPDIR/home-missing"
    mkdir -p "$home/node_modules/playwright"
    runtime_needs_install "$home/.installed" "$home/node_modules" "$GIIL_RUNTIME_SPEC"
}

@test "runtime_needs_install: legacy empty stamp from older releases requires install" {
    local home="$BATS_TEST_TMPDIR/home-legacy"
    mkdir -p "$home/node_modules/playwright"
    : > "$home/.installed"
    runtime_needs_install "$home/.installed" "$home/node_modules" "$GIIL_RUNTIME_SPEC"
}

@test "runtime_needs_install: stamp for different pins requires install" {
    local home="$BATS_TEST_TMPDIR/home-old"
    mkdir -p "$home/node_modules/playwright"
    printf '%s\n' "playwright@1.40.0 sharp@0.33.0 exifr@7.1.3" > "$home/.installed"
    runtime_needs_install "$home/.installed" "$home/node_modules" "$GIIL_RUNTIME_SPEC"
}

@test "runtime_needs_install: matching stamp without playwright package requires install" {
    local home="$BATS_TEST_TMPDIR/home-nopw"
    mkdir -p "$home/node_modules"
    printf '%s\n' "$GIIL_RUNTIME_SPEC" > "$home/.installed"
    runtime_needs_install "$home/.installed" "$home/node_modules" "$GIIL_RUNTIME_SPEC"
}

@test "runtime_needs_install: matching stamp and package reuses cache" {
    local home="$BATS_TEST_TMPDIR/home-current"
    mkdir -p "$home/node_modules/playwright"
    printf '%s\n' "$GIIL_RUNTIME_SPEC" > "$home/.installed"
    ! runtime_needs_install "$home/.installed" "$home/node_modules" "$GIIL_RUNTIME_SPEC"
}

# ============================================================================
# First-run installer output must never reach stdout (JSON/TOON/path contract)
# ============================================================================

@test "ensure_playwright: every gum spin installer step redirects stdout to stderr" {
    local body
    # End at the next function: the embedded package.json heredoc has a bare "}" line.
    body="$(sed -n '/^ensure_playwright() {$/,/^create_extractor_script() {$/p' "$GIIL_SCRIPT")"
    [ -n "$body" ]
    # Join backslash-continued lines so each gum spin command is one line.
    local joined
    joined="$(printf '%s\n' "$body" | awk '{ if (sub(/\\$/, "")) { buf = buf $0 } else { print buf $0; buf = "" } }')"
    local count=0 line
    while IFS= read -r line; do
        [[ "$line" == *"gum spin"* ]] || continue
        count=$((count + 1))
        [[ "$line" == *">&2"* ]] || { echo "stdout leak: $line" >&2; return 1; }
    done <<< "$joined"
    [ "$count" -ge 2 ]
}

@test "ensure_playwright: npm and playwright installer commands never write to stdout" {
    local body joined line
    # End at the next function: the embedded package.json heredoc has a bare "}" line.
    body="$(sed -n '/^ensure_playwright() {$/,/^create_extractor_script() {$/p' "$GIIL_SCRIPT")"
    joined="$(printf '%s\n' "$body" | awk '{ if (sub(/\\$/, "")) { buf = buf $0 } else { print buf $0; buf = "" } }')"
    local count=0
    while IFS= read -r line; do
        [[ "$line" =~ (npm\ install|npx\ playwright\ install) ]] || continue
        [[ "$line" =~ ^[[:space:]]*log_error ]] && continue
        count=$((count + 1))
        [[ "$line" == *">&2"* ]] || { echo "stdout leak: $line" >&2; return 1; }
    done <<< "$joined"
    [ "$count" -ge 4 ]
}

# ============================================================================
# detect_file_mime_type tests (Dropbox direct validation without file(1))
# ============================================================================

@test "detect_file_mime_type: identifies PNG, JPEG, GIF, WebP, HEIC, AVIF without file(1)" {
    local d="$BATS_TEST_TMPDIR/mime"
    mkdir -p "$d"
    printf '\x89PNG\r\n\x1a\n00000000' > "$d/a.bin"
    printf '\xff\xd8\xff\xe000000000' > "$d/b.bin"
    printf 'GIF89a0000000000' > "$d/c.bin"
    printf 'RIFF\x00\x00\x00\x00WEBP0000' > "$d/d.bin"
    printf '\x00\x00\x00\x18ftypheic0000' > "$d/e.bin"
    printf '\x00\x00\x00\x18ftypavif0000' > "$d/f.bin"

    # Hide file(1) via PATH override to simulate minimal containers
    local minpath="$d/bin"
    mkdir -p "$minpath"
    for cmd in od tr head sed; do
        ln -sf "$(command -v "$cmd")" "$minpath/$cmd"
    done

    [ "$(PATH="$minpath" detect_file_mime_type "$d/a.bin")" = "image/png" ]
    [ "$(PATH="$minpath" detect_file_mime_type "$d/b.bin")" = "image/jpeg" ]
    [ "$(PATH="$minpath" detect_file_mime_type "$d/c.bin")" = "image/gif" ]
    [ "$(PATH="$minpath" detect_file_mime_type "$d/d.bin")" = "image/webp" ]
    [ "$(PATH="$minpath" detect_file_mime_type "$d/e.bin")" = "image/heic" ]
    [ "$(PATH="$minpath" detect_file_mime_type "$d/f.bin")" = "image/avif" ]
}

@test "detect_file_mime_type: detects HTML error pages without file(1)" {
    local d="$BATS_TEST_TMPDIR/mime-html"
    mkdir -p "$d/bin"
    for cmd in od tr head sed; do
        ln -sf "$(command -v "$cmd")" "$d/bin/$cmd"
    done
    printf '  \n<!DOCTYPE html>\n<html lang="en"><body>Error</body></html>' > "$d/err1.html"
    printf '<html><head><title>404</title></head></html>' > "$d/err2.html"

    [ "$(PATH="$d/bin" detect_file_mime_type "$d/err1.html")" = "text/html" ]
    [ "$(PATH="$d/bin" detect_file_mime_type "$d/err2.html")" = "text/html" ]
}

@test "main: guards empty _dropbox_urls expansion for Bash 4.0-4.3 set -u compatibility" {
    local body
    body="$(sed -n '/^main() {$/,/^}$/p' "$GIIL_SCRIPT")"
    [[ "$body" == *'if [[ ${#_dropbox_urls[@]} -gt 0 ]]; then'* ]]
}

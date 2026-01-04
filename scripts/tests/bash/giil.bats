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

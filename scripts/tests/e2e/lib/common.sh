#!/usr/bin/env bash
# E2E Test Common Library for giil
# Provides shared setup, teardown, and assertions for E2E tests
#
# Usage:
#   source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
#   e2e_setup "test name"
#   e2e_run_giil "$URL" --json
#   e2e_assert_file_exists "$path"
#   e2e_teardown

set -euo pipefail

# shellcheck source=../../lib/log.sh
E2E_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
E2E_ROOT="$(cd "$E2E_LIB_DIR/.." && pwd)"
TESTS_ROOT="$(cd "$E2E_ROOT/.." && pwd)"
PROJECT_ROOT="$(cd "$TESTS_ROOT/../.." && pwd)"

source "$TESTS_ROOT/lib/log.sh"

# Globals
E2E_TEST_NAME=""
E2E_OUTPUT_DIR=""
E2E_START_TIME=0
E2E_GIIL_BIN="$PROJECT_ROOT/giil"

# Setup test environment
e2e_setup() {
    E2E_TEST_NAME="${1:-unnamed}"
    E2E_START_TIME=$SECONDS

    # Create isolated output directory
    E2E_OUTPUT_DIR="$(mktemp -d "/tmp/giil-e2e-${E2E_TEST_NAME}-XXXXXX")"

    # Set up giil environment
    export GIIL_HOME="${GIIL_HOME:-$E2E_OUTPUT_DIR/.giil}"
    export PLAYWRIGHT_BROWSERS_PATH="${PLAYWRIGHT_BROWSERS_PATH:-$GIIL_HOME/ms-playwright}"
    export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$E2E_OUTPUT_DIR/.cache}"

    log_section "E2E Test: $E2E_TEST_NAME"
    log_info "Output directory: $E2E_OUTPUT_DIR"
}

# Teardown test environment
e2e_teardown() {
    local duration=$((SECONDS - E2E_START_TIME))

    if [[ -n "${E2E_KEEP_OUTPUT:-}" ]]; then
        log_info "Keeping output directory: $E2E_OUTPUT_DIR"
    elif [[ -n "$E2E_OUTPUT_DIR" && -d "$E2E_OUTPUT_DIR" ]]; then
        rm -rf "$E2E_OUTPUT_DIR"
    fi

    log_info "Test duration: ${duration}s"
}

# Run giil with standard options and capture output
# Usage: e2e_run_giil URL [extra args...]
# Sets: E2E_JSON_OUTPUT, E2E_OUTPUT_PATH, E2E_CAPTURE_METHOD
e2e_run_giil() {
    local url="$1"
    shift
    local extra_args=("$@")

    local json_file="$E2E_OUTPUT_DIR/output.json"

    log_info "Platform: $(e2e_detect_platform "$url")"
    log_info "URL: $url"

    local start=$SECONDS
    if ! "$E2E_GIIL_BIN" "$url" --json --output "$E2E_OUTPUT_DIR" "${extra_args[@]}" > "$json_file"; then
        log_fail "giil command failed"
        if [[ -f "$json_file" ]]; then
            log_info "JSON output: $(cat "$json_file")"
        fi
        return 1
    fi
    local duration=$((SECONDS - start))

    # Parse JSON output
    if ! E2E_JSON_OUTPUT=$(cat "$json_file"); then
        log_fail "Failed to read JSON output"
        return 1
    fi

    # Extract key fields
    E2E_OUTPUT_PATH=$(echo "$E2E_JSON_OUTPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('path',''))" 2>/dev/null || true)
    E2E_CAPTURE_METHOD=$(echo "$E2E_JSON_OUTPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('method',''))" 2>/dev/null || true)

    log_info "Method: ${E2E_CAPTURE_METHOD:-unknown}"
    log_info "Duration: ${duration}s"

    if [[ -n "$E2E_OUTPUT_PATH" && -f "$E2E_OUTPUT_PATH" ]]; then
        local size
        size=$(stat -c%s "$E2E_OUTPUT_PATH" 2>/dev/null || stat -f%z "$E2E_OUTPUT_PATH" 2>/dev/null || echo "unknown")
        log_info "Size: $size bytes"
    fi

    return 0
}

# Detect platform from URL (simple version)
e2e_detect_platform() {
    local url="$1"
    case "$url" in
        *icloud.com*|*apple.com*) echo "icloud" ;;
        *dropbox.com*) echo "dropbox" ;;
        *photos.google.com*|*photos.app.goo.gl*|*lh3.googleusercontent.com*) echo "google-photos" ;;
        *drive.google.com*|*docs.google.com*) echo "google-drive" ;;
        *) echo "unknown" ;;
    esac
}

# Assert file exists
e2e_assert_file_exists() {
    local path="$1"
    local msg="${2:-File should exist: $path}"

    if [[ -f "$path" ]]; then
        log_pass "$msg"
        return 0
    else
        log_fail "$msg"
        return 1
    fi
}

# Assert file is valid image (has valid magic bytes)
e2e_assert_valid_image() {
    local path="$1"
    local msg="${2:-File should be valid image}"

    if [[ ! -f "$path" ]]; then
        log_fail "$msg (file does not exist)"
        return 1
    fi

    # Check magic bytes
    local magic
    magic=$(xxd -p -l 4 "$path" 2>/dev/null || true)

    case "$magic" in
        ffd8ff*)   log_pass "$msg (JPEG)"; return 0 ;;
        89504e47*) log_pass "$msg (PNG)"; return 0 ;;
        47494638*) log_pass "$msg (GIF)"; return 0 ;;
        52494646*) log_pass "$msg (RIFF/WebP)"; return 0 ;;
        424d*)     log_pass "$msg (BMP)"; return 0 ;;
        49492a00*|4d4d002a*) log_pass "$msg (TIFF)"; return 0 ;;
    esac

    # Check for HEIC/HEIF (needs more bytes)
    local heic_check
    heic_check=$(xxd -p -l 12 "$path" 2>/dev/null || true)
    if [[ "$heic_check" == *"66747970"* ]]; then
        log_pass "$msg (HEIC/HEIF)"
        return 0
    fi

    log_fail "$msg (unknown format: $magic)"
    return 1
}

# Assert SHA256 matches expected
e2e_assert_sha256() {
    local path="$1"
    local expected="$2"
    local msg="${3:-SHA256 should match}"

    if [[ ! -f "$path" ]]; then
        log_fail "$msg (file does not exist)"
        return 1
    fi

    local actual
    actual=$(sha256sum "$path" 2>/dev/null | awk '{print $1}' || shasum -a 256 "$path" 2>/dev/null | awk '{print $1}')

    if [[ "$actual" == "$expected" ]]; then
        log_pass "$msg ($actual)"
        return 0
    else
        log_fail "$msg"
        log_info "Expected: $expected"
        log_info "Actual:   $actual"
        return 1
    fi
}

# Assert JSON output has required fields
e2e_assert_json_has_field() {
    local field="$1"
    local msg="${2:-JSON should have field: $field}"

    if echo "$E2E_JSON_OUTPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); exit(0 if '$field' in d else 1)" 2>/dev/null; then
        log_pass "$msg"
        return 0
    else
        log_fail "$msg"
        return 1
    fi
}

# Assert capture method
e2e_assert_method() {
    local expected="$1"
    local msg="${2:-Capture method should be: $expected}"

    if [[ "$E2E_CAPTURE_METHOD" == "$expected" ]]; then
        log_pass "$msg"
        return 0
    else
        log_fail "$msg (got: $E2E_CAPTURE_METHOD)"
        return 1
    fi
}

# Skip test with reason
e2e_skip() {
    local reason="${1:-No reason given}"
    log_warn "SKIP: $reason"
    exit 0
}

# Check if URL is accessible (basic check)
e2e_check_url_accessible() {
    local url="$1"
    local timeout="${2:-10}"

    if curl -sf --max-time "$timeout" -o /dev/null "$url" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

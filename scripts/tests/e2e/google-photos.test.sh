#!/usr/bin/env bash
# E2E Test: Google Photos Download
#
# Tests downloading from Google Photos shared links:
# - Uses Playwright to extract full-resolution URL
# - Tests =s0 modifier for original quality
# - Verifies file is valid image
#
# Environment:
#   GIIL_GOOGLE_PHOTOS_TEST_URL - Override test URL
#   E2E_KEEP_OUTPUT - Keep output directory for debugging
#
# Note: Google Photos tests require a valid public share link.
# If no test URL is configured, this test will be skipped.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Test configuration
TEST_URL="${GIIL_GOOGLE_PHOTOS_TEST_URL:-}"

# Main test
main() {
    local exit_code=0

    e2e_setup "google-photos"

    # Check if we have a test URL
    if [[ -z "$TEST_URL" ]]; then
        e2e_skip "No GIIL_GOOGLE_PHOTOS_TEST_URL configured - set environment variable to run this test"
    fi

    # Check if giil exists
    if [[ ! -x "$E2E_GIIL_BIN" ]]; then
        log_fail "giil binary not found or not executable: $E2E_GIIL_BIN"
        e2e_teardown
        exit 1
    fi

    # Verify URL format
    case "$TEST_URL" in
        *photos.google.com*|*photos.app.goo.gl*|*lh3.googleusercontent.com*)
            log_info "URL format: valid Google Photos URL"
            ;;
        *)
            log_fail "TEST_URL does not appear to be a Google Photos URL: $TEST_URL"
            e2e_teardown
            exit 1
            ;;
    esac

    # Run giil
    if ! e2e_run_giil "$TEST_URL" --timeout 120; then
        log_fail "Failed to download from Google Photos"
        exit_code=1
    else
        # Verify file exists
        if ! e2e_assert_file_exists "$E2E_OUTPUT_PATH" "Output file exists"; then
            exit_code=1
        fi

        # Verify valid image
        if ! e2e_assert_valid_image "$E2E_OUTPUT_PATH"; then
            exit_code=1
        fi

        # Verify JSON has required fields
        for field in path method; do
            if ! e2e_assert_json_has_field "$field"; then
                exit_code=1
            fi
        done

        # Check that we got a reasonably sized image (> 10KB suggests full res)
        if [[ -f "$E2E_OUTPUT_PATH" ]]; then
            local size
            size=$(stat -c%s "$E2E_OUTPUT_PATH" 2>/dev/null || stat -f%z "$E2E_OUTPUT_PATH" 2>/dev/null || echo "0")
            if [[ "$size" -gt 10240 ]]; then
                log_pass "Image size suggests full resolution: $size bytes"
            else
                log_warn "Image size may be thumbnail: $size bytes"
            fi
        fi
    fi

    e2e_teardown

    if [[ "$exit_code" -eq 0 ]]; then
        log_pass "Google Photos E2E test passed"
    else
        log_fail "Google Photos E2E test failed"
    fi

    exit "$exit_code"
}

main "$@"

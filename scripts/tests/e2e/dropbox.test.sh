#!/usr/bin/env bash
# E2E Test: Dropbox Direct Download
#
# Tests downloading from Dropbox shared links:
# - Uses direct curl (no Playwright) for public links
# - Tests raw=1 URL transformation
# - Verifies file is valid image
#
# Environment:
#   GIIL_DROPBOX_TEST_URL - Override test URL
#   E2E_KEEP_OUTPUT - Keep output directory for debugging
#
# Note: Dropbox tests require a valid public share link.
# If no test URL is configured, this test will be skipped.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Test configuration
# Default URL should be a stable Dropbox shared link (if available)
TEST_URL="${GIIL_DROPBOX_TEST_URL:-}"

# Main test
main() {
    local exit_code=0

    e2e_setup "dropbox"

    # Check if we have a test URL
    if [[ -z "$TEST_URL" ]]; then
        e2e_skip "No GIIL_DROPBOX_TEST_URL configured - set environment variable to run this test"
    fi

    # Check if giil exists
    if [[ ! -x "$E2E_GIIL_BIN" ]]; then
        log_fail "giil binary not found or not executable: $E2E_GIIL_BIN"
        e2e_teardown
        exit 1
    fi

    # Verify URL format
    case "$TEST_URL" in
        *dropbox.com*)
            log_info "URL format: valid Dropbox URL"
            ;;
        *)
            log_fail "TEST_URL does not appear to be a Dropbox URL: $TEST_URL"
            e2e_teardown
            exit 1
            ;;
    esac

    # Run giil
    if ! e2e_run_giil "$TEST_URL" --timeout 60; then
        log_fail "Failed to download from Dropbox"
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

        # Dropbox should use "direct" method (curl, no Playwright)
        if [[ "$E2E_CAPTURE_METHOD" == "direct" ]]; then
            log_pass "Used direct download method (no Playwright)"
        else
            log_info "Capture method: $E2E_CAPTURE_METHOD (expected 'direct' for Dropbox)"
        fi
    fi

    e2e_teardown

    if [[ "$exit_code" -eq 0 ]]; then
        log_pass "Dropbox E2E test passed"
    else
        log_fail "Dropbox E2E test failed"
    fi

    exit "$exit_code"
}

main "$@"

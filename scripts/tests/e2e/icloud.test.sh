#!/usr/bin/env bash
# E2E Test: iCloud Photo Download
#
# Tests downloading a known iCloud shared photo and verifies:
# - File is downloaded successfully
# - File is a valid image
# - SHA256 matches expected (ensures consistent output)
# - JSON output contains required fields
#
# Environment:
#   GIIL_ICLOUD_TEST_URL - Override test URL
#   GIIL_ICLOUD_EXPECTED_SHA - Override expected SHA256
#   E2E_KEEP_OUTPUT - Keep output directory for debugging

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Test configuration
TEST_URL="${GIIL_ICLOUD_TEST_URL:-https://share.icloud.com/photos/02cD9okNHvVd-uuDnPCH3ZEEA}"
EXPECTED_SHA_FILE="$PROJECT_ROOT/scripts/real_icloud_expected.sha256"

# Get expected SHA
get_expected_sha() {
    if [[ -n "${GIIL_ICLOUD_EXPECTED_SHA:-}" ]]; then
        echo "$GIIL_ICLOUD_EXPECTED_SHA"
        return
    fi

    if [[ -f "$EXPECTED_SHA_FILE" ]]; then
        tr -d '[:space:]' < "$EXPECTED_SHA_FILE"
    else
        log_warn "No expected SHA file found, skipping SHA verification"
        echo ""
    fi
}

# Main test
main() {
    local exit_code=0

    e2e_setup "icloud"

    # Check if giil exists
    if [[ ! -x "$E2E_GIIL_BIN" ]]; then
        log_fail "giil binary not found or not executable: $E2E_GIIL_BIN"
        e2e_teardown
        exit 1
    fi

    # Run giil
    if ! e2e_run_giil "$TEST_URL" --timeout 120; then
        log_fail "Failed to download from iCloud"
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

        # Verify SHA256 if expected value is available
        local expected_sha
        expected_sha=$(get_expected_sha)
        if [[ -n "$expected_sha" ]]; then
            if ! e2e_assert_sha256 "$E2E_OUTPUT_PATH" "$expected_sha" "SHA256 matches expected"; then
                exit_code=1
            fi
        fi
    fi

    e2e_teardown

    if [[ "$exit_code" -eq 0 ]]; then
        log_pass "iCloud E2E test passed"
    else
        log_fail "iCloud E2E test failed"
    fi

    exit "$exit_code"
}

main "$@"

#!/usr/bin/env bash
# Run all tests: unit tests and E2E tests
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./lib/log.sh
source "$SCRIPT_DIR/lib/log.sh"

log_section "giil Test Suite"

# Track overall results
total_passed=0
total_failed=0
start_time=$SECONDS

# Run unit tests
log_section "Unit Tests"
if node --test "$SCRIPT_DIR"/*.test.mjs; then
    log_pass "All unit tests passed"
    ((total_passed++))
else
    log_fail "Some unit tests failed"
    ((total_failed++))
fi

# Run E2E tests if they exist
if compgen -G "$SCRIPT_DIR/e2e/*.test.sh" > /dev/null 2>&1; then
    log_section "E2E Tests"
    for test in "$SCRIPT_DIR"/e2e/*.test.sh; do
        test_name=$(basename "$test")
        log_info "Running: $test_name"
        if bash "$test"; then
            log_pass "$test_name"
            ((total_passed++))
        else
            log_fail "$test_name"
            ((total_failed++))
        fi
    done
else
    log_info "No E2E tests found in $SCRIPT_DIR/e2e/"
fi

# Summary
duration=$((SECONDS - start_time))
log_separator
log_suite_summary "All Tests" "$total_passed" "$total_failed" 0 "$((duration * 1000))"

exit $((total_failed > 0 ? 1 : 0))

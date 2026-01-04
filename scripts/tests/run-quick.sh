#!/usr/bin/env bash
# Run quick tests only (unit tests, skip E2E)
# Use this for fast feedback during development
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./lib/log.sh
source "$SCRIPT_DIR/lib/log.sh"

log_section "Quick Unit Tests"

start_time=$SECONDS

# Run unit tests with Node.js test runner
if node --test "$SCRIPT_DIR"/*.test.mjs; then
    duration=$((SECONDS - start_time))
    log_pass "All unit tests passed (${duration}s)"
    exit 0
else
    duration=$((SECONDS - start_time))
    log_fail "Some unit tests failed (${duration}s)"
    exit 1
fi

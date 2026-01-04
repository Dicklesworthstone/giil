#!/usr/bin/env bash
# Test logging framework for giil tests
# Provides structured logging for both CI and local development
#
# Usage:
#   source scripts/tests/lib/log.sh
#   log_info "Starting test suite"
#   log_pass "Test passed"
#   log_fail "Test failed: expected X, got Y"
#
# Environment:
#   GIIL_LOG_FORMAT=json  - Output JSON for CI parsing
#   GIIL_LOG_FORMAT=text  - Human-readable (default)

# Detect if we're in CI
if [[ -n "${CI:-}" || -n "${GITHUB_ACTIONS:-}" ]]; then
    GIIL_LOG_FORMAT="${GIIL_LOG_FORMAT:-json}"
else
    GIIL_LOG_FORMAT="${GIIL_LOG_FORMAT:-text}"
fi

# Color codes for terminal output
readonly _RED='\033[0;31m'
readonly _GREEN='\033[0;32m'
readonly _YELLOW='\033[0;33m'
readonly _BLUE='\033[0;34m'
readonly _NC='\033[0m' # No Color

# Check if colors should be used
_use_colors() {
    [[ -t 2 && "${NO_COLOR:-}" != "1" && "${GIIL_LOG_FORMAT}" == "text" ]]
}

# Get ISO timestamp
_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%S.%3NZ" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# JSON-escape a string
_json_escape() {
    local str="$1"
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    str="${str//$'\n'/\\n}"
    str="${str//$'\r'/\\r}"
    str="${str//$'\t'/\\t}"
    printf '%s' "$str"
}

# Core logging function
_log() {
    local level="$1"
    local msg="$2"
    local extra="${3:-}"

    if [[ "${GIIL_LOG_FORMAT}" == "json" ]]; then
        local json="{\"ts\":\"$(_timestamp)\",\"level\":\"$level\",\"msg\":\"$(_json_escape "$msg")\""
        if [[ -n "$extra" ]]; then
            json="${json},${extra}"
        fi
        json="${json}}"
        echo "$json" >&2
    else
        local ts
        ts="$(_timestamp)"
        local color=""
        local label=""

        case "$level" in
            INFO)  color="${_BLUE}"; label="INFO" ;;
            PASS)  color="${_GREEN}"; label="PASS" ;;
            FAIL)  color="${_RED}"; label="FAIL" ;;
            WARN)  color="${_YELLOW}"; label="WARN" ;;
            DEBUG) color=""; label="DEBUG" ;;
            *)     color=""; label="$level" ;;
        esac

        if _use_colors; then
            printf "[%s] [${color}%s${_NC}] %s\n" "$ts" "$label" "$msg" >&2
        else
            printf "[%s] [%s] %s\n" "$ts" "$label" "$msg" >&2
        fi
    fi
}

# Public logging functions
log_info() {
    _log "INFO" "$*"
}

log_pass() {
    _log "PASS" "$*"
}

log_fail() {
    _log "FAIL" "$*"
}

log_warn() {
    _log "WARN" "$*"
}

log_debug() {
    if [[ "${GIIL_DEBUG:-}" == "1" ]]; then
        _log "DEBUG" "$*"
    fi
}

# Log with timing information
log_timing() {
    local duration_ms="$1"
    local msg="$2"
    _log "INFO" "$msg" "\"duration_ms\":$duration_ms"
}

# Test result logging with structured data
log_test_result() {
    local name="$1"
    local test_status="$2"  # pass|fail|skip
    local duration_ms="${3:-0}"
    local error_msg="${4:-}"

    local level="INFO"
    [[ "$test_status" == "pass" ]] && level="PASS"
    [[ "$test_status" == "fail" ]] && level="FAIL"

    local extra="\"test\":\"$(_json_escape "$name")\",\"status\":\"$test_status\",\"duration_ms\":$duration_ms"
    if [[ -n "$error_msg" ]]; then
        extra="${extra},\"error\":\"$(_json_escape "$error_msg")\""
    fi

    if [[ "${GIIL_LOG_FORMAT}" == "json" ]]; then
        _log "$level" "Test: $name" "$extra"
    else
        local status_str
        case "$test_status" in
            pass) status_str="PASS" ;;
            fail) status_str="FAIL" ;;
            skip) status_str="SKIP" ;;
            *)    status_str="$test_status" ;;
        esac
        _log "$level" "Test: $name [$status_str] (${duration_ms}ms)"
    fi
}

# Suite summary logging
log_suite_summary() {
    local suite_name="$1"
    local passed="$2"
    local failed="$3"
    local skipped="${4:-0}"
    local duration_ms="${5:-0}"

    local total=$((passed + failed + skipped))
    local suite_status="pass"
    [[ "$failed" -gt 0 ]] && suite_status="fail"

    local extra="\"suite\":\"$(_json_escape "$suite_name")\",\"passed\":$passed,\"failed\":$failed,\"skipped\":$skipped,\"total\":$total,\"duration_ms\":$duration_ms"

    if [[ "${GIIL_LOG_FORMAT}" == "json" ]]; then
        _log "INFO" "Suite complete: $suite_name" "$extra"
    else
        if [[ "$failed" -gt 0 ]]; then
            log_fail "Suite: $suite_name - $passed passed, $failed failed, $skipped skipped (${duration_ms}ms)"
        else
            log_pass "Suite: $suite_name - $passed passed, $failed failed, $skipped skipped (${duration_ms}ms)"
        fi
    fi

    # Return non-zero if any tests failed
    [[ "$failed" -eq 0 ]]
}

# Separator for visual clarity in text mode
log_separator() {
    if [[ "${GIIL_LOG_FORMAT}" != "json" ]]; then
        echo "-------------------------------------------" >&2
    fi
}

# Section header
log_section() {
    local title="$1"
    if [[ "${GIIL_LOG_FORMAT}" == "json" ]]; then
        _log "INFO" "Section: $title" "\"section\":\"$(_json_escape "$title")\""
    else
        echo "" >&2
        if _use_colors; then
            printf "${_BLUE}=== %s ===${_NC}\n" "$title" >&2
        else
            printf "=== %s ===\n" "$title" >&2
        fi
    fi
}

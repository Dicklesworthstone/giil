#!/usr/bin/env bash
# Run bash unit tests using bats
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check for bats
if ! command -v bats &> /dev/null; then
    echo "[error] bats is not installed. Install with: npm install -g bats" >&2
    exit 1
fi

echo "=== Bash Unit Tests ==="
bats "$SCRIPT_DIR"/*.bats

#!/bin/bash
# =============================================================================
# LocalStack Pro Samples - Shared Utility Library
# =============================================================================
# Source this file in your scripts:
#   source "$(dirname "$0")/../../scripts/lib.sh"
# or
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "$SCRIPT_DIR/../../scripts/lib.sh"
# =============================================================================

# Determine AWS CLI to use
if command -v awslocal &> /dev/null; then
    AWS="awslocal"
else
    AWS="aws --endpoint-url=http://localhost:4566"
fi

# Default region
REGION="${AWS_DEFAULT_REGION:-us-east-1}"

# =============================================================================
# poll - Execute a command repeatedly until it succeeds or times out
# =============================================================================
# Usage:
#   poll [OPTIONS] COMMAND [ARGS...]
#
# Options:
#   -t, --timeout SECONDS    Maximum time to wait (default: 60)
#   -i, --interval SECONDS   Time between attempts (default: 2)
#   -m, --message MESSAGE    Message to display while waiting
#   -q, --quiet              Suppress progress output
#
# Examples:
#   # Wait for Lambda to be active
#   poll -t 60 -m "Waiting for Lambda..." \
#       bash -c '$AWS lambda get-function --function-name my-func --query "Configuration.State" --output text | grep -q "Active"'
#
#   # Wait for URL to respond
#   poll -t 30 curl -sf http://localhost:8080/health
#
# Returns: 0 if command succeeds, 1 if timeout
# =============================================================================
poll() {
    local timeout=60
    local interval=2
    local message=""
    local quiet=false

    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -t|--timeout)
                timeout="$2"
                shift 2
                ;;
            -i|--interval)
                interval="$2"
                shift 2
                ;;
            -m|--message)
                message="$2"
                shift 2
                ;;
            -q|--quiet)
                quiet=true
                shift
                ;;
            --)
                shift
                break
                ;;
            *)
                break
                ;;
        esac
    done

    local start_time=$(date +%s)
    local end_time=$((start_time + timeout))
    local attempt=1

    [[ -n "$message" && "$quiet" != "true" ]] && echo "$message"

    while true; do
        if "$@" >/dev/null 2>&1; then
            [[ "$quiet" != "true" ]] && echo "  OK (attempt $attempt)"
            return 0
        fi

        local now=$(date +%s)
        if [[ $now -ge $end_time ]]; then
            [[ "$quiet" != "true" ]] && echo "  TIMEOUT after ${timeout}s"
            return 1
        fi

        [[ "$quiet" != "true" ]] && echo -n "."
        sleep "$interval"
        ((attempt++))
    done
}

# =============================================================================
# wait_for_lambda - Wait for a Lambda function to be Active
# =============================================================================
# Usage:
#   wait_for_lambda FUNCTION_NAME [TIMEOUT_SECONDS]
#
# Returns: 0 if function becomes Active, 1 if timeout
# =============================================================================
wait_for_lambda() {
    local function_name="$1"
    local timeout="${2:-60}"

    poll -t "$timeout" -m "Waiting for Lambda '$function_name' to be active..." -- \
        bash -c "state=\$($AWS lambda get-function --function-name '$function_name' --query 'Configuration.State' --output text --region '$REGION' 2>/dev/null); [[ \"\$state\" == 'Active' ]]"
}

# =============================================================================
# wait_for_url - Wait for a URL to respond successfully
# =============================================================================
# Usage:
#   wait_for_url URL [TIMEOUT_SECONDS]
#
# Returns: 0 if URL responds with 2xx, 1 if timeout
# =============================================================================
wait_for_url() {
    local url="$1"
    local timeout="${2:-60}"

    poll -t "$timeout" -m "Waiting for URL to respond..." -- \
        curl -sf "$url"
}

# =============================================================================
# wait_for_service - Wait for a LocalStack service to be available
# =============================================================================
# Usage:
#   wait_for_service SERVICE_NAME [TIMEOUT_SECONDS]
#
# Returns: 0 if service is available, 1 if timeout
# =============================================================================
wait_for_service() {
    local service="$1"
    local timeout="${2:-60}"

    poll -t "$timeout" -m "Waiting for LocalStack $service service..." -- \
        bash -c "curl -s http://localhost:4566/_localstack/health | jq -e '.services.$service == \"available\" or .services.$service == \"running\"' >/dev/null 2>&1"
}

# =============================================================================
# retry - Execute a command with retries
# =============================================================================
# Usage:
#   retry [OPTIONS] COMMAND [ARGS...]
#
# Options:
#   -n, --attempts N         Maximum number of attempts (default: 3)
#   -d, --delay SECONDS      Delay between retries (default: 2)
#   -m, --message MESSAGE    Message to display on retry
#
# Example:
#   retry -n 5 -d 3 aws s3 cp file.txt s3://bucket/
#
# Returns: Exit code of the command
# =============================================================================
retry() {
    local attempts=3
    local delay=2
    local message=""

    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--attempts)
                attempts="$2"
                shift 2
                ;;
            -d|--delay)
                delay="$2"
                shift 2
                ;;
            -m|--message)
                message="$2"
                shift 2
                ;;
            --)
                shift
                break
                ;;
            *)
                break
                ;;
        esac
    done

    local attempt=1
    while [[ $attempt -le $attempts ]]; do
        if "$@"; then
            return 0
        fi

        if [[ $attempt -lt $attempts ]]; then
            [[ -n "$message" ]] && echo "$message (attempt $attempt/$attempts, retrying in ${delay}s...)"
            sleep "$delay"
        fi
        ((attempt++))
    done

    return 1
}

# =============================================================================
# assert_eq - Assert two values are equal
# =============================================================================
# Usage:
#   assert_eq "actual" "expected" "test description"
# =============================================================================
assert_eq() {
    local actual="$1"
    local expected="$2"
    local description="${3:-values should be equal}"

    if [[ "$actual" == "$expected" ]]; then
        echo "  PASS: $description"
        return 0
    else
        echo "  FAIL: $description"
        echo "    Expected: $expected"
        echo "    Actual:   $actual"
        return 1
    fi
}

# =============================================================================
# assert_contains - Assert a string contains a substring
# =============================================================================
# Usage:
#   assert_contains "haystack" "needle" "test description"
# =============================================================================
assert_contains() {
    local haystack="$1"
    local needle="$2"
    local description="${3:-should contain substring}"

    if [[ "$haystack" == *"$needle"* ]]; then
        echo "  PASS: $description"
        return 0
    else
        echo "  FAIL: $description"
        echo "    String does not contain: $needle"
        return 1
    fi
}

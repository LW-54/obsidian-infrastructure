#!/bin/sh

# ==============================================================================
# test-1.1-infrastructure.sh
#
# Description:
#   Unit/Integration tests for stage.sh (Infrastructure & Logging).
#   Verifies P0 (Critical) and P1 (High) requirements.
# ==============================================================================

# Determine base directory of the script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_SCRIPT="$SCRIPT_DIR/../scripts/stage.sh"

# Setup isolated test vault
TEST_VAULT="test_vault_1.1"
rm -rf "$TEST_VAULT"
mkdir -p "$TEST_VAULT"
export VAULT_ROOT="$TEST_VAULT"

TEST_LOG_DIR="$TEST_VAULT/99-SYSTEM/logs"
TEST_LOG_FILE="$TEST_LOG_DIR/staging_logs.md"
CONFIG_DIR="$TEST_VAULT/99-SYSTEM/infrastructure"
CONFIG_FILE="$CONFIG_DIR/staging-workflow.md"

# ------------------------------------------------------------------------------
# Test Runner Helpers
# ------------------------------------------------------------------------------
pass=0
fail=0

run_test() {
    desc="$1"
    cmd="$2"
    
    printf "TEST: %s ... " "$desc"
    # Execute the command (function or string)
    if $cmd; then
        printf "PASS\n"
        pass=$((pass + 1))
    else
        printf "FAIL\n"
        fail=$((fail + 1))
    fi
}

setup_config() {
    mkdir -p "$CONFIG_DIR"
    echo '```json' > "$CONFIG_FILE"
    echo '{}' >> "$CONFIG_FILE"
    echo '```' >> "$CONFIG_FILE"
}

# ------------------------------------------------------------------------------
# Tests
# ------------------------------------------------------------------------------

echo "Running Tests for Story 1.1..."

# 1.1-INT-001: Executable check
test_executable() {
    [ -x "$TARGET_SCRIPT" ]
}
run_test "Script is executable" test_executable

# 1.1-E2E-001: Syntax check (POSIX sh)
test_syntax() {
    sh -n "$TARGET_SCRIPT"
}
run_test "POSIX syntax check" test_syntax

# 1.1-UNIT-001a: check_dependencies (jq MISSING)
# We assume jq is missing in this env (or we can't easily force it without complex path manip).
# If jq is present, we skip or mock absence?
# For now, let's try to detect if jq is present first.
jq_present=0
if command -v jq >/dev/null 2>&1; then
    jq_present=1
fi

test_deps_missing() {
    if [ "$jq_present" -eq 1 ]; then
        # jq is present, we can't test "missing" easily without masking it.
        # Masking:
        (
            PATH="/bin:/usr/bin" # Hope jq is not here or we exclude it?
            # Hard to guess where jq is.
            # If we really want to fail, we can define a function jq() { return 127; } ?
            # But the script uses `command -v jq`.
            # So we rely on strict PATH.
            PATH="." # Assume jq is not in .
            "$TARGET_SCRIPT" --dry-run >/dev/null 2>&1
        )
        # Expect failure (exit 1)
        [ $? -eq 1 ]
    else
        # jq is already missing
        ! "$TARGET_SCRIPT" --dry-run >/dev/null 2>&1
    fi
}
run_test "Dependency check (jq missing -> fail)" test_deps_missing

# 1.1-UNIT-001b: check_dependencies (jq PRESENT)
test_deps_present() {
    setup_config
    mkdir -p "$TEST_VAULT/01-STAGING"
    # Use real jq if available, otherwise we might fail if we don't mock. 
    # But previous tests showed jq IS available in this env.
    "$TARGET_SCRIPT" --dry-run >/dev/null 2>&1
}
run_test "Dependency check (jq present -> pass)" test_deps_present

# 1.1-INT-002 & UNIT-003: Logging
test_logging() {
    rm -rf "$TEST_LOG_DIR"
    setup_config
    mkdir -p "$TEST_VAULT/01-STAGING"
    
    "$TARGET_SCRIPT" --dry-run >/dev/null 2>&1
    
    if [ ! -f "$TEST_LOG_FILE" ]; then
        echo "DEBUG: Log file not found at $TEST_LOG_FILE"
        return 1
    fi
    # 1.1-UNIT-003: Check format [YYYY-MM-DD HH:MM:SS] [LEVEL] Message
    grep -q "^\[[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\} [0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\] \[INFO\] Starting stage.sh in DRY RUN mode\." "$TEST_LOG_FILE"
}
run_test "Log file creation and format (1.1-UNIT-003)" test_logging

# 1.1-UNIT-004 & 005: Argument Parsing
test_standard_run() {
    setup_config
    "$TARGET_SCRIPT" >/dev/null 2>&1
    grep -q "\[INFO\] Starting stage.sh execution." "$TEST_LOG_FILE"
}
run_test "Standard run logging (1.1-UNIT-004)" test_standard_run

test_mixed_args() {
    rm -rf "$TEST_LOG_DIR"
    setup_config
    "$TARGET_SCRIPT" --some-other-arg --dry-run --another-one >/dev/null 2>&1
    grep -q "\[INFO\] Starting stage.sh in DRY RUN mode." "$TEST_LOG_FILE"
}
run_test "Mixed arguments handling (1.1-UNIT-005)" test_mixed_args

# ------------------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------------------
echo "----------------------------------------------------------------"
echo "Results: $pass PASS, $fail FAIL"
rm -rf "$TEST_VAULT"
if [ "$fail" -eq 0 ]; then
    exit 0
else
    exit 1
fi
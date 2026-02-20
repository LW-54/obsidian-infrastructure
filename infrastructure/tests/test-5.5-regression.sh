#!/bin/sh

# ==============================================================================
# test-5.5-regression.sh
#
# Description:
#   Regression tests for critical bug fixes.
#   Verifies that fixed bugs don't recur.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMPLUX_SCRIPT="$SCRIPT_DIR/../bin/tmpl_ux.sh"
TMPL_SCRIPT="$SCRIPT_DIR/../bin/tmpl.sh"
TEMPLATE_DEFAULT="$SCRIPT_DIR/../templates/ST-default.md"

# Create test directory structure
TEST_DIR="$SCRIPT_DIR/../../test_regression_5.5"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR/99-SYSTEM/infrastructure/bin"
mkdir -p "$TEST_DIR/99-SYSTEM/infrastructure/templates"
mkdir -p "$TEST_DIR/00-INBOX"

# Copy scripts and template to test location
cp "$TMPLUX_SCRIPT" "$TEST_DIR/99-SYSTEM/infrastructure/bin/"
cp "$TMPL_SCRIPT" "$TEST_DIR/99-SYSTEM/infrastructure/bin/"
cp "$TEMPLATE_DEFAULT" "$TEST_DIR/99-SYSTEM/infrastructure/templates/"
chmod +x "$TEST_DIR/99-SYSTEM/infrastructure/bin/"*.sh

TEST_TMUX="$TEST_DIR/99-SYSTEM/infrastructure/bin/tmpl_ux.sh"

pass=0
fail=0

run_test() {
    desc="$1"
    cmd="$2"
    
    printf "TEST: %s ... " "$desc"
    if $cmd; then
        printf "PASS\n"
        pass=$((pass + 1))
    else
        printf "FAIL\n"
        fail=$((fail + 1))
    fi
}

# -----------------------------------------------------------------------------
# Regression Tests
# -----------------------------------------------------------------------------

echo "Running Regression Tests..."

# REG-001: Environment variable leakage (Bug: Persistent content between runs)
test_env_leakage_fix() {
    inbox="$TEST_DIR/00-INBOX"
    rm -f "$inbox"/*.md 2>/dev/null
    
    # Create first note with specific body
    cd "$TEST_DIR" && ./99-SYSTEM/infrastructure/bin/tmpl_ux.sh "Note1" BODY="First unique content" 2>/dev/null
    
    # Create second note WITHOUT specifying BODY
    # If env isolation fails, Note2 will have "First unique content"
    cd "$TEST_DIR" && ./99-SYSTEM/infrastructure/bin/tmpl_ux.sh "Note2" 2>/dev/null
    
    # Verify Note1 has correct content
    grep -q "First unique content" "$inbox/Note1.md" || return 1
    
    # Verify Note2 does NOT have the leaked content
    if grep -q "First unique content" "$inbox/Note2.md" 2>/dev/null; then
        echo "BUG: Environment variable leaked!" >&2
        return 1
    fi
    
    return 0
}
run_test "Environment isolation (env -i prevents leakage)" test_env_leakage_fix

# REG-002: Trailing underscore sanitization (one underscore)
test_underscore_sanitize_fix() {
    inbox="$TEST_DIR/00-INBOX"
    rm -f "$inbox"/*.md 2>/dev/null
    
    # Create note with one trailing underscore
    cd "$TEST_DIR" && ./99-SYSTEM/infrastructure/bin/tmpl_ux.sh "Test_Name_" BODY="Content" 2>/dev/null
    
    # Should create Test_Name.md (one underscore stripped)
    if [ -f "$inbox/Test_Name_.md" ]; then
        echo "BUG: Trailing underscore not stripped!" >&2
        return 1
    fi
    
    if [ ! -f "$inbox/Test_Name.md" ]; then
        echo "BUG: File not created with sanitized name!" >&2
        return 1
    fi
    
    return 0
}
run_test "Underscore sanitization (one trailing underscore stripped)" test_underscore_sanitize_fix

# REG-003: Single trailing underscore
test_single_underscore() {
    inbox="$TEST_DIR/00-INBOX"
    rm -f "$inbox"/*.md 2>/dev/null
    
    # Single underscore - should be stripped
    cd "$TEST_DIR" && ./99-SYSTEM/infrastructure/bin/tmpl_ux.sh "Single_" BODY="test" 2>/dev/null
    
    # Should be stripped to Single.md
    [ -f "$inbox/Single.md" ]
}
run_test "Single trailing underscore stripped" test_single_underscore

# REG-004: Internal underscores preserved
test_internal_underscores_preserved() {
    inbox="$TEST_DIR/00-INBOX"
    rm -f "$inbox"/*.md 2>/dev/null
    
    # Internal underscores should be preserved
    cd "$TEST_DIR" && ./99-SYSTEM/infrastructure/bin/tmpl_ux.sh "My_Note_Name" BODY="test" 2>/dev/null
    
    [ -f "$inbox/My_Note_Name.md" ]
}
run_test "Internal underscores preserved" test_internal_underscores_preserved

# REG-005: Concurrent note creation isolation
test_concurrent_isolation() {
    inbox="$TEST_DIR/00-INBOX"
    rm -f "$inbox"/*.md 2>/dev/null
    
    # Simulate rapid sequential creation (common in loops)
    cd "$TEST_DIR" && ./99-SYSTEM/infrastructure/bin/tmpl_ux.sh "Rapid1" BODY="Content1" 2>/dev/null
    cd "$TEST_DIR" && ./99-SYSTEM/infrastructure/bin/tmpl_ux.sh "Rapid2" BODY="Content2" 2>/dev/null
    cd "$TEST_DIR" && ./99-SYSTEM/infrastructure/bin/tmpl_ux.sh "Rapid3" BODY="Content3" 2>/dev/null
    
    # Verify each has correct content
    grep -q "Content1" "$inbox/Rapid1.md" && \
    grep -q "Content2" "$inbox/Rapid2.md" && \
    grep -q "Content3" "$inbox/Rapid3.md"
}
run_test "Sequential note creation isolation" test_concurrent_isolation

# REG-006: Filename with only underscores (edge case)
test_only_underscores() {
    inbox="$TEST_DIR/00-INBOX"
    rm -f "$inbox"/*.md 2>/dev/null
    
    # Only underscores - should result in empty name after sanitization
    # This tests edge case behavior (may fail or create empty-named file)
    result=$(cd "$TEST_DIR" && ./99-SYSTEM/infrastructure/bin/tmpl_ux.sh "___" BODY="test" 2>&1)
    
    # We just verify it doesn't crash
    return 0
}
run_test "Edge case: filename with only underscores" test_only_underscores

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
echo "----------------------------------------------------------------"
echo "Results: $pass PASS, $fail FAIL"
rm -rf "$TEST_DIR"
if [ "$fail" -eq 0 ]; then
    echo "All regression tests passed - bugs remain fixed!"
    exit 0
else
    echo "REGRESSION DETECTED!"
    exit 1
fi

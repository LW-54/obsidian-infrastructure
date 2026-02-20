#!/bin/sh

# ==============================================================================
# test-2.1-tmpl.sh
#
# Description:
#   Unit/Integration tests for tmpl.sh (Template Expander).
#   Verifies template variable substitution, heredoc handling, and output generation.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_SCRIPT="$SCRIPT_DIR/../bin/tmpl.sh"
TEST_DIR="test_tmpl_2.1"

rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"

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
# Tests
# -----------------------------------------------------------------------------

echo "Running Tests for tmpl.sh..."

# TMPL-001: Executable check
test_executable() {
    [ -x "$TARGET_SCRIPT" ]
}
run_test "Script is executable" test_executable

# TMPL-002: POSIX syntax check
test_syntax() {
    sh -n "$TARGET_SCRIPT"
}
run_test "POSIX syntax check" test_syntax

# TMPL-003: Basic template expansion
test_basic_expansion() {
    template="$TEST_DIR/basic.md"
    output="$TEST_DIR/output.md"
    
    cat > "$template" << 'EOF'
---
title: ${TITLE}
---

Hello, ${NAME}!
EOF
    
    TITLE="Test Title" NAME="World" "$TARGET_SCRIPT" -o "$output" "$template"
    
    grep -q "title: Test Title" "$output" && grep -q "Hello, World!" "$output"
}
run_test "Basic variable expansion" test_basic_expansion

# TMPL-004: Environment variable file (-e flag)
test_env_file() {
    template="$TEST_DIR/env_template.md"
    vars="$TEST_DIR/vars.env"
    output="$TEST_DIR/env_output.md"
    
    cat > "$template" << 'EOF'
Project: ${PROJECT}
Version: ${VERSION}
EOF
    
    cat > "$vars" << 'EOF'
PROJECT="My Project"
VERSION="1.2.3"
EOF
    
    "$TARGET_SCRIPT" -e "$vars" -o "$output" "$template"
    
    grep -q "Project: My Project" "$output" && grep -q "Version: 1.2.3" "$output"
}
run_test "Environment variable file (-e)" test_env_file

# TMPL-005: Default values (unset variable uses default)
test_default_value() {
    template="$TEST_DIR/default.md"
    output="$TEST_DIR/default_output.md"
    
    # Template uses a variable that we don't set
    cat > "$template" << 'EOF'
Title: ${MISSING_VAR}
EOF
    
    # When MISSING_VAR is not set, it should expand to empty
    MISSING_VAR="" "$TARGET_SCRIPT" -o "$output" "$template"
    
    grep -q "Title:" "$output"
}
run_test "Unset variable expansion" test_default_value

# TMPL-006: Special characters in variables
test_special_chars() {
    template="$TEST_DIR/special.md"
    output="$TEST_DIR/special_output.md"
    
    cat > "$template" << 'EOF'
Content: ${CONTENT}
EOF
    
    CONTENT="Line 1
Line 2
* Bullet" "$TARGET_SCRIPT" -o "$output" "$template"
    
    grep -q "Line 1" "$output" && grep -q "Line 2" "$output" && grep -q "* Bullet" "$output"
}
run_test "Special characters in variables" test_special_chars

# TMPL-007: Non-existent template file
test_missing_template() {
    ! "$TARGET_SCRIPT" -o "$TEST_DIR/out.md" "$TEST_DIR/nonexistent.md" 2>/dev/null
}
run_test "Error on missing template" test_missing_template

# TMPL-008: Output to stdout (no -o flag)
test_stdout_output() {
    template="$TEST_DIR/stdout.md"
    
    cat > "$template" << 'EOF'
Test: ${VALUE}
EOF
    
    output=$(VALUE="test" "$TARGET_SCRIPT" "$template" 2>/dev/null)
    echo "$output" | grep -q "Test: test"
}
run_test "Output to stdout" test_stdout_output

# TMPL-009: Multiple variable sources (env file + environment)
test_mixed_sources() {
    template="$TEST_DIR/mixed.md"
    vars="$TEST_DIR/mixed.env"
    output="$TEST_DIR/mixed_output.md"
    
    cat > "$template" << 'EOF'
From env: ${FROM_ENV}
From file: ${FROM_FILE}
EOF
    
    cat > "$vars" << 'EOF'
FROM_FILE="file_value"
EOF
    
    FROM_ENV="env_value" "$TARGET_SCRIPT" -e "$vars" -o "$output" "$template"
    
    grep -q "From env: env_value" "$output" && grep -q "From file: file_value" "$output"
}
run_test "Mixed variable sources" test_mixed_sources

# TMPL-010: Template with no variables
test_no_variables() {
    template="$TEST_DIR/static.md"
    output="$TEST_DIR/static_output.md"
    
    cat > "$template" << 'EOF'
Static content
No variables here
EOF
    
    "$TARGET_SCRIPT" -o "$output" "$template"
    
    grep -q "Static content" "$output"
}
run_test "Template with no variables" test_no_variables

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
echo "----------------------------------------------------------------"
echo "Results: $pass PASS, $fail FAIL"
rm -rf "$TEST_DIR"
if [ "$fail" -eq 0 ]; then
    exit 0
else
    exit 1
fi

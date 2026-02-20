#!/bin/sh

# ==============================================================================
# test-2.2-tmpl_ux.sh
#
# Description:
#   Unit/Integration tests for tmpl_ux.sh (Template Wrapper).
#   Verifies bug fixes (env isolation, underscore sanitization), note creation,
#   and argument parsing.
#
# Note: tmpl_ux.sh calculates VAULT_ROOT as SCRIPT_DIR/../../..
# So we need: TEST_DIR/99-SYSTEM/infrastructure/bin/ structure
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_SCRIPT="$SCRIPT_DIR/../bin/tmpl_ux.sh"
TMPL_SCRIPT="$SCRIPT_DIR/../bin/tmpl.sh"
TEMPLATE_DEFAULT="$SCRIPT_DIR/../templates/ST-default.md"

# Create test directory structure that tmpl_ux.sh expects
# tmpl_ux.sh goes up 3 levels from infrastructure/bin/ to find vault root
TEST_DIR="$SCRIPT_DIR/../../test_tmplux_2.2"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR/99-SYSTEM/infrastructure/bin"
mkdir -p "$TEST_DIR/99-SYSTEM/infrastructure/templates"
mkdir -p "$TEST_DIR/00-INBOX"

# Copy scripts and template to test location
cp "$TARGET_SCRIPT" "$TEST_DIR/99-SYSTEM/infrastructure/bin/"
cp "$TMPL_SCRIPT" "$TEST_DIR/99-SYSTEM/infrastructure/bin/"
cp "$TEMPLATE_DEFAULT" "$TEST_DIR/99-SYSTEM/infrastructure/templates/"
chmod +x "$TEST_DIR/99-SYSTEM/infrastructure/bin/"*.sh

# Use the copied script for testing
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
# Tests
# -----------------------------------------------------------------------------

echo "Running Tests for tmpl_ux.sh..."

# TMPLUX-001: Executable check
test_executable() {
    [ -x "$TEST_TMUX" ]
}
run_test "Script is executable" test_executable

# TMPLUX-002: POSIX syntax check
test_syntax() {
    sh -n "$TEST_TMUX"
}
run_test "POSIX syntax check" test_syntax

# TMPLUX-003: Basic note creation
test_basic_note() {
    inbox="$TEST_DIR/00-INBOX"
    rm -f "$inbox"/*.md 2>/dev/null
    
    cd "$TEST_DIR" && ./99-SYSTEM/infrastructure/bin/tmpl_ux.sh "TestNote" BODY="Test content" 2>/dev/null
    
    [ -f "$inbox/TestNote.md" ]
}
run_test "Basic note creation" test_basic_note

# TMPLUX-004: Bug fix - underscore sanitization (one trailing underscore removal)
test_underscore_sanitize() {
    inbox="$TEST_DIR/00-INBOX"
    rm -f "$inbox"/*.md 2>/dev/null
    
    # Test single trailing underscore
    cd "$TEST_DIR" && ./99-SYSTEM/infrastructure/bin/tmpl_ux.sh "NoteWithUnderscore_" BODY="content" 2>/dev/null
    
    # Should create NoteWithUnderscore.md (one trailing underscore stripped)
    [ -f "$inbox/NoteWithUnderscore.md" ] && [ ! -f "$inbox/NoteWithUnderscore_.md" ]
}
run_test "Underscore sanitization (bug fix)" test_underscore_sanitize

# TMPLUX-005: Bug fix - environment isolation (env -i)
test_env_isolation() {
    inbox="$TEST_DIR/00-INBOX"
    rm -f "$inbox"/*.md 2>/dev/null
    
    # Set a variable that should NOT leak to next invocation
    export BODY="Leaked content"
    
    # Create first note with specific body
    cd "$TEST_DIR" && ./99-SYSTEM/infrastructure/bin/tmpl_ux.sh "FirstNote" BODY="First content" 2>/dev/null
    
    # Create second note without specifying BODY
    # If env isolation works, BODY should be empty/default, not "First content"
    cd "$TEST_DIR" && ./99-SYSTEM/infrastructure/bin/tmpl_ux.sh "SecondNote" 2>/dev/null
    
    # The second note should not contain "First content" (env isolation check)
    ! grep -q "First content" "$inbox/SecondNote.md" 2>/dev/null
}
run_test "Environment isolation (env -i bug fix)" test_env_isolation

# TMPLUX-006: Custom template (-T flag)
test_custom_template() {
    inbox="$TEST_DIR/00-INBOX"
    templates="$TEST_DIR/99-SYSTEM/infrastructure/templates"
    rm -f "$inbox"/*.md 2>/dev/null
    
    cat > "$templates/custom.md" << 'EOF'
---
custom: ${CUSTOM}
---

${CUSTOM_BODY}
EOF
    
    cd "$TEST_DIR" && ./99-SYSTEM/infrastructure/bin/tmpl_ux.sh "CustomNote" -T "$templates/custom.md" CUSTOM="value" CUSTOM_BODY="Custom body" 2>/dev/null
    
    grep -q "custom: value" "$inbox/CustomNote.md" && grep -q "Custom body" "$inbox/CustomNote.md"
}
run_test "Custom template (-T flag)" test_custom_template

# TMPLUX-007: Multiple KEY=VALUE arguments
test_multiple_vars() {
    inbox="$TEST_DIR/00-INBOX"
    rm -f "$inbox"/*.md 2>/dev/null
    
    cd "$TEST_DIR" && ./99-SYSTEM/infrastructure/bin/tmpl_ux.sh "MultiNote" BODY="Body text" PROJECT="MyProject" STATUS="Active" 2>/dev/null
    
    grep -q "Body text" "$inbox/MultiNote.md"
}
run_test "Multiple KEY=VALUE arguments" test_multiple_vars

# TMPLUX-008: --list flag for YAML lists
test_list_flag() {
    inbox="$TEST_DIR/00-INBOX"
    rm -f "$inbox"/*.md 2>/dev/null
    
    cd "$TEST_DIR" && ./99-SYSTEM/infrastructure/bin/tmpl_ux.sh "ListNote" BODY="test" --list "TAGS=tag1,tag2,tag3" 2>/dev/null
    
    grep -q "tag1" "$inbox/ListNote.md" && grep -q "tag2" "$inbox/ListNote.md"
}
run_test "--list flag for YAML lists" test_list_flag

# TMPLUX-009: Error on duplicate filename
test_duplicate_error() {
    inbox="$TEST_DIR/00-INBOX"
    rm -f "$inbox"/*.md 2>/dev/null
    
    # Create first note
    cd "$TEST_DIR" && ./99-SYSTEM/infrastructure/bin/tmpl_ux.sh "DuplicateTest" BODY="first" 2>/dev/null
    
    # Try to create second with same name - should fail (check exit code)
    cd "$TEST_DIR" && ./99-SYSTEM/infrastructure/bin/tmpl_ux.sh "DuplicateTest" BODY="second" 2>/dev/null
    result=$?
    
    # Should return non-zero exit code
    [ $result -ne 0 ]
}
run_test "Error on duplicate filename" test_duplicate_error

# TMPLUX-010: .md extension handling
test_md_extension() {
    inbox="$TEST_DIR/00-INBOX"
    rm -f "$inbox"/*.md 2>/dev/null
    
    # With .md extension
    cd "$TEST_DIR" && ./99-SYSTEM/infrastructure/bin/tmpl_ux.sh "WithExt.md" BODY="content" 2>/dev/null
    
    # Without .md extension
    cd "$TEST_DIR" && ./99-SYSTEM/infrastructure/bin/tmpl_ux.sh "WithoutExt" BODY="content" 2>/dev/null
    
    # Both should result in .md files
    [ -f "$inbox/WithExt.md" ] && [ -f "$inbox/WithoutExt.md" ]
}
run_test ".md extension handling" test_md_extension

# TMPLUX-011: Variable file (-e flag)
test_var_file() {
    inbox="$TEST_DIR/00-INBOX"
    rm -f "$inbox"/*.md 2>/dev/null
    
    vars="$TEST_DIR/vars.env"
    cat > "$vars" << 'EOF'
BODY="From var file"
PROJECT="TestProject"
EOF
    
    cd "$TEST_DIR" && ./99-SYSTEM/infrastructure/bin/tmpl_ux.sh "VarFileNote" -e "$vars" 2>/dev/null
    
    grep -q "From var file" "$inbox/VarFileNote.md"
}
run_test "Variable file (-e flag)" test_var_file

# TMPLUX-012: Template directory resolution
test_template_resolution() {
    inbox="$TEST_DIR/00-INBOX"
    templates="$TEST_DIR/99-SYSTEM/infrastructure/templates"
    rm -f "$inbox"/*.md 2>/dev/null
    
    # Create a template with specific name
    cat > "$templates/ST-task.md" << 'EOF'
---
type: task
---
Task: ${BODY}
EOF
    
    cd "$TEST_DIR" && ./99-SYSTEM/infrastructure/bin/tmpl_ux.sh "TaskNote" -T "ST-task.md" BODY="Do something" 2>/dev/null
    
    grep -q "type: task" "$inbox/TaskNote.md"
}
run_test "Template directory resolution" test_template_resolution

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

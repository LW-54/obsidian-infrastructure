#!/bin/sh

# ==============================================================================
# test-2.3-task.sh
#
# Description:
#   Unit/Integration tests for task.sh (Task Note Wrapper).
#   Verifies task note creation with proper template selection.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_SCRIPT="$SCRIPT_DIR/../bin/task.sh"
TMPLUX_SCRIPT="$SCRIPT_DIR/../bin/tmpl_ux.sh"
TMPL_SCRIPT="$SCRIPT_DIR/../bin/tmpl.sh"
TEMPLATE_TASK="$SCRIPT_DIR/../templates/ST-task.md"

# Create test directory structure
TEST_DIR="$SCRIPT_DIR/../../test_task_2.3"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR/99-SYSTEM/infrastructure/bin"
mkdir -p "$TEST_DIR/99-SYSTEM/infrastructure/templates"
mkdir -p "$TEST_DIR/00-INBOX"

# Copy scripts and template to test location
cp "$TARGET_SCRIPT" "$TEST_DIR/99-SYSTEM/infrastructure/bin/"
cp "$TMPLUX_SCRIPT" "$TEST_DIR/99-SYSTEM/infrastructure/bin/"
cp "$TMPL_SCRIPT" "$TEST_DIR/99-SYSTEM/infrastructure/bin/"
cp "$TEMPLATE_TASK" "$TEST_DIR/99-SYSTEM/infrastructure/templates/"
chmod +x "$TEST_DIR/99-SYSTEM/infrastructure/bin/"*.sh

TEST_TASK="$TEST_DIR/99-SYSTEM/infrastructure/bin/task.sh"

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

echo "Running Tests for task.sh..."

# TASK-001: Executable check
test_executable() {
    [ -x "$TEST_TASK" ]
}
run_test "Script is executable" test_executable

# TASK-002: POSIX syntax check
test_syntax() {
    sh -n "$TEST_TASK"
}
run_test "POSIX syntax check" test_syntax

# TASK-003: Basic task creation
test_basic_task() {
    inbox="$TEST_DIR/00-INBOX"
    rm -f "$inbox"/*.md 2>/dev/null
    
    cd "$TEST_DIR" && ./99-SYSTEM/infrastructure/bin/task.sh "MyTask" BODY="Complete this task" 2>/dev/null
    
    [ -f "$inbox/MyTask.md" ]
}
run_test "Basic task creation" test_basic_task

# TASK-004: Task uses ST-task.md template
test_task_template() {
    inbox="$TEST_DIR/00-INBOX"
    rm -f "$inbox"/*.md 2>/dev/null
    
    cd "$TEST_DIR" && ./99-SYSTEM/infrastructure/bin/task.sh "TemplateTest" BODY="Test body" 2>/dev/null
    
    # Should contain task-specific markers (from ST-task.md template)
    grep -q "type/task" "$inbox/TemplateTest.md"
}
run_test "Uses ST-task.md template" test_task_template

# TASK-005: Task with status override
test_task_status() {
    inbox="$TEST_DIR/00-INBOX"
    rm -f "$inbox"/*.md 2>/dev/null
    
    cd "$TEST_DIR" && ./99-SYSTEM/infrastructure/bin/task.sh "StatusTask" BODY="Do this" STATUS="In Progress" 2>/dev/null
    
    grep -q "In Progress" "$inbox/StatusTask.md"
}
run_test "Task with status override" test_task_status

# TASK-006: Task with project
test_task_project() {
    inbox="$TEST_DIR/00-INBOX"
    rm -f "$inbox"/*.md 2>/dev/null
    
    cd "$TEST_DIR" && ./99-SYSTEM/infrastructure/bin/task.sh "ProjectTask" BODY="Project work" PROJECT="MyProject" 2>/dev/null
    
    grep -q "MyProject" "$inbox/ProjectTask.md"
}
run_test "Task with project" test_task_project

# TASK-007: Multiple tasks creation
test_multiple_tasks() {
    inbox="$TEST_DIR/00-INBOX"
    rm -f "$inbox"/*.md 2>/dev/null
    
    cd "$TEST_DIR" && ./99-SYSTEM/infrastructure/bin/task.sh "Task1" BODY="First task" 2>/dev/null
    cd "$TEST_DIR" && ./99-SYSTEM/infrastructure/bin/task.sh "Task2" BODY="Second task" 2>/dev/null
    cd "$TEST_DIR" && ./99-SYSTEM/infrastructure/bin/task.sh "Task3" BODY="Third task" 2>/dev/null
    
    [ -f "$inbox/Task1.md" ] && [ -f "$inbox/Task2.md" ] && [ -f "$inbox/Task3.md" ]
}
run_test "Multiple tasks creation" test_multiple_tasks

# TASK-008: Task with due date
test_task_due_date() {
    inbox="$TEST_DIR/00-INBOX"
    rm -f "$inbox"/*.md 2>/dev/null
    
    cd "$TEST_DIR" && ./99-SYSTEM/infrastructure/bin/task.sh "DueTask" BODY="Urgent" DUE_DATE="2026-03-01" 2>/dev/null
    
    grep -q "2026-03-01" "$inbox/DueTask.md"
}
run_test "Task with due date" test_task_due_date

# TASK-009: Task with tags
test_task_tags() {
    inbox="$TEST_DIR/00-INBOX"
    rm -f "$inbox"/*.md 2>/dev/null
    
    cd "$TEST_DIR" && ./99-SYSTEM/infrastructure/bin/task.sh "TaggedTask" BODY="Work" TAGS="  - work
  - urgent" 2>/dev/null
    
    grep -q "work" "$inbox/TaggedTask.md"
}
run_test "Task with tags" test_task_tags

# TASK-010: Error when tmpl_ux.sh not found
test_missing_tmplux() {
    # Save original
    OLD_TUX="$TEST_DIR/99-SYSTEM/infrastructure/bin/tmpl_ux.sh"
    mv "$OLD_TUX" "$OLD_TUX.bak"
    
    result=0
    cd "$TEST_DIR" && ./99-SYSTEM/infrastructure/bin/task.sh "Test" 2>/dev/null || result=1
    
    mv "$OLD_TUX.bak" "$OLD_TUX"
    [ $result -eq 1 ]
}
run_test "Error when tmpl_ux.sh not found" test_missing_tmplux

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

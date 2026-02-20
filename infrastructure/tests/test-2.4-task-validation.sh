#!/bin/sh

# ==============================================================================
# test-2.4-task-validation.sh
#
# Description:
#   Tests for task-specific validation requirements.
#   Verifies that tasks require 'id' and 'status' fields,
#   and that status must be one of: To Do, Done, Canceled
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STAGE_SCRIPT="$SCRIPT_DIR/../bin/stage.sh"

# Create test vault structure
TEST_DIR="$SCRIPT_DIR/../../test_task_validation_2.4"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR/01-STAGING"
mkdir -p "$TEST_DIR/02-REFACTORING"
mkdir -p "$TEST_DIR/03-ZETTELKASTEN/Tasks"
mkdir -p "$TEST_DIR/99-SYSTEM/logs"
mkdir -p "$TEST_DIR/infrastructure/config"

# Copy stage.sh
mkdir -p "$TEST_DIR/infrastructure/bin"
cp "$STAGE_SCRIPT" "$TEST_DIR/infrastructure/bin/"
chmod +x "$TEST_DIR/infrastructure/bin/stage.sh"

# Create config with task validation
cat > "$TEST_DIR/infrastructure/config/staging-workflow.md" << 'EOF'
---
type: configuration
desc: Staging workflow rules
---

# Staging Workflow Configuration

```json
{
  "task": {
    "destination": "03-ZETTELKASTEN/Tasks",
    "fields": {
      "id": "",
      "status": "[ \"$status\" = \"To Do\" ] || [ \"$status\" = \"Done\" ] || [ \"$status\" = \"Canceled\" ]"
    }
  }
}
```
EOF

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

echo "Running Task Validation Tests..."

# TEST-001: Task with valid status "To Do" passes
test_task_todo_status() {
    rm -f "$TEST_DIR/01-STAGING"/*.md "$TEST_DIR/03-ZETTELKASTEN/Tasks"/*.md 2>/dev/null
    
    cat > "$TEST_DIR/01-STAGING/valid-todo.md" << 'EOF'
---
Type: task
id: 20260220120000
status: To Do
---

Task content here
EOF
    
    cd "$TEST_DIR" && ./infrastructure/bin/stage.sh 2>/dev/null
    
    [ -f "$TEST_DIR/03-ZETTELKASTEN/Tasks/valid-todo.md" ]
}
run_test "Task with status 'To Do' passes validation" test_task_todo_status

# TEST-002: Task with valid status "Done" passes
test_task_done_status() {
    rm -f "$TEST_DIR/01-STAGING"/*.md "$TEST_DIR/03-ZETTELKASTEN/Tasks"/*.md 2>/dev/null
    
    cat > "$TEST_DIR/01-STAGING/valid-done.md" << 'EOF'
---
Type: task
id: 20260220120001
status: Done
---

Task content here
EOF
    
    cd "$TEST_DIR" && ./infrastructure/bin/stage.sh 2>/dev/null
    
    [ -f "$TEST_DIR/03-ZETTELKASTEN/Tasks/valid-done.md" ]
}
run_test "Task with status 'Done' passes validation" test_task_done_status

# TEST-003: Task with valid status "Canceled" passes
test_task_canceled_status() {
    rm -f "$TEST_DIR/01-STAGING"/*.md "$TEST_DIR/03-ZETTELKASTEN/Tasks"/*.md 2>/dev/null
    
    cat > "$TEST_DIR/01-STAGING/valid-canceled.md" << 'EOF'
---
Type: task
id: 20260220120002
status: Canceled
---

Task content here
EOF
    
    cd "$TEST_DIR" && ./infrastructure/bin/stage.sh 2>/dev/null
    
    [ -f "$TEST_DIR/03-ZETTELKASTEN/Tasks/valid-canceled.md" ]
}
run_test "Task with status 'Canceled' passes validation" test_task_canceled_status

# TEST-004: Task with invalid status fails
test_task_invalid_status() {
    rm -f "$TEST_DIR/01-STAGING"/*.md "$TEST_DIR/02-REFACTORING"/*.md 2>/dev/null
    
    cat > "$TEST_DIR/01-STAGING/invalid-status.md" << 'EOF'
---
Type: task
id: 20260220120003
status: In Progress
---

Task content here
EOF
    
    cd "$TEST_DIR" && ./infrastructure/bin/stage.sh 2>/dev/null
    
    # Should be moved to REFACTORING due to invalid status
    [ -f "$TEST_DIR/02-REFACTORING/invalid-status.md" ]
}
run_test "Task with invalid status 'In Progress' fails validation" test_task_invalid_status

# TEST-005: Task without status fails
test_task_missing_status() {
    rm -f "$TEST_DIR/01-STAGING"/*.md "$TEST_DIR/02-REFACTORING"/*.md 2>/dev/null
    
    cat > "$TEST_DIR/01-STAGING/missing-status.md" << 'EOF'
---
Type: task
id: 20260220120004
---

Task content here
EOF
    
    cd "$TEST_DIR" && ./infrastructure/bin/stage.sh 2>/dev/null
    
    # Should be moved to REFACTORING due to missing status
    [ -f "$TEST_DIR/02-REFACTORING/missing-status.md" ]
}
run_test "Task without status fails validation" test_task_missing_status

# TEST-006: Task without id fails
test_task_missing_id() {
    rm -f "$TEST_DIR/01-STAGING"/*.md "$TEST_DIR/02-REFACTORING"/*.md 2>/dev/null
    
    cat > "$TEST_DIR/01-STAGING/missing-id.md" << 'EOF'
---
Type: task
status: To Do
---

Task content here
EOF
    
    cd "$TEST_DIR" && ./infrastructure/bin/stage.sh 2>/dev/null
    
    # Should be moved to REFACTORING due to missing id (lowercase)
    [ -f "$TEST_DIR/02-REFACTORING/missing-id.md" ] || [ -f "$TEST_DIR/02-REFACTORING/missing-id.md" ]
}
run_test "Task without id fails validation" test_task_missing_id

# TEST-007: Task with empty status fails
test_task_empty_status() {
    rm -f "$TEST_DIR/01-STAGING"/*.md "$TEST_DIR/02-REFACTORING"/*.md 2>/dev/null
    
    # Create file with empty status (just the field name with no value)
    cat > "$TEST_DIR/01-STAGING/empty-status.md" << 'EOF'
---
Type: task
id: 20260220120005
status:
---

Task content here
EOF
    
    cd "$TEST_DIR" && ./infrastructure/bin/stage.sh 2>/dev/null
    
    # Should be moved to REFACTORING due to empty status (either missing or failed validation)
    [ -f "$TEST_DIR/02-REFACTORING/empty-status.md" ]
}
run_test "Task with empty status fails validation" test_task_empty_status

# TEST-008: Error callout contains validation failure reason
test_error_callout_content() {
    rm -f "$TEST_DIR/01-STAGING"/*.md "$TEST_DIR/02-REFACTORING"/*.md 2>/dev/null
    
    cat > "$TEST_DIR/01-STAGING/callout-test.md" << 'EOF'
---
Type: task
id: 20260220120006
status: InvalidStatus
---

Task content here
EOF
    
    cd "$TEST_DIR" && ./infrastructure/bin/stage.sh 2>/dev/null
    
    # Error callout should mention the validation failure
    grep -q "Staging Failed" "$TEST_DIR/02-REFACTORING/callout-test.md"
}
run_test "Error callout contains validation failure" test_error_callout_content

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
echo "----------------------------------------------------------------"
echo "Results: $pass PASS, $fail FAIL"
rm -rf "$TEST_DIR"
if [ "$fail" -eq 0 ]; then
    echo "All task validation tests passed!"
    exit 0
else
    exit 1
fi

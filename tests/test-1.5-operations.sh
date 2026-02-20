#!/bin/sh

# Test script for Story 1.5: File Operations

# Set up test environment
VAULT_ROOT="test_vault_1.5"
rm -rf "$VAULT_ROOT"
mkdir -p "$VAULT_ROOT"

# Use generate_test_data.sh to seed
sh scripts/generate_test_data.sh --target "$VAULT_ROOT"

# Add custom test cases
# 1. Invalid note for Error Injection
cat <<EOF > "$VAULT_ROOT/01-STAGING/missing-id.md"
---
Type: Idea
Topic: No ID
---
Content
EOF

# Run stage.sh
export VAULT_ROOT
sh scripts/stage.sh > /dev/null

# Verify Results

pass=0
fail=0

check_file() {
    path="$1"
    desc="$2"
    if [ -f "$path" ]; then
        echo "PASS: $desc found at $path"
        pass=$((pass + 1))
    else
        echo "FAIL: $desc NOT found at $path"
        fail=$((fail + 1))
    fi
}

check_content() {
    path="$1"
    pattern="$2"
    desc="$3"
    if grep -qF "$pattern" "$path"; then
        echo "PASS: $desc in $path"
        pass=$((pass + 1))
    else
        echo "FAIL: $desc missing in $path"
        fail=$((fail + 1))
    fi
}

echo "Verifying File Operations..."

# 1. Valid Moves
check_file "$VAULT_ROOT/03-ZETTELKASTEN/Ideas/valid-idea.md" "Valid Idea"
check_file "$VAULT_ROOT/03-ZETTELKASTEN/Notes/valid-note.md" "Valid Note"

# 2. Collision (collision-test.md exists in dest, so STAGING file moves to REFACTORING)
check_file "$VAULT_ROOT/02-REFACTORING/collision-test.md" "Collision file"
check_content "$VAULT_ROOT/02-REFACTORING/collision-test.md" "> [!WARNING] Staging Failed: Collision: File already exists at destination" "Collision Warning"

# 3. Invalid Note (missing-id.md moves to REFACTORING with error)
check_file "$VAULT_ROOT/02-REFACTORING/missing-id.md" "Invalid file"
check_content "$VAULT_ROOT/02-REFACTORING/missing-id.md" "> [!WARNING] Staging Failed: Missing mandatory field: ID" "Missing ID Warning"

# 4. Missing Type (moves to REFACTORING)
check_file "$VAULT_ROOT/02-REFACTORING/missing-type.md" "Missing Type file"
check_content "$VAULT_ROOT/02-REFACTORING/missing-type.md" "> [!WARNING] Staging Failed: No Type found in frontmatter" "Missing Type Warning"

# 5. Staging Empty
if [ -z "$(ls -A "$VAULT_ROOT/01-STAGING")" ]; then
    echo "PASS: 01-STAGING is empty"
    pass=$((pass + 1))
else
    echo "FAIL: 01-STAGING is not empty"
    ls -l "$VAULT_ROOT/01-STAGING"
    fail=$((fail + 1))
fi

# 6. Summary Log
LOG_FILE="$VAULT_ROOT/99-SYSTEM/logs/staging_logs.md"
if grep -q "Finished processing. Total: 6, Success: 2, Failure: 4." "$LOG_FILE"; then
    echo "PASS: Final summary log correct"
    pass=$((pass + 1))
else
    echo "FAIL: Final summary log incorrect"
    tail -n 5 "$LOG_FILE"
    fail=$((fail + 1))
fi

echo "Results: $pass PASS, $fail FAIL"
rm -rf "$VAULT_ROOT"

if [ "$fail" -eq 0 ]; then
    exit 0
else
    exit 1
fi

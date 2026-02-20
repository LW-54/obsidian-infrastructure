#!/bin/sh

# Test script for Story 1.4: Validation Logic

# Set up test environment
VAULT_ROOT="test_vault_1.4"
rm -rf "$VAULT_ROOT"
mkdir -p "$VAULT_ROOT"

# Use generate_test_data.sh to seed
sh scripts/generate_test_data.sh --target "$VAULT_ROOT"

# Add custom failure cases
# Case 1: Missing ID
cat <<EOF > "$VAULT_ROOT/01-STAGING/missing-id.md"
---
Type: Idea
Topic: No ID
---
Content
EOF

# Case 2: Empty required field
cat <<EOF > "$VAULT_ROOT/01-STAGING/empty-topic.md"
---
Type: Idea
ID: 12345
Topic: 
---
Content
EOF

# Case 3: Failing snippet
cat <<EOF > "$VAULT_ROOT/01-STAGING/inactive-note.md"
---
Type: Note
ID: 12346
Status: Inactive
---
Content
EOF

# Run stage.sh
export VAULT_ROOT
sh scripts/stage.sh > /dev/null

# Verify logs
LOG_FILE="$VAULT_ROOT/99-SYSTEM/logs/staging_logs.md"

check_log() {
    pattern="$1"
    if grep -qF "$pattern" "$LOG_FILE"; then
        echo "PASS: Found '$pattern' in log"
    else
        echo "FAIL: Missing '$pattern' in log"
        # Print log for debugging if fail
        cat "$LOG_FILE"
        exit 1
    fi
}

echo "Verifying validation results..."

# Positive cases
check_log "Processing valid-idea.md: [PASS]"
check_log "Processing valid-note.md: [PASS]"

# Negative cases
check_log "Processing missing-id.md: [FAIL] Missing mandatory field: ID"
check_log "Processing empty-topic.md: [FAIL] Missing or empty required field: Topic"
check_log "Processing inactive-note.md: [FAIL] Validation snippet failed for Status: [ \"\$Status\" = \"Active\" ]"

echo "All Story 1.4 tests passed."
rm -rf "$VAULT_ROOT"

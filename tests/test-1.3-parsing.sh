#!/bin/sh

# Test script for Story 1.3: Core Config Parser & Iteration Loop

# Set up test environment
VAULT_ROOT="test_vault_1.3"
rm -rf "$VAULT_ROOT"
mkdir -p "$VAULT_ROOT/01-STAGING"
mkdir -p "$VAULT_ROOT/99-SYSTEM/infrastructure"
mkdir -p "$VAULT_ROOT/99-SYSTEM/logs"

# Create config
cat <<'EOF' > "$VAULT_ROOT/99-SYSTEM/infrastructure/staging-workflow.md"
# Config
```json
{
  "Idea": {
    "destination": "03-ZETTELKASTEN/Ideas"
  },
  "Note": {
    "destination": "03-ZETTELKASTEN/Notes"
  }
}
```
EOF

# Create test files
cat <<'EOF' > "$VAULT_ROOT/01-STAGING/valid-idea.md"
---
Type: Idea
ID: 1001
---
Body
EOF

cat <<'EOF' > "$VAULT_ROOT/01-STAGING/valid-note.md"
---
Type: Note
ID: 1002
---
Body
EOF

cat <<'EOF' > "$VAULT_ROOT/01-STAGING/missing-type.md"
---
ID: 123
---
Body
EOF

cat <<'EOF' > "$VAULT_ROOT/01-STAGING/bad-fm.md"
---
Type: Idea
No closing dashes
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
        exit 1
    fi
}

echo "Verifying log results..."
# Updated expectations for Story 1.5 logic
check_log "Processing valid-idea.md: [PASS]"
check_log "Processing valid-note.md: [PASS]"
check_log "Processing missing-type.md: No Type found."
check_log "Processing bad-fm.md: No Type found."
check_log "Finished processing. Total: 4, Success: 2, Failure: 2."

echo "All Story 1.3 tests passed."
rm -rf "$VAULT_ROOT"

#!/bin/sh

# Test script for Story 1.3 parsing logic

# 1. Setup Mock Environment
TEST_DIR="test_vault_1.3"
mkdir -p "$TEST_DIR/01-STAGING"
mkdir -p "$TEST_DIR/99-SYSTEM/infrastructure"
mkdir -p "$TEST_DIR/99-SYSTEM/logs"

cat <<'EOF' > "$TEST_DIR/99-SYSTEM/infrastructure/staging-workflow.md"
# Config
```json
{
  "TestType": {
    "destination": "03-ZETTELKASTEN/Test"
  }
}
```
EOF

cat <<'EOF' > "$TEST_DIR/01-STAGING/test-note.md"
---
Type: TestType
ID: 12345
---
Body content
EOF

# 2. Source the script logic
# We need to source it but NOT run main.
# To do this, we can wrap main in a check or just grep the functions.
# Since stage.sh calls main at the end, we might need to modify it or use a trick.

# Trick: Copy stage.sh and remove the main call
cp scripts/stage.sh stage_lib.sh
sed -i '$d' stage_lib.sh # Remove main "$@"

. ./stage_lib.sh

export VAULT_ROOT="$TEST_DIR"

# 3. Test load_config
echo "Testing load_config..."
config=$(load_config)
if printf "%s" "$config" | jq -e '.TestType' > /dev/null; then
    echo "PASS: load_config"
else
    echo "FAIL: load_config"
    exit 1
fi

# 4. Test extract_frontmatter
echo "Testing extract_frontmatter..."
fm=$(extract_frontmatter "$TEST_DIR/01-STAGING/test-note.md")
if printf "%s" "$fm" | grep -q "Type: TestType"; then
    echo "PASS: extract_frontmatter"
else
    echo "FAIL: extract_frontmatter"
    exit 1
fi

# 5. Test get_metadata
echo "Testing get_metadata..."
metadata=$(get_metadata "$fm")
if printf "%s" "$metadata" | jq -e '.Type == "TestType"' > /dev/null; then
    echo "PASS: get_metadata"
else
    echo "FAIL: get_metadata"
    printf "Metadata: %s\n" "$metadata"
    exit 1
fi

echo "All parsing tests passed."
rm stage_lib.sh
rm -rf "$TEST_DIR"

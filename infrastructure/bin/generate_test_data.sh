#!/bin/sh

# ==============================================================================
# generate_test_data.sh - Obsidian Staging Test Data Generator
#
# Description:
#   Generates a mock vault structure with valid, invalid, and collision-prone
#   notes for testing stage.sh.
#
# Usage:
#   ./generate_test_data.sh [--target <path>]
#
# Dependencies:
#   None (Standard POSIX sh)
# ==============================================================================

set -e

# Default target is current directory
TARGET_DIR="."

# Parse arguments
parse_arguments() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --target) 
                if [ -n "$2" ]; then
                    TARGET_DIR="$2"
                    shift 2
                else
                    printf "ERROR: --target requires a path argument.\n" >&2
                    exit 1
                fi
                ;; 
            *)
                printf "ERROR: Unknown argument '%s'\n" "$1" >&2
                exit 1
                ;; 
        esac
    done
}

# Create directory structure
create_directories() {
    printf "INFO: Creating vault structure in '%s'..\n" "$TARGET_DIR"
    mkdir -p "$TARGET_DIR/01-STAGING"
    mkdir -p "$TARGET_DIR/02-REFACTORING"
    mkdir -p "$TARGET_DIR/03-ZETTELKASTEN/Ideas"
    mkdir -p "$TARGET_DIR/03-ZETTELKASTEN/Notes"
    mkdir -p "$TARGET_DIR/infrastructure/config"
}

# Generate config file
create_config() {
    config_file="$TARGET_DIR/infrastructure/config/staging-workflow.md"
    printf "INFO: Generating config at '%s'..\n" "$config_file"
    
    cat <<'EOF' > "$config_file"
# Staging Workflow Configuration

This file contains the rules for processing staged notes.

```json
{
  "Idea": {
    "destination": "03-ZETTELKASTEN/Ideas",
    "fields": {
      "topic": ""
    }
  },
  "Note": {
    "destination": "03-ZETTELKASTEN/Notes",
    "fields": {
      "status": "[ \"$status\" = \"Active\" ]"
    }
  }
}
```
EOF
}

# Generate test notes
create_notes() {
    staging_dir="$TARGET_DIR/01-STAGING"
    
    # 1. Valid Idea
    cat <<EOF > "$staging_dir/valid-idea.md"
---
Type: Idea
id: 20260119001
topic: Automation
---
# Valid Idea
This is a valid idea note.
EOF

    # 2. Valid Note
    cat <<EOF > "$staging_dir/valid-note.md"
---
Type: Note
id: 20260119002
status: Active
---
# Valid Note
This is a valid status note.
EOF

    # 3. Missing Type
    cat <<EOF > "$staging_dir/missing-type.md"
---
id: 20260119003
topic: Lost
---
# Missing Type
This note has no Type field.
EOF

    # 4. Bad Frontmatter (Unclosed)
    cat <<EOF > "$staging_dir/bad-frontmatter.md"
---
Type: Idea
id: 20260119004
# Bad Frontmatter
No closing dashes here.
EOF

    # 5. Collision Test (Source)
    cat <<EOF > "$staging_dir/collision-test.md"
---
Type: Idea
id: 20260119005
topic: Collision
---
# Collision Source
This should collide.
EOF

    # 5b. Collision Test (Target - Pre-existing)
    printf "INFO: Creating collision target...\n"
    cat <<EOF > "$TARGET_DIR/03-ZETTELKASTEN/Ideas/collision-test.md"
---
Type: Idea
id: 20260119000
topic: Original
---
# Original Note
I was here first.
EOF
}

# Main execution
main() {
    parse_arguments "$@"
    
    # Safety check: Don't run in root or obvious system paths if target is .
    # (Simple heuristic, relying on user responsibility mostly)
    
    create_directories
    create_config
    create_notes
    
    printf "SUCCESS: Test data generated in '%s'.\n" "$TARGET_DIR"
}

main "$@"

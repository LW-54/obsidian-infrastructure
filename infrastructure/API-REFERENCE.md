# Obsidian Infrastructure - API Reference

## Script Interfaces

### tmpl.sh

```bash
# SYNOPSIS
tmpl.sh [-e vars.env] [-o outfile] template.md

# ENVIRONMENT
# Variables referenced in template must be exported

# RETURNS
# 0 - Success
# 1 - Expansion failed
# 2 - Invalid arguments
```

### tmpl_ux.sh

```bash
# SYNOPSIS
tmpl_ux.sh NAME [-T TEMPLATE] [-e file] [--list VAR=items] [VAR=VALUE ...]

# POSITIONAL
NAME    - Target filename (sans .md added if needed)

# OPTIONS
-T TEMPLATE    Template path or name (default: ST-default.md)
-e FILE        Source variables from file
--list VAR=a,b Create YAML list from comma-separated values

# ENVIRONMENT
VAULT_ROOT     - Override vault location (auto-detected from script location)
INBOX_DIR      - Override inbox location (default: $VAULT_ROOT/00-INBOX)
TEMPLATE_DIR   - Override template location (default: $SCRIPT_DIR/../templates)

# RETURNS
# 0 - Success
# 1 - Error (template not found, duplicate file, etc.)
# 2 - Invalid arguments
```

### task.sh

```bash
# SYNOPSIS
task.sh NAME [VAR=VALUE ...]

# POSITIONAL
NAME    - Task name/filename

# BEHAVIOR
# Always uses ST-task.md template
# Equivalent to: tmpl_ux.sh NAME -T ST-task.md [VAR=VALUE ...]

# COMMON VARIABLES
BODY, STATUS, PROJECT, DUE_DATE, DO_DATE, TAGS, PRIORITY

# RETURNS
# 0 - Success
# 1 - Error
```

### stage.sh

```bash
# SYNOPSIS
stage.sh [--dry-run]

# OPTIONS
--dry-run    Preview actions without modifying files

# CONFIGURATION
# Reads: infrastructure/config/staging-workflow.md

# LOGGING
# Writes to: 99-SYSTEM/logs/staging_logs.md

# RETURNS
# 0 - Success (may have processed failures)
# 1 - Fatal error (config missing, jq not found, etc.)
```

---

## Configuration Schema

### staging-workflow.md

```json
{
  "type-string": {
    "destination": "relative/path/from/vault",
    "fields": {
      "fieldname": "",
      "fieldname": "validation_expression"
    }
  }
}
```

| Property | Type | Description |
|----------|------|-------------|
| `type-string` | string | Matches `Type:` in note frontmatter |
| `destination` | string | Relative path from vault root |
| `fields` | object | Field validation rules |
| `fieldname` | string | `""` = required any value, or validation expression |

### Validation Expressions

Shell test expressions evaluated in subshell:

```bash
# Exact match
"[ \"$status\" = \"Active\" ]"

# Multiple options
"[ \"$status\" = \"To Do\" ] || [ \"$status\" = \"Done\" ]"

# Pattern match (POSIX)
"case \"$id\" in 2026*) true ;; *) false ;; esac"

# Numeric comparison
"[ \"$priority\" -ge 1 ] && [ \"$priority\" -le 5 ]"
```

**Variables available in validation:**
- All frontmatter fields as `$fieldname`
- Use lowercase matching field names

---

## Template Variables

### Standard Variables

| Variable | Used In | Purpose |
|----------|---------|---------|
| `BODY` | All | Main note content |
| `TITLE` | All | Note title |
| `PROJECT` | All | Associated project |
| `STATUS` | Tasks | Task status |
| `ID` | All | Unique identifier (timestamp) |

### Task-Specific Variables

| Variable | Purpose |
|----------|---------|
| `DUE_DATE` | When task is due |
| `DO_DATE` | When to start task |
| `PRIORITY` | Priority level |
| `TAGS` | YAML list of tags |
| `RELATED` | Related notes |
| `TOPIC` | Topic/category |

### YAML List Variables

Created with `--list` flag:

```bash
--list "TAGS=tag1,tag2,tag3"
--list "ALIASES=alias1,alias2"
--list "RELATED=note1,note2,note3"
```

---

## Exit Codes Reference

| Code | Scripts | Meaning |
|------|---------|---------|
| 0 | All | Success |
| 1 | tmpl.sh | Expansion failed |
| 1 | tmpl_ux.sh, task.sh | File exists, template not found, or other error |
| 1 | stage.sh | Config missing or dependency error |
| 2 | tmpl.sh, tmpl_ux.sh, task.sh | Invalid arguments |

---

## File Locations

### Required Structure

```
VAULT_ROOT/
├── 00-INBOX/                          # Note creation destination
├── 01-STAGING/                        # stage.sh source
├── 02-REFACTORING/                    # stage.sh failures
├── 03-ZETTELKASTEN/                   # stage.sh success destinations
│   └── (configured subdirectories)
├── 99-SYSTEM/
│   ├── logs/
│   │   └── staging_logs.md           # stage.sh logs
│   └── infrastructure/
│       ├── bin/                      # Scripts
│       │   ├── tmpl.sh
│       │   ├── tmpl_ux.sh
│       │   ├── task.sh
│       │   └── stage.sh
│       ├── config/
│       │   └── staging-workflow.md   # Routing config
│       └── templates/
│           ├── ST-default.md
│           └── ST-task.md
```

### Environment Overrides

| Variable | Scripts | Purpose |
|----------|---------|---------|
| `VAULT_ROOT` | tmpl_ux.sh, task.sh, stage.sh | Override vault location |
| `INBOX_DIR` | tmpl_ux.sh | Override inbox location |
| `TEMPLATE_DIR` | tmpl_ux.sh | Override template location |
| `TMPL_SH` | tmpl_ux.sh, task.sh | Override tmpl.sh path |
| `TUX` | task.sh | Override tmpl_ux.sh path |
| `DEFAULT_TEMPLATE` | tmpl_ux.sh | Override default template |

---

## Error Callout Format

When `stage.sh` fails validation, this callout is injected:

```markdown
> [!WARNING] Staging Failed: {error_message}
```

**Error messages:**
- `Missing mandatory field: id`
- `Missing or empty required field: {fieldname}`
- `Validation snippet failed for {fieldname}: {snippet}`
- `Collision: File already exists at destination {destination}`
- `No Type found in frontmatter`
- `Type '{type}' not defined in workflow config`

---

## Log Format

### staging_logs.md

```
[YYYY-MM-DD HH:MM:SS] [LEVEL] Message
```

**Levels:**
- `[INFO]` - General information
- `[WARN]` - Warnings (validation failures)
- `[ERROR]` - Errors (fatal issues)

**Examples:**
```
[2026-02-20 21:48:39] [INFO] Starting stage.sh execution.
[2026-02-20 21:48:39] [INFO] Processing note.md: [PASS] -> 03-ZETTELKASTEN/Tasks
[2026-02-20 21:48:39] [WARN] Processing note.md: [FAIL] Missing mandatory field: id
```

---

## YAML Frontmatter Format

### Standard Structure

```yaml
---
Type: task
id: YYYYMMDDHHMMSS
status: To Do
project: Project Name
---
```

### Field Requirements

- **Case-sensitive:** Use lowercase field names (`id`, `status`, `topic`)
- **Type:** Must match a key in `staging-workflow.md`
- **id:** Required for all notes (enforced by stage.sh)

### YAML Lists

```yaml
---
tags:
  - tag1
  - tag2
  - tag3
related:
  - "[[Related Note]]"
  - "[[Another Note]]"
---
```

---

## Dependencies

### Required

| Tool | Version | Purpose |
|------|---------|---------|
| `sh` | POSIX compliant | Script execution |
| `jq` | 1.6+ | JSON parsing in stage.sh |

### Optional

| Tool | Purpose |
|------|---------|
| `shellcheck` | Linting scripts |
| `date` | Timestamp generation |

### iOS (a-shell) Notes

- Scripts must be copied to vault directory (not symlinked)
- Ensure `jq` is installed: `pkg install jq`
- File paths are case-sensitive

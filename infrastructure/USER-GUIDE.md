# Obsidian Infrastructure Scripts - User Guide

## Overview

This document describes the shell-based automation system for managing Obsidian vault workflows. The system provides POSIX-compliant scripts that run on both Linux/WSL and iOS (a-shell).

---

## Script Reference

### 1. `tmpl.sh` - Template Expander

**Purpose:** Expands template files with variable substitution using heredoc syntax.

#### Interface

```
tmpl.sh [-e vars.env] [-o outfile] template.md
```

#### Arguments

| Option | Description | Required |
|--------|-------------|----------|
| `template.md` | Path to template file | Yes |
| `-e file` | Source variables from environment file | No |
| `-o file` | Write output to file (default: stdout) | No |
| `-h, --help` | Show help message | No |

#### Environment Variables

Variables can be passed via environment or `-e` file. Use `${VARNAME}` syntax in templates.

**Example vars.env:**
```bash
TITLE="My Note"
PROJECT="Work"
STATUS="Active"
```

#### Template Format

Templates use standard shell variable expansion:

```markdown
---
title: ${TITLE}
project: ${PROJECT}
status: ${STATUS:-To Do}
---

# ${TITLE}

Project: ${PROJECT}
```

**Default values:** Use `${VAR:-default}` syntax for defaults.

#### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Template expansion failed |
| 2 | Invalid arguments |

#### Examples

```bash
# Basic usage with environment variables
TITLE="Meeting Notes" PROJECT="Alpha" tmpl.sh -o output.md template.md

# Using variable file
tmpl.sh -e vars.env -o note.md templates/ST-default.md

# Output to stdout
tmpl.sh template.md > output.md
```

---

### 2. `tmpl_ux.sh` - Template Wrapper (User Experience)

**Purpose:** High-level wrapper for creating notes from templates in the Obsidian vault.

#### Interface

```
tmpl_ux.sh NAME [options] [KEY=VALUE ...]
```

#### Arguments

| Argument | Description | Required |
|----------|-------------|----------|
| `NAME` | Note filename (adds .md if omitted) | Yes |
| `-T TEMPLATE` | Template path or name | No (default: ST-default.md) |
| `-e FILE` | Source extra variables from file | No |
| `--list VAR=a,b` | Create YAML list variable | No |
| `KEY=VALUE` | Set template variables | No |

#### Filename Sanitization

Trailing underscores are automatically stripped from filenames:
- `MyNote_` → `MyNote.md`
- `MyNote___` → `MyNote__.md` (only one underscore stripped)

#### Environment Isolation

Uses `env -i` to prevent variable leakage between invocations. This fixes a bug where variables from one note creation would persist to the next.

#### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Error (template not found, file exists, etc.) |
| 2 | Invalid arguments |

#### Examples

```bash
# Create a basic note
tmpl_ux.sh "Meeting Notes" BODY="Discussion about project"

# Create with custom template
tmpl_ux.sh "Task" -T ST-task.md BODY="Do something" STATUS="To Do"

# Create with tags (YAML list)
tmpl_ux.sh "Project Note" BODY="Content" --list "TAGS=work,urgent,alpha"

# Multiple variables
tmpl_ux.sh "Complex Note" BODY="Text" PROJECT="Alpha" STATUS="Active" PRIORITY="High"

# Using variable file
tmpl_ux.sh "From File" -e myvars.env
```

---

### 3. `task.sh` - Task Note Creator

**Purpose:** Simplified wrapper for creating task notes using `ST-task.md` template.

#### Interface

```
task.sh NAME [KEY=VALUE ...]
```

#### Arguments

| Argument | Description | Required |
|----------|-------------|----------|
| `NAME` | Task name/filename | Yes |
| `KEY=VALUE` | Template variables | No |

#### Default Template

Always uses `ST-task.md` from the templates directory.

#### Common Variables

| Variable | Purpose | Default |
|----------|---------|---------|
| `BODY` | Task description | (empty) |
| `STATUS` | Task status | "To Do" |
| `PROJECT` | Associated project | (empty) |
| `DUE_DATE` | Due date | (empty) |
| `DO_DATE` | Do date | (empty) |
| `TAGS` | YAML list of tags | (empty) |

#### Exit Codes

Same as `tmpl_ux.sh`.

#### Examples

```bash
# Simple task
task.sh "Buy groceries" BODY="Milk, eggs, bread"

# Task with status
task.sh "Review PR" BODY="Check code changes" STATUS="In Progress"

# Task with project and due date
task.sh "Quarterly Report" BODY="Prepare Q1 report" PROJECT="Finance" DUE_DATE="2026-03-31"

# Task with tags
task.sh "Deploy" BODY="Deploy to production" --list "TAGS=devops,critical"
```

---

### 4. `stage.sh` - Staging Automation

**Purpose:** Processes notes from `01-STAGING/` and routes them to appropriate destinations based on configuration.

#### Interface

```
stage.sh [--dry-run]
```

#### Arguments

| Option | Description |
|--------|-------------|
| `--dry-run` | Show planned actions without modifying files |

#### Configuration

Reads routing rules from `infrastructure/config/staging-workflow.md`.

#### Processing Flow

1. Scans `01-STAGING/` for `.md` files
2. Extracts YAML frontmatter from each file
3. Validates required fields per note type
4. Routes valid notes to configured destinations
5. Moves invalid notes to `02-REFACTORING/` with error callouts

#### Validation Rules

- **Mandatory:** All notes must have `id` field
- **Type-specific:** Each type can define required fields and validation snippets

#### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success (processed all files) |
| 1 | Error (config not found, dependency missing, etc.) |

#### Examples

```bash
# Normal execution
./stage.sh

# Preview changes without applying
./stage.sh --dry-run

# From iOS Shortcuts via a-shell
sh infrastructure/bin/stage.sh
```

---

## Configuration Format

### `staging-workflow.md`

Configuration is embedded as JSON within a Markdown file:

```markdown
---
type: configuration
desc: Staging workflow rules
---

# Staging Workflow Configuration

```json
{
  "note-type": {
    "destination": "relative/path/from/vault/root",
    "fields": {
      "fieldname": "",
      "fieldname": "validation_snippet"
    }
  }
}
```
```

#### Field Types

| Field Value | Behavior |
|-------------|----------|
| `""` | Required field, any non-empty value |
| `"validation_snippet"` | Required field, must pass shell validation |

#### Validation Snippets

Shell expressions that evaluate to true/false. Use `$fieldname` to reference the field value:

```json
{
  "status": "[ \"$status\" = \"Active\" ] || [ \"$status\" = \"Inactive\" ]"
}
```

#### Example Configuration

```json
{
  "task": {
    "destination": "03-ZETTELKASTEN/Tasks",
    "fields": {
      "id": "",
      "status": "[ \"$status\" = \"To Do\" ] || [ \"$status\" = \"Done\" ] || [ \"$status\" = \"Canceled\" ]"
    }
  },
  "idea": {
    "destination": "03-ZETTELKASTEN/Ideas",
    "fields": {
      "id": "",
      "topic": ""
    }
  }
}
```

---

## Template Format

### Frontmatter Variables

Templates use standard YAML frontmatter with shell variable expansion:

```markdown
---
id: ${ID:-$(date +%s%3N)}
title: ${TITLE}
project: ${PROJECT}
status: ${STATUS:-To Do}
tags:
${TAGS}
---

${BODY}
```

### YAML Lists

Use `--list` flag to generate YAML list syntax:

```bash
tmpl_ux.sh "Note" --list "TAGS=tag1,tag2,tag3"
```

Results in:
```yaml
tags:
  - tag1
  - tag2
  - tag3
```

### Default Templates

| Template | Purpose |
|----------|---------|
| `ST-default.md` | General purpose notes |
| `ST-task.md` | Task/todo items |

---

## Directory Structure

```
vault/
├── 00-INBOX/              # New notes land here
├── 01-STAGING/            # Notes ready for processing
├── 02-REFACTORING/        # Failed validation notes
├── 03-ZETTELKASTEN/       # Organized notes
│   ├── Ideas/
│   ├── Tasks/
│   └── ...
├── 99-SYSTEM/
│   ├── logs/              # Processing logs
│   └── infrastructure/
│       ├── bin/           # Scripts
│       ├── config/        # Configuration
│       ├── templates/     # Note templates
│       └── tests/         # Test suite
```

---

## Error Handling

### Error Callouts

When validation fails, an Obsidian callout is injected after the frontmatter:

```markdown
---
Type: task
---

> [!WARNING] Staging Failed: Missing mandatory field: id

Note content here...
```

### Log Format

Logs are written to `99-SYSTEM/logs/staging_logs.md`:

```
[2026-02-20 21:48:39] [INFO] Starting stage.sh execution.
[2026-02-20 21:48:39] [INFO] Processing note.md: [PASS] -> 03-ZETTELKASTEN/Tasks
[2026-02-20 21:48:39] [WARN] Processing invalid.md: [FAIL] Missing mandatory field: id
```

---

## Best Practices

### Creating Notes

1. **Use `task.sh` for tasks** - Ensures consistent task structure
2. **Include required fields** - Check `staging-workflow.md` for your note type
3. **Use descriptive names** - Filenames become note titles

### Staging Workflow

1. **Review notes** before moving to `01-STAGING/`
2. **Run `--dry-run` first** to preview changes
3. **Check `02-REFACTORING/`** for failed notes and fix errors
4. **Review logs** for processing history

### Configuration Changes

1. **Test changes** with `--dry-run` first
2. **Validate JSON** syntax before saving
3. **Use lowercase field names** in frontmatter

---

## Troubleshooting

### "jq is not installed"

Install `jq`:
- Linux: `apt-get install jq` or `yum install jq`
- macOS: `brew install jq`
- iOS (a-shell): `pkg install jq`

### "inbox dir not found"

Ensure you're running scripts from the vault root or have set `VAULT_ROOT` environment variable.

### "template not found"

Check that templates exist in `infrastructure/templates/` or provide full path with `-T`.

### Variable leakage between notes

This was a bug that's now fixed. Ensure you're using the latest `tmpl_ux.sh` which uses `env -i`.

---

## POSIX Compliance

All scripts are POSIX-compliant (`sh`) for cross-platform compatibility:

- Works on Linux (bash, dash)
- Works on iOS (a-shell)
- No bash-specific features (`[[ ]]`, arrays, `local`)
- No GNU-specific tools (`sed -i`)

---

## See Also

- `infrastructure/tests/` - Test suite demonstrating usage
- `docs/` - Additional documentation
- `staging-workflow.md` - Current routing configuration

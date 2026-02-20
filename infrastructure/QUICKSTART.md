# Quick Start Guide

## Installation

### 1. Copy Scripts to Vault

Copy the `infrastructure/` directory to your Obsidian vault:

```bash
cp -r infrastructure/ /path/to/your/vault/
```

### 2. Create Directory Structure

Ensure these directories exist:

```bash
mkdir -p 00-INBOX 01-STAGING 02-REFACTORING 03-ZETTELKASTEN
mkdir -p 99-SYSTEM/logs
```

### 3. Install Dependencies

**Linux/WSL:**
```bash
sudo apt-get install jq    # Debian/Ubuntu
sudo yum install jq        # RHEL/CentOS
```

**macOS:**
```bash
brew install jq
```

**iOS (a-shell):**
```bash
pkg install jq
```

### 4. Make Scripts Executable

```bash
chmod +x infrastructure/bin/*.sh
```

---

## Your First Note

### Create a Task

```bash
./infrastructure/bin/task.sh "My First Task" BODY="Learn the system"
```

Check `00-INBOX/` - you'll find `My First Task.md`.

### Create a Custom Note

```bash
./infrastructure/bin/tmpl_ux.sh "Project Ideas" BODY="Brainstorm here" PROJECT="Personal"
```

---

## Staging Workflow

### 1. Move to Staging

In Obsidian or file manager, move your note from `00-INBOX/` to `01-STAGING/`.

### 2. Run Staging

```bash
./infrastructure/bin/stage.sh --dry-run
```

Preview what will happen.

### 3. Execute

```bash
./infrastructure/bin/stage.sh
```

### 4. Check Results

- Valid notes → `03-ZETTELKASTEN/`
- Invalid notes → `02-REFACTORING/` (with error messages)

---

## Common Workflows

### Daily Capture (iOS)

1. Create note via Shortcut → lands in `00-INBOX/`
2. Review and move to `01-STAGING/`
3. Run `stage.sh` from terminal

### Task Management

```bash
# Create tasks
task.sh "Email team" BODY="Send weekly update" DUE_DATE="2026-02-25"
task.sh "Review docs" BODY="Check PR documentation"

# Process them
stage.sh
```

### Custom Note Types

Edit `infrastructure/config/staging-workflow.md`:

```json
{
  "meeting": {
    "destination": "03-ZETTELKASTEN/Meetings",
    "fields": {
      "id": "",
      "attendees": ""
    }
  }
}
```

Then create notes:

```bash
tmpl_ux.sh "Sprint Review" -T ST-meeting.md BODY="Notes..." ATTENDEES="Team"
```

---

## Troubleshooting

### "jq not found"

Install jq (see Installation above).

### "inbox dir not found"

Run scripts from vault root, or set:

```bash
export VAULT_ROOT=/path/to/vault
```

### Notes not routing

Check that:
1. Note has `Type:` field matching config
2. Note has `id:` field
3. Config JSON is valid

### Permission denied

```bash
chmod +x infrastructure/bin/*.sh
```

---

## Next Steps

- Read [USER-GUIDE.md](USER-GUIDE.md) for detailed usage
- Read [API-REFERENCE.md](API-REFERENCE.md) for scripting
- Check `infrastructure/tests/` for examples
- Customize templates in `infrastructure/templates/`

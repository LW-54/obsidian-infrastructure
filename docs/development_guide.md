# Development Guide

**Analysis Date:** 2026-02-20
**Scan Level:** Deep

## Prerequisites

- **Environment:** POSIX-compliant Shell (sh/bash)
- **Target Platform:** iOS (via a-shell) or Linux/macOS
- **Tools:** Standard Coreutils (`grep`, `sed`, `cat`, `mkdir`, `rm`)

## Installation

1. Clone or copy the `current_infrastructure` folder to your vault or script directory.
2. Ensure scripts are executable:
   ```bash
   chmod +x current_infrastructure/scripts/*.sh
   ```

## Usage

### Creating a Task

Run the `task.sh` wrapper:

```bash
./current_infrastructure/scripts/task.sh "My Task Name" BODY="Task details here"
```

### Using the Template Engine

Run `tmpl_ux.sh` directly:

```bash
./current_infrastructure/scripts/tmpl_ux.sh "Note Name" -T "TemplateName.md" KEY=VALUE
```

## Testing

Run the test suite located in the `tests/` directory:

```bash
# Run all tests
for t in tests/test-*.sh; do sh "$t"; done
```

## Debugging

- **Underscore Issues:** Check your input variable `NAME`. Ensure it doesn't have trailing spaces or underscores.
- **Persistence Issues:** If running in a loop (e.g., a-shell), manually unset variables like `BODY` before the next call: `unset BODY`.

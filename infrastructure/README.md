# Obsidian Infrastructure

POSIX-compliant shell automation for Obsidian vault workflows.

## Overview

This infrastructure provides cross-platform shell scripts for managing Obsidian notes across Linux/WSL and iOS (a-shell).

## Features

- **Template-based note creation** with variable substitution
- **Automated staging workflow** for organizing notes
- **Validation and error handling** with Obsidian-compatible callouts
- **Cross-platform compatibility** (POSIX sh, runs on Linux and iOS)
- **Configurable routing** via JSON-in-Markdown

## Documentation

| Document | Purpose |
|----------|---------|
| [QUICKSTART.md](QUICKSTART.md) | Get up and running in 5 minutes |
| [USER-GUIDE.md](USER-GUIDE.md) | Comprehensive usage guide |
| [API-REFERENCE.md](API-REFERENCE.md) | Script interfaces and configuration |

## Scripts

| Script | Purpose |
|--------|---------|
| `bin/tmpl.sh` | Template expander with variable substitution |
| `bin/tmpl_ux.sh` | User-friendly note creation wrapper |
| `bin/task.sh` | Task note creator |
| `bin/stage.sh` | Automated staging and routing |
| `bin/generate_test_data.sh` | Test data generator |

## Quick Example

```bash
# Create a task
task.sh "Review PR" BODY="Check code changes" STATUS="To Do"

# Stage notes
stage.sh
```

## Directory Structure

```
infrastructure/
├── bin/              # Executable scripts
├── config/           # Configuration files
├── templates/        # Note templates
├── tests/            # Test suite
├── USER-GUIDE.md     # Usage documentation
├── API-REFERENCE.md  # API documentation
└── QUICKSTART.md     # Quick start guide
```

## Requirements

- POSIX-compliant shell (`sh`)
- `jq` (1.6+) for JSON processing
- Obsidian vault with standard folder structure

## Installation

See [QUICKSTART.md](QUICKSTART.md) for installation instructions.

## Testing

Run the test suite:

```bash
for test in tests/test-*.sh; do sh "$test"; done
```

All tests should pass before deployment.

## License

Personal use - customize for your workflow.

## Contributing

This is a personal infrastructure. Adapt it to your needs!

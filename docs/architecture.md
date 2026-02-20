# Architecture Documentation

**Analysis Date:** 2026-02-20
**Scan Level:** Deep

## Overview

The Obsidian Infrastructure project provides a set of shell scripts to automate note and task creation within an Obsidian vault. It is designed to be lightweight, POSIX-compliant, and compatible with mobile environments like a-shell (iOS).

## Core Components

### 1. Template Engine (`tmpl.sh`)
- **Responsibility:** Variable substitution in markdown templates.
- **Mechanism:** Uses `heredoc` expansion in a subshell to safely replace `${VAR}` placeholders with environment values.
- **Input:** Markdown template file + Environment variables.
- **Output:** Processed markdown file.

### 2. User Wrapper (`tmpl_ux.sh`)
- **Responsibility:** High-level command-line interface for creating notes.
- **Features:**
  - Argument parsing (`-T`, `-e`, `KEY=VALUE`).
  - Filename handling (adds `.md` extension).
  - Variable file generation (converts CLI args to env vars).
  - Safety checks (prevents overwriting existing files).

### 3. Task Wrapper (`task.sh`)
- **Responsibility:** Simplified command for creating tasks.
- **Mechanism:** Presets the template to `ST-task.md` and calls `tmpl_ux.sh`.

### 4. Configuration (`staging-workflow.md`)
- **Responsibility:** Maps content types (e.g., `media/book`) to folder paths (e.g., `Media/Books`).
- **Status:** Currently exists as a static config file. Usage logic (router) appears to be external (e.g., iOS Shortcut logic) or missing from the scanned scripts.

## Data Flow

1. **User/Shortcut** invokes `task.sh "My Task"`.
2. `task.sh` calls `tmpl_ux.sh` with `ST-task.md`.
3. `tmpl_ux.sh`:
   - Parses arguments.
   - Creates a temporary variables file from inputs.
   - Determines output path (`00-INBOX/My Task.md`).
   - Calls `tmpl.sh`.
4. `tmpl.sh`:
   - Reads `ST-task.md`.
   - Substitutes `${BODY}`, `${STATUS}`, etc.
   - Writes final content to the output file.

## Integration Points

- **iOS Shortcuts / a-shell:** The primary consumer of these scripts.
- **Obsidian Vault:** The target storage for generated files.

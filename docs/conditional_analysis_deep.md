# Conditional Scan Findings

**Analysis Date:** 2026-02-20
**Scan Level:** Deep

## Findings Summary

### 1. Configuration (`type_to_folder.md`)
- **Format:** Simple Key-Value pairs (`type: folder/path`).
- **Usage:** Not explicitly referenced in scanned scripts (`tmpl.sh`, `task.sh`, `tmpl_ux.sh`). Likely used by external caller (iOS Shortcut) or missing logic.
- **Goal:** Update to "new format" (Need user clarification on what this format is, or infer from context).

### 2. Script Logic Analysis
- **`tmpl.sh` (Template Engine):**
  - Uses `set -a` to export variables from file.
  - Inherits environment variables from parent shell.
  - Vulnerable to persistent environment variables if running in a loop within the same shell session (e.g., a-shell).

- **`tmpl_ux.sh` (User Wrapper):**
  - Handles argument parsing and constructs variable files.
  - Does NOT explicitly clear common variables (like `BODY`) before calling `tmpl.sh`.
  - Ignores unknown arguments silently (potential for misuse).

- **`task.sh` (Convenience Wrapper):**
  - Simple wrapper around `tmpl_ux.sh`.

### 3. Bug Hypotheses

#### A. Underscore Bug (`filename_`)
- **Observation:** `tmpl_ux.sh` appends `.md` if missing, but doesn't modify the name itself unless it ends with `.md`.
- **Root Cause:** Likely the *caller* (iOS Shortcut) is passing a name with a trailing underscore or a variable that expands to `name_` (e.g., `${NAME}_${SUFFIX}` where suffix is empty).
- **Fix:** In `tmpl_ux.sh`, sanitize the input name (strip trailing/leading underscores/spaces).

#### B. Persistent Content Bug (`BODY` reuse)
- **Observation:** `ST-task.md` uses `${BODY:-}`.
- **Root Cause:** In a persistent shell environment (like a-shell loops), if `export BODY="content"` happens once, it remains set for subsequent calls unless explicitly unset.
- **Fix:** Update `tmpl_ux.sh` to explicitly unset common variables (BODY, TAGS, etc.) at the start, OR scope the execution more strictly.

## Recommendations
1. **Sanitize Inputs:** Modify `tmpl_ux.sh` to clean up filenames.
2. **Isolate Environment:** Modify `tmpl_ux.sh` or `tmpl.sh` to unset specific variables or run in a cleaner environment.
3. **Update Config:** Clarify the "new format" for `type_to_folder.md` and implement a parser for it.

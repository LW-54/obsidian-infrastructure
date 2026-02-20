# Infrastructure Enhancement Plan

**Author:** Mary (Analyst)
**Date:** 2026-02-20
**Status:** Draft

## Executive Summary
The Obsidian Infrastructure requires updates to improve reliability, fix persistent bugs, and align with the new `stage.sh` workflow. This plan outlines the necessary changes to the legacy scripts and configuration.

## Problem Statement
1.  **Underscore Bug:** Files created via iOS Shortcuts sometimes have a trailing underscore (e.g., `Note_.md`).
2.  **Persistent Content:** Task body content persists across executions in stateful environments (e.g., a-shell loops).
3.  **Legacy Configuration:** The project uses a legacy `type_to_folder.md` (key-value) format, but the new `stage.sh` requires a JSON-embedded `staging-workflow.md`.

## Proposed Solution

### 1. Script Updates
- **`tmpl_ux.sh`**:
    -   **Sanitization:** Add logic to strip trailing underscores from the `NAME` argument.
    -   **Isolation:** Explicitly `unset` common variables (`BODY`, `TAGS`, etc.) at the start of execution to prevent leakage from the parent shell.
- **`stage.sh`**:
    -   Ensure it is located in `current_infrastructure/scripts/`.
    -   Verify it correctly reads the new configuration format.

### 2. Configuration Migration
-   **Convert** `type_to_folder.md` to `staging-workflow.md`.
-   **Format:** Embed the configuration as a JSON block within a Markdown file (as required by `stage.sh`).
-   **Location:** `current_infrastructure/staging-workflow.md`.

### 3. Testing Strategy
-   **New Tests:** Create/Update tests to verify:
    -   Underscore removal.
    -   Variable isolation.
    -   JSON config parsing.
-   **Location:** Ensure all tests in `tests/` point to the correct script locations in `current_infrastructure/scripts/`.

## Implementation Steps (For Developer)
1.  [ ] Modify `tmpl_ux.sh` to fix bugs.
2.  [ ] Generate `staging-workflow.md` from legacy config.
3.  [ ] Move `stage.sh` to infrastructure folder.
4.  [ ] Update test suites.
5.  [ ] Verify all tests pass.

## Outcome
These changes will result in a robust, stateless, and fully automated staging workflow compatible with iOS and Linux.

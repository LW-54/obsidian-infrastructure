# Implementation Brief: Obsidian Infrastructure Refactor

**Status:** Ready for Development
**Source Material:** `_bmad-output/planning-artifacts/prd.md`, `current_infrastructure/`, `docs/conditional_analysis_deep.md`

## 1. Project Goal
Refactor the existing Obsidian infrastructure scripts to be robust, stateless, and consistently organized. This involves fixing specific bugs in the legacy scripts, migrating the configuration to a JSON-based format, and reorganizing the directory structure.

## 2. Directory Restructuring
**Current State:** Flat structure in `current_infrastructure/` with loose `tests/` and `scripts/`.
**Target State:**
```text
infrastructure/
├── bin/                # Executable scripts (was scripts/)
│   ├── tmpl.sh
│   ├── tmpl_ux.sh
│   ├── task.sh
│   ├── stage.sh
│   └── generate_test_data.sh
├── config/             # Configuration files
│   └── staging-workflow.md  # (New JSON format)
├── templates/          # Markdown templates (was script_templates/)
│   ├── ST-default.md
│   └── ST-task.md
└── tests/              # Integration tests
    ├── test-1.1-infrastructure.sh
    └── ...
```

## 3. Configuration Migration (Crucial)
**Requirement:** The legacy `type_to_folder.md` file MUST be retired. Its data (mappings) must be migrated to the **new JSON format** defined in the PRD and expected by `stage.sh`.

- **Input:** `type_to_folder.md` (Format: `key: value`)
- **Output:** `config/staging-workflow.md` (Format: Embedded JSON in Markdown)
- **Transformation Logic:**
  For each line `Type: Folder`:
  ```json
  "Type": {
    "destination": "Folder",
    "fields": { "ID": "" }  // Default field requirement
  }
  ```

## 4. Script Hardening & Bug Fixes

### A. Persistent Content Bug (Priority: High)
- **Issue:** Environment variables (BODY, TAGS) leak into `tmpl.sh` when running in stateful shells (like a-shell loops).
- **Fix:** In `bin/tmpl_ux.sh`, modify the execution of `tmpl.sh` to use `env -i` (empty environment).
- **Implementation:**
  ```bash
  # Execute in clean environment, passing only essential vars + constructed vars file
  exec env -i PATH="$PATH" HOME="$HOME" TMPDIR="$TMPDIR" \
       sh "$TMPL_SH" ${VARS_TO_PASS:+-e "$VARS_TO_PASS"} -o "$OUTFILE" "$TEMPLATE_FILE"
  ```

### B. Underscore Bug (Priority: Medium)
- **Issue:** Filenames sometimes have trailing underscores (e.g., `Note_.md`), likely from upstream iOS Shortcut logic.
- **Fix:** In `bin/tmpl_ux.sh`, add defensive sanitization.
- **Implementation:**
  ```bash
  NAME="${NAME%_}" # Strip trailing underscore
  ```

## 5. Script & Test Updates
- **Path Updates:** All scripts (`task.sh`, `stage.sh`, tests) currently rely on relative paths (e.g., `../script_templates`). These MUST be updated to reflect the new structure (`../templates`, `../config`).
- **Verification:** Run the full test suite (`tests/*.sh`) after restructuring to ensure no regressions.

## 6. Deliverables
1.  Refactored `infrastructure/` folder.
2.  `config/staging-workflow.md` containing all mappings from `type_to_folder.md`.
3.  Updated `bin/tmpl_ux.sh` with `env -i` and underscore fix.
4.  Passing test suite.

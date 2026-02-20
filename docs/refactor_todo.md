# Refactor Todo List: Obsidian Infrastructure

**Status:** Pending
**Source:** `docs/implementation_brief.md`

## Phase 1: Setup & Migration (Critical)

- [ ] **1.1 Create Directory Structure**
  - Create `infrastructure/bin`
  - Create `infrastructure/config`
  - Create `infrastructure/templates`
  - Create `infrastructure/tests`
  - *Note: Do not delete old directories yet.*

- [ ] **1.2 Verify & Move Configuration**
  - *Note:* `type_to_folder.md` is already deleted and `staging-workflow.md` exists in `current_infrastructure/`.
  - Move `current_infrastructure/staging-workflow.md` -> `infrastructure/config/staging-workflow.md`.
  - Verify the content is valid JSON-in-Markdown.

## Phase 2: Restructuring & Code Movement

- [ ] **2.1 Move & Rename Scripts**
  - Move `current_infrastructure/scripts/tmpl.sh` -> `infrastructure/bin/tmpl.sh`
  - Move `current_infrastructure/scripts/tmpl_ux.sh` -> `infrastructure/bin/tmpl_ux.sh`
  - Move `current_infrastructure/scripts/task.sh` -> `infrastructure/bin/task.sh`
  - Move `current_infrastructure/scripts/stage.sh` -> `infrastructure/bin/stage.sh`
  - Move `current_infrastructure/scripts/generate_test_data.sh` -> `infrastructure/bin/generate_test_data.sh`
  - Ensure all are executable (`chmod +x`).

- [ ] **2.2 Move Templates**
  - Move `current_infrastructure/script_templates/ST-default.md` -> `infrastructure/templates/ST-default.md`
  - Move `current_infrastructure/script_templates/ST-task.md` -> `infrastructure/templates/ST-task.md`

- [ ] **2.3 Move Tests**
  - Move `current_infrastructure/tests/*` -> `infrastructure/tests/`
  - Move `tests/*` (from root) -> `infrastructure/tests/` (Consolidate all tests)

## Phase 3: Code Updates & Fixes

- [ ] **3.1 Update Paths in Scripts**
  - Update `infrastructure/bin/task.sh`: Point to `../templates` instead of `../script_templates`.
  - Update `infrastructure/bin/stage.sh`: Point to `../config/staging-workflow.md` instead of `type_to_folder.md`.
  - Update `infrastructure/bin/generate_test_data.sh`: Fix any relative paths.
  - Update `infrastructure/tests/*.sh`: Fix paths to SUT (System Under Test).

- [ ] **3.2 Fix Persistent Content Bug (Priority: High)**
  - Edit `infrastructure/bin/tmpl_ux.sh`.
  - Implement `exec env -i ...` logic as defined in the Brief (Section 4.A).

- [ ] **3.3 Fix Underscore Bug (Priority: Medium)**
  - Edit `infrastructure/bin/tmpl_ux.sh`.
  - Add `NAME="${NAME%_}"` sanitization (Section 4.B).

## Phase 4: Verification & Cleanup

- [ ] **4.1 Run Tests**
  - Execute `infrastructure/tests/test-1.1-infrastructure.sh` (and others).
  - Verify green status.

- [ ] **4.2 Cleanup**
  - Remove `current_infrastructure/` directory once everything is verified.

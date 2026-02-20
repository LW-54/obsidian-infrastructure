---
stepsCompleted:
  - step-01-validate-prerequisites
  - step-02-design-epics
  - step-03-create-stories
  - step-04-final-validation
workflowStatus: complete
inputDocuments:
  - _bmad-output/planning-artifacts/prd.md
  - _bmad-output/planning-artifacts/architecture.md
  - _bmad-output/planning-artifacts/brownfield-architecture.md
---

# obsidian-scripts - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for obsidian-scripts, decomposing the requirements from the PRD, UX Design if it exists, and Architecture requirements into implementable stories.

## Requirements Inventory

### Functional Requirements

**FR1:** System maintains executable scripts in `infrastructure/bin/` directory
**FR2:** System maintains configuration files in `infrastructure/config/` directory
**FR3:** System maintains templates in `infrastructure/templates/` directory
**FR4:** System maintains test files in `infrastructure/tests/` directory
**FR5:** Scripts execute from `infrastructure/bin/` with relative paths to sibling directories

**FR6:** System reads routing configuration from `infrastructure/config/staging-workflow.md`
**FR7:** System parses JSON configuration embedded within Markdown files
**FR8:** System supports configurable note type definitions with destination folders
**FR9:** System supports configurable field validation rules per note type
**FR10:** Configuration changes take effect on next script execution (stateless reload)

**FR11:** System processes all files in `01-STAGING/` directory
**FR12:** System extracts YAML frontmatter from Markdown files
**FR13:** System routes validated notes to configured destinations in `03-ZETTELKASTEN/`
**FR14:** System supports nested folder destinations (e.g., `Media/Books/Tomes/`)
**FR15:** System treats filename collisions as validation failures

**FR16:** System validates presence of required fields per note type configuration
**FR17:** System validates presence of "Type" field in note frontmatter
**FR18:** System validates field values using configurable shell snippet rules
**FR19:** System moves invalid notes to `02-REFACTORING/` directory
**FR20:** System injects error callouts into invalid notes immediately after YAML frontmatter
**FR21:** System preserves original note content except for injected error callouts

**FR22:** System executes on Linux/WSL using POSIX `sh`
**FR23:** System executes on iOS `a-shell` using POSIX `sh`
**FR24:** System avoids GNU-specific shell features (e.g., `sed -i`, `[[ ]]`, arrays)
**FR25:** System handles filenames with spaces correctly
**FR26:** System isolates script environment to prevent variable leakage between invocations

**FR27:** System includes test suite executable via `infrastructure/tests/*.sh`
**FR28:** System supports dry-run mode showing intended actions without file modifications
**FR29:** System generates test data for validation of staging workflows
**FR30:** System exits with non-zero status on failure for script chaining

### Non-Functional Requirements

**Performance:**
- **NFR-P1:** Script execution completes within 2 seconds for batches of 10 notes on iPhone (a-shell environment)
- **NFR-P2:** Template generation completes within 500ms for single note creation
- **NFR-P3:** Configuration loading overhead is negligible (<100ms) for typical config sizes

**Reliability:**
- **NFR-R1:** Scripts produce identical results on Linux `sh` and iOS `a-shell` for identical inputs
- **NFR-R2:** Failed script execution leaves filesystem in consistent state (no partial file moves)
- **NFR-R3:** Test suite passes 100% of runs on both target platforms

**Maintainability:**
- **NFR-M1:** All scripts pass shellcheck linting with zero warnings
- **NFR-M2:** New note types can be added via configuration change only (no script modification)
- **NFR-M3:** All functions include inline comments explaining complex logic (e.g., `sed`, `jq` operations)

**Integration:**
- **NFR-I1:** Scripts function correctly with Obsidian's file watching (atomic moves where possible)
- **NFR-I2:** Configuration file format is valid Markdown that renders correctly in Obsidian
- **NFR-I3:** Scripts exit with standard codes (0=success, 1=general error, 2=validation failure) for iOS Shortcuts integration

### Additional Requirements

**From Architecture:**
- Starter template/greenfield: Not specified—this is a brownfield refactor
- Tech stack: POSIX `sh`, `jq` 1.6+, `sed`/`awk` (POSIX compliant)
- Data storage: Markdown files in Obsidian vault
- Coding standards: Modern POSIX sh style, 2-space indentation, mandatory variable quoting
- Testing: Custom test suite with mock environment, dry-run verification
- Security: Path sanitization to prevent escaping vault root, snippet validation warnings
- Deployment: Manual execution via terminal/a-shell

**From UX:**
- Not applicable—CLI tool with no UI

### FR Coverage Map

| FR | Epic | Description |
|:---:|:---:|:---|
| FR1-5 | 1 | Directory structure and organization |
| FR6-10 | 2 | Configuration management (JSON-in-Markdown) |
| FR11-15 | 3 | Note processing and routing |
| FR16-21 | 3 | Validation and error handling |
| FR22-26 | 4 | Cross-platform execution and bug fixes |
| FR27-30 | 5 | Testing and quality assurance |

## Epic List

### Epic 1: Infrastructure Foundation
**Goal:** Establish the directory structure and script organization that enables reliable cross-platform execution.

**FRs covered:** FR1, FR2, FR3, FR4, FR5
- Create `infrastructure/` directory structure (`bin/`, `config/`, `templates/`, `tests/`)
- Move existing scripts with updated relative paths
- Ensure scripts can execute from `infrastructure/bin/` using sibling directory references

**User Value:** The system has a clean, organized structure that's maintainable and testable.

### Epic 2: Configuration System
**Goal:** Implement JSON-in-Markdown configuration that defines note type routing and validation rules.

**FRs covered:** FR6, FR7, FR8, FR9, FR10
- Create `config/staging-workflow.md` with embedded JSON
- Migrate mappings from legacy `type_to_folder.md`
- Support configurable note type definitions and field validation rules

**User Value:** Users can define routing rules directly in Obsidian via editable Markdown files.

### Epic 3: Core Staging Engine
**Goal:** Build the note processing pipeline that validates, routes, and moves notes based on configuration.

**FRs covered:** FR11, FR12, FR13, FR14, FR15, FR16, FR17, FR18, FR19, FR20, FR21
- Process files from `01-STAGING/` directory
- Extract YAML frontmatter and validate required fields
- Route valid notes to `03-ZETTELKASTEN/` destinations
- Move invalid notes to `02-REFACTORING/` with error callout injection

**User Value:** Notes automatically move to correct folders with clear error feedback when validation fails.

### Epic 4: Cross-Platform Reliability
**Goal:** Ensure scripts run identically on Linux/WSL and iOS (a-shell) without modification.

**FRs covered:** FR22, FR23, FR24, FR25, FR26
- Fix persistent content bug via `env -i` environment isolation
- Implement underscore sanitization (`NAME="${NAME%_}"`)
- Ensure POSIX compliance (no bashisms, GNU-specific features)
- Handle filenames with spaces correctly

**User Value:** Same scripts work reliably on both desktop and mobile without workarounds.

### Epic 5: Testing & Validation Framework
**Goal:** Provide automated testing and dry-run capabilities for confident deployment.

**FRs covered:** FR27, FR28, FR29, FR30
- Create test suite in `infrastructure/tests/`
- Implement dry-run mode showing intended actions
- Generate test data for validation workflows
- Proper exit codes for script chaining

**User Value:** Changes can be validated before affecting live data; regressions are caught automatically.


## Epic 1: Infrastructure Foundation

**Goal:** Establish the directory structure and script organization that enables reliable cross-platform execution.

### Story 1.1: Create Directory Structure

**As a** developer,  
**I want** the infrastructure directory structure to be created with standardized paths,  
**So that** scripts, config, templates, and tests have clear, organized locations.

**Acceptance Criteria:**

**Given** the refactor is starting from the existing codebase,  
**When** I run the setup script or manual initialization,  
**Then** the following directories are created:
- `infrastructure/bin/`
- `infrastructure/config/`
- `infrastructure/templates/`
- `infrastructure/tests/`  
**And** the directory structure matches the planned architecture.

### Story 1.2: Migrate Existing Scripts

**As a** developer,  
**I want** existing scripts moved to the new `infrastructure/bin/` directory with updated paths,  
**So that** they execute correctly from their new location.

**Acceptance Criteria:**

**Given** existing scripts (`tmpl.sh`, `tmpl_ux.sh`, `task.sh`, etc.) in `current_infrastructure/`,  
**When** I migrate them to `infrastructure/bin/`,  
**Then** all relative path references are updated to work from the new location  
**And** scripts can locate their sibling directories (`../config/`, `../templates/`, `../tests/`)  
**And** no hardcoded absolute paths remain.

### Story 1.3: Update Script Templates

**As a** developer,  
**I want** template scripts (`tmpl.sh`, `tmpl_ux.sh`) updated to use the new infrastructure paths,  
**So that** note creation continues to work after migration.

**Acceptance Criteria:**

**Given** template generation scripts need to reference templates in the new location,  
**When** I execute `tmpl.sh` or `tmpl_ux.sh`,  
**Then** they find templates in `infrastructure/templates/`  
**And** created notes land in the correct inbox location  
**And** the scripts remain POSIX compliant.

---

## Epic 2: Configuration System

**Goal:** Implement JSON-in-Markdown configuration that defines note type routing and validation rules.

### Story 2.1: Create Configuration File Format

**As a** developer,  
**I want** a `staging-workflow.md` configuration file with embedded JSON,  
**So that** routing rules are human-readable in Obsidian and machine-parseable by scripts.

**Acceptance Criteria:**

**Given** the need for editable configuration in Obsidian,  
**When** I create `infrastructure/config/staging-workflow.md`,  
**Then** it contains valid Markdown with embedded JSON code block  
**And** the JSON defines note types with destination folders and validation rules  
**And** the file renders correctly in Obsidian preview mode.

### Story 2.2: Migrate Type-to-Folder Mappings

**As a** developer,  
**I want** existing mappings from `type_to_folder.md` migrated to the new JSON format,  
**So that** all existing note types continue to route correctly.

**Acceptance Criteria:**

**Given** legacy `type_to_folder.md` with existing mappings,  
**When** I migrate the configuration,  
**Then** all existing note types are preserved in the new format  
**And** destination paths are correctly converted  
**And** the old configuration file is deprecated but kept as backup.

### Story 2.3: Implement Configuration Parser

**As a** developer,  
**I want** a utility function to parse JSON configuration from Markdown files,  
**So that** scripts can load routing rules at runtime.

**Acceptance Criteria:**

**Given** a `staging-workflow.md` file with embedded JSON,  
**When** the configuration parser runs,  
**Then** it extracts the JSON block from Markdown  
**And** validates the JSON structure  
**And** returns the configuration to the calling script  
**And** errors are reported clearly if parsing fails.

---

## Epic 3: Core Staging Engine

**Goal:** Build the note processing pipeline that validates, routes, and moves notes based on configuration.

### Story 3.1: Process Staging Directory

**As a** user,  
**I want** `stage.sh` to process all files in `01-STAGING/`,  
**So that** notes are validated and moved according to configuration.

**Acceptance Criteria:**

**Given** files exist in `01-STAGING/` directory,  
**When** I execute `stage.sh`,  
**Then** all Markdown files are processed  
**And** YAML frontmatter is extracted from each file  
**And** the "Type" field is used to determine routing.

### Story 3.2: Validate Note Frontmatter

**As a** user,  
**I want** notes to be validated against configured rules,  
**So that** incomplete or malformed notes are flagged for correction.

**Acceptance Criteria:**

**Given** a note with YAML frontmatter,  
**When** validation runs,  
**Then** required fields are checked per note type configuration  
**And** field values are validated using configurable shell snippets  
**And** missing "Type" field causes validation failure  
**And** validation results determine routing destination.

### Story 3.3: Route Valid Notes

**As a** user,  
**I want** valid notes moved to their configured destinations in `03-ZETTELKASTEN/`,  
**So that** notes are organized automatically.

**Acceptance Criteria:**

**Given** a note passes validation,  
**When** routing occurs,  
**Then** the note is moved to the destination folder defined in configuration  
**And** nested folder destinations are created if needed  
**And** filename collisions are treated as validation failures.

### Story 3.4: Handle Validation Failures

**As a** user,  
**I want** invalid notes moved to `02-REFACTORING/` with error callouts,  
**So that** I can see what needs fixing directly in Obsidian.

**Acceptance Criteria:**

**Given** a note fails validation,  
**When** the error handling process runs,  
**Then** the note is moved to `02-REFACTORING/`  
**And** an error callout is injected immediately after YAML frontmatter  
**And** the callout specifies which validation failed  
**And** original note content is preserved except for the callout.

### Story 3.5: Implement Dry-Run Mode

**As a** user,  
**I want** a dry-run mode that shows intended actions without modifying files,  
**So that** I can preview staging results before committing.

**Acceptance Criteria:**

**Given** I run `stage.sh --dry-run`,  
**When** processing completes,  
**Then** no files are moved or modified  
**And** the script outputs a summary of planned actions  
**And** each planned move lists source and destination paths  
**And** validation failures are listed with reasons.

---

## Epic 4: Cross-Platform Reliability

**Goal:** Ensure scripts run identically on Linux/WSL and iOS (a-shell) without modification.

### Story 4.1: Fix Environment Variable Leakage

**As a** user,  
**I want** the persistent content bug fixed via `env -i` environment isolation,  
**So that** template variables don't leak between script invocations.

**Acceptance Criteria:**

**Given** the known bug where environment variables persist between runs,  
**When** template scripts execute,  
**Then** they use `env -i` to start with a clean environment  
**And** only required variables are passed explicitly  
**And** running templates consecutively produces correct, isolated results  
**And** the fix works on both Linux and iOS a-shell.

### Story 4.2: Implement Underscore Sanitization

**As a** user,  
**I want** trailing underscores stripped from filenames,  
**So that** note names don't end with unwanted punctuation.

**Acceptance Criteria:**

**Given** a filename with trailing underscores (e.g., "My_Note__"),  
**When** the filename is processed,  
**Then** trailing underscores are removed using `NAME="${NAME%_}"` pattern  
**And** the sanitized name is used for file operations  
**And** the fix is applied consistently across all scripts.

### Story 4.3: Ensure POSIX Compliance

**As a** user,  
**I want** all scripts to be strictly POSIX compliant,  
**So that** they run on iOS a-shell without bash-specific features.

**Acceptance Criteria:**

**Given** scripts must run on POSIX `sh`,  
**When** scripts are reviewed and tested,  
**Then** no bashisms are present (no `[[ ]]`, no `local`, no arrays)  
**And** GNU-specific `sed` features are avoided (no `sed -i`)  
**And** all scripts pass shellcheck with zero warnings  
**And** scripts execute correctly on both Linux `sh` and iOS `a-shell`.

### Story 4.4: Handle Special Characters in Filenames

**As a** user,  
**I want** filenames with spaces and special characters handled correctly,  
**So that** note titles aren't restricted.

**Acceptance Criteria:**

**Given** filenames containing spaces, quotes, or other special characters,  
**When** scripts process these files,  
**Then** variables are properly quoted throughout  
**And** file operations succeed without errors  
**And** no data loss occurs due to word splitting or globbing.

---

## Epic 5: Testing & Validation Framework

**Goal:** Provide automated testing and dry-run capabilities for confident deployment.

### Story 5.1: Create Test Suite Structure

**As a** developer,  
**I want** a test suite in `infrastructure/tests/`,  
**So that** automated validation can run against the scripts.

**Acceptance Criteria:**

**Given** the need for automated testing,  
**When** I examine `infrastructure/tests/`,  
**Then** test scripts follow a consistent naming pattern (`test-*.sh`)  
**And** a test runner script executes all tests  
**And** tests can be run individually or as a suite  
**And** test results are clearly reported (pass/fail with details).

### Story 5.2: Implement Infrastructure Tests

**As a** developer,  
**I want** tests that verify directory structure and script functionality,  
**So that** the foundation is validated before deployment.

**Acceptance Criteria:**

**Given** the infrastructure has been set up,  
**When** `test-1.1-infrastructure.sh` runs,  
**Then** it verifies all required directories exist  
**And** it checks scripts are executable  
**And** it validates relative path resolution works  
**And** all tests pass on both Linux and iOS a-shell.

### Story 5.3: Create Mock Test Environment

**As a** developer,  
**I want** a mock vault generator for testing,  
**So that** staging workflows can be tested without risking live data.

**Acceptance Criteria:**

**Given** the need for safe testing,  
**When** the mock generator runs,  
**Then** it creates a temporary directory structure mimicking the vault  
**And** it generates test notes with various frontmatter scenarios  
**And** the mock environment can be easily cleaned up  
**And** staging scripts can target the mock environment via argument.

### Story 5.4: Implement Staging Workflow Tests

**As a** developer,  
**I want** tests that verify note routing and validation,  
**So that** the core staging logic is validated.

**Acceptance Criteria:**

**Given** the mock test environment is set up,  
**When** staging workflow tests run,  
**Then** they test valid note routing to correct destinations  
**And** they test invalid notes moving to REFACTORING  
**And** they test error callout injection  
**And** they test dry-run mode output  
**And** all tests pass on both target platforms.

### Story 5.5: Add Regression Tests for Bug Fixes

**As a** developer,  
**I want** regression tests for the environment leakage and underscore bugs,  
**So that** these bugs don't recur.

**Acceptance Criteria:**

**Given** the bugs have been fixed,  
**When** regression tests run,  
**Then** they verify `env -i` prevents variable leakage between invocations  
**And** they verify trailing underscores are stripped from filenames  
**And** tests fail if the bugs are reintroduced  
**And** tests document the expected behavior for future maintainers.

### Story 5.6: Standardize Exit Codes

**As a** user,  
**I want** scripts to exit with standard codes,  
**So that** iOS Shortcuts and script chaining can handle success/failure appropriately.

**Acceptance Criteria:**

**Given** scripts are executed from iOS Shortcuts or other scripts,  
**When** execution completes,  
**Then** exit code 0 indicates success  
**And** exit code 1 indicates general error  
**And** exit code 2 indicates validation failure  
**And** exit codes are documented and consistent across all scripts.


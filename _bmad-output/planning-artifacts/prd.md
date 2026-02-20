# Brownfield Enhancement PRD

## Intro Project Analysis and Context

### Existing Project Overview

#### Analysis Source
- Document-project analysis available - using existing technical documentation
- Expert Interview regarding Staging Logic and Constraints

#### Current Project State
The project is a `home-manager` configuration for a development environment (Linux/WSL). The immediate focus is on **Obsidian Staging Automation**, a specific workflow to manage the user's "Second Brain". Currently, this relies on manual file moves, which is error-prone and inefficient, especially on mobile devices.

### Available Documentation Analysis

#### Available Documentation
- [x] Tech Stack Documentation (in `docs/brownfield-architecture.md`)
- [x] Source Tree/Architecture (in `docs/brownfield-architecture.md`)
- [ ] Coding Standards (Implicit in existing scripts, but specific POSIX sh standards needed)
- [ ] API Documentation (N/A)
- [ ] External API Documentation (N/A)
- [ ] UX/UI Guidelines (N/A - CLI/Script focus)
- [ ] Technical Debt Documentation (in `docs/brownfield-architecture.md`)
- [x] Other: `docs/brief.md` (Project Brief for this specific enhancement)

**Note:** Using existing project analysis from `docs/brownfield-architecture.md` and `docs/brief.md`.

### Enhancement Scope Definition

#### Enhancement Type
- [x] New Feature Addition
- [ ] Major Feature Modification
- [ ] Integration with New Systems
- [ ] Performance/Scalability Improvements
- [ ] UI/UX Overhaul
- [ ] Technology Stack Upgrade
- [ ] Bug Fix and Stability Improvements

#### Enhancement Description
Implement a POSIX-compliant shell script (`stage.sh`) and a corresponding configuration file (`staging-workflow.md`) to automate the processing of Obsidian notes. The system will parse YAML frontmatter, validate fields using configurable shell snippets, and move files from `01-STAGING` to their designated locations in `03-ZETTELKASTEN`, or to `02-REFACTORING` upon failure/collision.

#### Impact Assessment
- [ ] Minimal Impact (isolated additions)
- [x] Moderate Impact (some existing code changes - adding new scripts/config to `misc/obsidian`)
- [ ] Significant Impact (substantial existing code changes)
- [ ] Major Impact (architectural changes required)

### Goals and Background Context

#### Goals
- Automate file organization based on YAML frontmatter "Type" and "Fields".
- Ensure data integrity via validation rules executed as shell snippets (via `eval`).
- Run fast and reliably on Linux and iOS (`a-shell`) using POSIX `sh` and `jq`.
- Provide clear feedback for invalid files or naming collisions by moving them to `02-REFACTORING` and injecting an error callout.
- Maintain a stateless configuration (re-read config on every run) for easy mobile updates.

#### Background Context
The user needs a robust, cross-platform way to manage their Obsidian vault, ensuring that notes created on mobile or desktop are correctly categorized without manual friction. Manual filing is currently error-prone and tedious. The specific constraint of running on iOS via `a-shell` necessitates strict POSIX `sh` compliance. The "Configuration as Code" approach (embedding JSON in a Markdown note) allows for easy editing of workflow rules directly within Obsidian on any device.

### Change Log

| Change | Date | Version | Description | Author |
| :--- | :--- | :--- | :--- | :--- |
| Initial Draft | 2026-01-18 | 1.0 | Initial Brownfield PRD for Staging Automation | PM Agent |

## Requirements

### Functional Requirements
- **FR1**: The system MUST execute as a POSIX-compliant shell script (`stage.sh`), compatible with both Linux (bash/sh) and iOS (`a-shell`).
- **FR2**: The system MUST parse a JSON configuration block embedded within `99-SYSTEM/infrastructure/staging-workflow.md` using `jq`.
- **FR3**: The system MUST iterate through all files in the `01-STAGING` directory.
- **FR4**: For each file, the system MUST validate the presence of a "Type" field in the YAML frontmatter and match it against the loaded configuration.
- **FR5**: The system MUST validate required fields defined in the config.
    - **FR5.1**: If a field definition is an empty string `""`, valid if the field exists and is not empty.
    - **FR5.2**: If a field definition is a string, it MUST be treated as a shell snippet and executed via `eval` for validation (Return 0 = Pass, Non-zero = Fail).
- **FR6**: The system MUST enforce a mandatory unique ID check for every note (implicitly or explicitly defined in config) to prevent duplication.
- **FR7**: **Success Path**: If all validations pass, the system MUST move the file to the configured `destination` folder.
    - **FR7.1**: If a file with the same name already exists at the destination, the system MUST treat it as a failure (Collision).
- **FR8**: **Failure Path**: If validation fails OR a name collision occurs:
    - **FR8.1**: The file MUST be moved to `02-REFACTORING`.
    - **FR8.2**: An error callout (e.g., `> [!WARNING] Error: ...`) MUST be appended to the file content, immediately following the YAML frontmatter block (line after `---`).
- **FR9**: The system MUST be stateless, re-reading the configuration file on every execution.
- **FR10**: **Malformed Data**: If a file lacks valid YAML frontmatter or the frontmatter is unparseable, the system MUST treat it as a validation failure and move it to `02-REFACTORING` with a generic "Invalid Frontmatter" error.
- **FR11**: **Logging**: The system MUST append a run summary (Timestamp, Files Processed Count, Success Count, Failure Count) to `99-SYSTEM/logs/staging_logs.md`.

### Non-Functional Requirements
- **NFR1**: The script MUST complete execution on a batch of 10 notes in under 2 seconds on an iPhone (a-shell environment).
- **NFR2**: The script MUST NOT use any non-POSIX shell features (no arrays, no `[[ ]]`, no process substitution `<()`).

### Compatibility Requirements
- **CR1**: **Data Integrity**: The script MUST NOT modify the original content of the note *except* to append the error callout in case of failure.
## Technical Constraints and Integration Requirements

### Existing Technology Stack
- **Languages**: POSIX `sh` (Strict compliance required for iOS `a-shell`).
- **Data Processing**: `jq` (Version 1.6+).
- **OS**: Linux (WSL) and iOS (`a-shell`).
- **Infrastructure**: Git for version control; iCloud Drive for vault synchronization.
- **Dependencies**: `jq` must be installed and available in `$PATH`.

### Integration Approach
- **File Structure Approach**:
    - Script: `misc/obsidian/infrastructure/scripts/stage.sh`
    - Config: `misc/obsidian/infrastructure/staging-workflow.md`
    - Logs: `misc/obsidian/logs/staging_logs.md` (Symlinked to `99-SYSTEM/logs/staging_logs.md`)
- **Execution Model**: Manual execution via terminal (`./stage.sh`).
- **Path Resolution**: Script relies on relative paths from the vault root or explicit `VAULT_ROOT` environment variable.

### Code Organization and Standards
- **Naming Conventions**: `kebab-case` for filenames. `snake_case` for internal script variables and functions.
- **Coding Standards**:
    - Strict POSIX `sh` (#!/bin/sh).
    - All variables must be double-quoted to handle filenames with spaces.
    - Modular functions (e.g., `validate_file`, `move_file`, `log_event`).
- **Documentation**: Inline comments explaining complex `sed` or `jq` logic.

### Deployment and Operations
- **Testing Strategy**:
    - **Dry-Run Mode**: The script MUST support a `--dry-run` flag that prints actions (Validation Pass/Fail, Intended Move) to stdout without modifying files.
    - **Test Bed**: Developer should verify using a temporary directory structure mimicking the vault before deploying to the live vault.
- **Logging**:
    - Log location is fixed to `99-SYSTEM/logs/staging_logs.md` for MVP.
    - Log format: Markdown table or simple appended lines for easy rendering in Obsidian.

### Risk Assessment and Mitigation
- **Technical Risks**:
    - **BSD vs GNU `sed`**: `sed -i` behavior differs significantly between Linux (GNU) and macOS/iOS (BSD).
    - *Mitigation*: Avoid `sed -i`. Use `sed > temp && mv temp file` pattern to ensure cross-platform compatibility.
    - **`eval` Security**: Executing arbitrary strings from config.
    - *Mitigation*: Documentation must warn users; Script is local-only (low attack vector).
- **Integration Risks**:
    - **`jq` Availability**: User might not have `jq` installed on a new device.
## Epic and Story Structure

### Epic Structure
- **Epic Approach**: Single Epic structure. The enhancement is a coherent, single-purpose workflow tool. Splitting it would add unnecessary overhead.

### Epic 1: Automated Obsidian Staging Workflow
- **Epic Goal**: Eliminate manual file organization friction by implementing an automated, configurable staging script (`stage.sh`) that acts as a reliable gatekeeper for the Zettelkasten.
- **Integration Requirements**: Script must integrate with existing vault structure (`01-STAGING`, `02-REFACTORING`, `99-SYSTEM`) and run within the POSIX/sh constraints of `a-shell`.

#### Story 1.1: Infrastructure Setup & Logging
- **As a** Developer,
- **I want** the basic script structure with logging capabilities and pre-flight checks,
- **so that** I can debug future development steps and ensure the environment is correct.
- **Acceptance Criteria**:
    1. `stage.sh` exists and is executable.
    2. Script checks for `jq` and exits with error if missing.
    3. Script can write formatted log entries to `99-SYSTEM/logs/staging_logs.md` (or a mock location).
    4. `--dry-run` flag is implemented (even if it does nothing yet, the arg parsing works).

#### Story 1.2: Test Environment Generator
- **As a** Developer,
- **I want** a helper script to generate a dummy vault structure with valid and invalid test notes,
- **so that** I can safely test `stage.sh` without risking my actual data.
- **Acceptance Criteria**:
    1. `generate_test_data.sh` created.
    2. Generates folders: `01-STAGING`, `02-REFACTORING`, `03-ZETTELKASTEN`, `99-SYSTEM`.
    3. Generates `staging-workflow.md` with known test rules.
    4. Generates a mix of Valid, Invalid (missing type), and Invalid (bad field) notes in `01-STAGING`.

#### Story 1.3: Core Config Parser & Iteration Loop
- **As a** Developer,
- **I want** the script to parse the `staging-workflow.md` JSON and iterate through files,
- **so that** I can verify the script "sees" the work to be done.
- **Acceptance Criteria**:
    1. Script extracts JSON block from `staging-workflow.md` using `jq`.
    2. Script iterates through all `.md` files in `01-STAGING`.
    3. Script extracts YAML frontmatter from each file.
    4. Debug output shows: File Name, Extracted Type, and Matched Config Rule.

#### Story 1.4: Validation Logic Implementation
- **As a** Developer,
- **I want** the script to validate notes against the loaded configuration rules,
- **so that** I can correctly distinguish between "Valid" and "Invalid" notes.
- **Acceptance Criteria**:
    1. Implement "Type" existence check.
    2. Implement "Fields" existence check (empty string rule).
    3. Implement "Snippet" validation using `eval` (string rule).
    4. Log validation results (Pass/Fail + Reason) to stdout (or log file).

#### Story 1.5: File Operations (Move & Refactor)
- **As a** User,
- **I want** the script to actually move the files to their destinations or the refactoring folder,
- **so that** the staging process is automated.
- **Acceptance Criteria**:
    1. **Valid Notes**: Moved to `destination` defined in config.
    2. **Collisions**: If destination exists, treat as error -> move to Refactoring.
    3. **Invalid Notes**: Moved to `02-REFACTORING`.
    4. **Error Injection**: Append `> [!WARNING] {Reason}` to invalid notes using safe `sed` alternative (temp file + mv).
    5. **Integrity**: Original file content (users notes) remains 100% intact (minus the appended error).

#### Story 1.6: User Documentation
- **As a** User,
- **I want** clear documentation on how to write the JSON config and validation snippets,
- **so that** I can expand the system later without reading the shell script source code.
- **Acceptance Criteria**:
    1. `docs/staging-workflow-guide.md` created.
    2. Explains JSON structure.
    3. Provides examples of common validation snippets (e.g., date checks, regex).
    4. Explains how to set up the symlinks for a fresh install.



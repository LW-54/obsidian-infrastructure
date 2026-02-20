# Project Brief: Obsidian Staging Automation

## 1. Executive Summary
A lightweight, POSIX-compliant shell script to automate the "staging" of Obsidian notes into a Zettelkasten file structure. It acts as a gatekeeper, validating notes against a user-defined JSON configuration and routing them to their correct destination or a refactoring holding area.

## 2. Problem Statement
- **Current State:** Notes pile up in a "Staging" folder. Manually moving them is tedious and prone to error (forgetting fields, wrong folder).
- **Pain Points:** Inconsistent metadata, "entropy" in the vault, friction in the writing process on mobile.
- **Why Now:** To streamline the mobile workflow on iOS (`a-shell`) and ensure database integrity for future AI context.

## 3. Proposed Solution
- **Core Concept:** A `stage.sh` script that reads a `staging-workflow.md` config file.
- **Key Differentiator:** "Configuration as Code" stored directly within the Obsidian vault as a JSON block, enabling easy mobile editing while maintaining robust script logic via `jq`.
- **Vision:** "Write anywhere, run script, trust the system."

## 4. Target Users
- **Primary:** The User (You). Tech-savvy, uses Obsidian on Linux and iOS, values data integrity and automation.

## 5. Goals & Success Metrics
- **Objective:** Zero manual file moves for standard notes.
- **Metric:** 100% of "valid" notes are moved correctly. 100% of "invalid" notes are flagged with a specific error message.
- **Efficiency:** Script runs in <2 seconds on iPhone.

## 6. MVP Scope
- **Core Features:**
    - Parse JSON config from Markdown.
    - Loop through files in `01-STAGING`.
    - Extract YAML frontmatter.
    - Validate `Type` exists.
    - Validate required fields (existence + custom shell snippets).
    - Move valid files to destination.
    - Move invalid files to `02-REFACTORING` and append error callout.
- **Out of Scope:** Complex dependency trees, multi-pass refactoring, content modification beyond error logging.

## 7. Technical Considerations
- **Platform:** Linux (Desktop) & iOS (`a-shell`).
- **Language:** POSIX `sh`.
- **Dependencies:** `jq` (Must be present).
- **Config:** JSON block embedded in `99-SYSTEM/infrastructure/staging-workflow.md`.

## 8. Detailed Specifications

### 8.1 Folder Structure & Vault Tree
The system relies on a specific folder structure within the Obsidian Vault.

**Primary Folders:**

| Folder | Purpose |
| :--- | :--- |
| `01-STAGING` | **Input:** Where raw notes are placed for processing. |
| `02-REFACTORING` | **Error Output:** Where invalid notes are moved (with error logs). |
| `03-ZETTELKASTEN/...` | **Success Output:** Deep directory structure where valid notes settle. |
| `99-SYSTEM/infrastructure` | **Config Location:** Stores `staging-workflow.md` and scripts. |
| `99-SYSTEM/logs` | **Log Location:** Stores `staging_logs.md` for background run history. |

**Full Vault Tree:**
```text
.
├───00-INBOX
├───01-STAGING
├───02-REFACTORING
├───03-ZETTELKASTEN
│   ├───Guides
│   │   ├───Documentation
│   │   └───Recipes
│   ├───Ideas
│   │   ├───Gifts
│   │   ├───Purchases
│   │   ├───Questions
│   │   ├───Story Elements
│   │   └───To Do Some Day
│   ├───Media
│   │   ├───Anime
│   │   │   ├───Arcs
│   │   │   ├───Episodes
│   │   │   └───Seasons
│   │   ├───BD
│   │   │   └───Tomes
│   │   ├───Books
│   │   │   ├───Chapters
│   │   │   ├───Quotes
│   │   │   └───Tomes
│   │   ├───Comics
│   │   │   ├───Arcs
│   │   │   └───Issues
│   │   ├───Films
│   │   ├───Games
│   │   ├───Manga
│   │   │   ├───Arcs
│   │   │   ├───Chapters
│   │   │   └───Tomes
│   │   ├───Music
│   │   │   └───Albums
│   │   ├───Shows
│   │   │   ├───Episodes
│   │   │   └───Seasons
│   │   ├───Videos
│   │   ├───Websites
│   │   │   └───Pages
│   │   └───Webtoons
│   │       ├───Arcs
│   │       └───Chapters
│   ├───Projects
│   ├───Tasks
│   ├───Things
│   │   ├───Objects
│   │   ├───People
│   │   └───Places
│   ├───Thoughts
│   └───Topics
└───99-SYSTEM
    ├───ARCHIVE
    ├───attachments
    ├───bases
    ├───infrastructure
    │   ├───scripts
    │   ├───script_templates
    │   └───tests
    ├───PERIODIC
    ├───templates
    └───template_primitives
        ├───core
        └───media
```

### 8.2 Configuration Format (JSON)
The configuration must be a valid JSON block embedded within `staging-workflow.md`.
**Format:**
```json
{
  "TypeString": {
    "destination": "Path/To/Folder",
    "fields": {
      "fieldName1": "", 
      "fieldName2": "validation_shell_snippet"
    }
  }
}
```
**Validation Logic:**
- **Empty String (`""`):** Checks only for existence of the field.
- **Snippet:** Executed via `eval`. Returns 0 for pass, non-zero for fail.

## 9. Operational Requirements

### 9.1 Execution Mode
- **Non-Interactive:** The script MUST run without user prompts (for background execution).
- **Path Resolution:**
  - Script should auto-detect vault root (relative to its own position in `99-SYSTEM/...`).
  - Ideally supports a `VAULT_ROOT` environment variable or argument to override for testing.

### 9.2 Error Handling & Logging
- **In-File Errors:** If validation fails, append a specific error message as a callout (e.g., `> [!WARNING] Missing field: author`) immediately below the YAML frontmatter.
- **System Log:** Append run summary (Timestamp, Files Processed, Success/Fail counts) to `99-SYSTEM/logs/staging_logs.md`.

### 9.3 Testing Strategy
- **Mock Data:** Create a temporary directory structure mimicking the vault for unit testing.

## 10. Constraints & Assumptions
- **Constraint:** Must run on iOS `a-shell`.
- **Assumption:** User has `jq` installed. Notes always start with YAML frontmatter.

## 11. Risks
- **Risk:** `jq` unavailability on a specific environment.
- **Mitigation:** Check for `jq` at script start and exit gracefully with instructions if missing.

## 12. Next Steps
1.  Create the `staging-workflow.md` with the JSON config.
2.  Write the `stage.sh` script.
3.  Test with dummy files.

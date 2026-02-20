---
stepsCompleted:
  - step-01-init
  - step-02-discovery
  - step-02b-vision
  - step-02c-executive-summary
  - step-03-success
  - step-04-journeys
  - step-05-domain
  - step-06-innovation
  - step-07-project-type
  - step-08-scoping
  - step-09-functional
  - step-10-nonfunctional
  - step-11-polish
  - step-12-complete
workflowStatus: complete
inputDocuments:
  - docs/implementation_brief.md
  - docs/refactor_todo.md
  - docs/project-overview.md
  - docs/architecture.md
  - docs/technology_stack.md
  - docs/development_guide.md
  - docs/component_inventory.md
  - docs/source_tree_analysis.md
  - docs/conditional_analysis_deep.md
  - docs/enhancement-plan.md
  - docs/existing_documentation_inventory.md
  - docs/project_structure.md
workflowType: prd
documentCounts:
  briefCount: 1
  researchCount: 0
  brainstormingCount: 0
  projectDocsCount: 12
classification:
  projectType: CLI Tool
  domain: General
  complexity: Low
  projectContext: Brownfield
---

# Product Requirements Document - obsidian-scripts

**Author:** Lw
**Date:** 2026-02-20

## Executive Summary

This project refactors the existing Obsidian infrastructure automation system from an ad-hoc collection of scripts into a robust, testable foundation. The current system—comprising `tmpl.sh`, `tmpl_ux.sh`, `task.sh`, and `stage.sh`—suffers from bugs (environment variable leakage, filename sanitization issues), inconsistent directory structure, and manual configuration management. This refactor migrates the codebase to a clean `infrastructure/` layout with standardized paths, fixes critical bugs using environment isolation and defensive sanitization, and replaces the legacy `type_to_folder.md` configuration with a JSON-based `staging-workflow.md` format. The outcome is a POSIX-compliant shell toolset that runs reliably across Linux/WSL and iOS (a-shell), enabling confident iteration and deployment of future Obsidian workflow enhancements.

### What Makes This Special

Unlike one-off script fixes, this refactor prioritizes **testability and structural integrity** as the foundation for ongoing development. By implementing the `env -i` pattern for environment isolation and adding defensive underscore stripping, it eliminates a class of bugs that plague shell scripts running in stateful mobile environments. The directory reorganization (`bin/`, `config/`, `templates/`, `tests/`) creates clear boundaries that make the system comprehensible and extensible. The migration from flat configuration files to embedded JSON within Markdown preserves editability in Obsidian while enabling structured data parsing—bridging the gap between human-readable documentation and machine-readable configuration.

## Project Classification

| Attribute | Value |
|:---|:---|
| **Project Type** | CLI Tool |
| **Domain** | General (Personal Productivity) |
| **Complexity** | Low |
| **Project Context** | Brownfield Refactor |

## Success Criteria

### User Success

- **Confidence in Changes:** Developer can modify scripts or add new note types without fear of breaking iOS compatibility, verified by running the test suite and seeing 100% pass rate
- **Cross-Platform Reliability:** The same command produces identical results on Linux/WSL and iOS (a-shell) without manual workarounds
- **Clear Debugging:** When a note fails staging, the error callout in `02-REFACTORING/` provides specific, actionable feedback about which validation failed
- **Mobile Editability:** Configuration changes can be made directly in Obsidian on any device via the JSON-in-Markdown format

### Business Success

- **Foundation for Iteration:** Refactor completes with documented extension points, enabling future enhancements (new note types, validation rules) to be implemented in hours rather than days
- **Deployment Confidence:** Zero-downtime migration path—old `current_infrastructure/` can be removed only after full test suite passes in new `infrastructure/` location

### Technical Success

- **All Phases Complete:** Directory restructuring (Phase 1-2), bug fixes (Phase 3), and verification (Phase 4) all marked complete in `refactor_todo.md`
- **Bug Fixes Verified:** Persistent content bug fixed via `env -i` pattern; underscore sanitization strips trailing underscores from filenames
- **Configuration Migrated:** `type_to_folder.md` retired; all mappings successfully migrated to `config/staging-workflow.md` in JSON format
- **Test Coverage:** All integration tests pass: `test-1.1-infrastructure.sh` and related test files execute successfully
- **POSIX Compliance:** Scripts execute without errors in `a-shell` iOS environment and standard Linux `sh`

### Measurable Outcomes

| Metric | Target | Measurement Method |
|:---|:---|:---|
| Test Pass Rate | 100% | Run `infrastructure/tests/*.sh` |
| iOS Compatibility | Zero errors | Execute full workflow in a-shell |
| Migration Completeness | All mappings migrated | Compare `type_to_folder.md` to `config/staging-workflow.md` |
| Bug Fix Verification | Fixed issues don't recur | Regression tests for env leakage and underscore handling |

## Product Scope

### MVP - Minimum Viable Product

- Directory structure created (`bin/`, `config/`, `templates/`, `tests/`)
- All scripts moved and paths updated
- Configuration migrated to JSON format
- Persistent content bug fixed (`env -i` implementation)
- Underscore sanitization implemented
- Test suite passes

### Growth Features (Post-MVP)

- Additional validation rules for note types beyond basic ID check
- Enhanced logging with structured output
- Dry-run mode improvements with diff output
- Support for additional template types

### Vision (Future)

- Plugin architecture for custom validators
- Automatic backup integration before file moves
- Cross-vault synchronization capabilities
- Webhook or notification integration for staging events

## User Journeys

### Journey 1: The Daily Capture (Happy Path)

**Alex** is out and about when an idea strikes. They trigger an iOS Shortcut that creates a new note in `00-INBOX/` with a timestamp and their quick capture. Later, at their desk, Alex reviews the inbox, sees a note that's ready for the Zettelkasten, and drags it to `01-STAGING/`. They run `./stage.sh` from the terminal. The script validates the note's frontmatter (Type: Ideas, ID present), matches it against `config/staging-workflow.md`, and moves it to `03-ZETTELKASTEN/Ideas/Gifts/`. The note is now properly filed and searchable.

**Emotional Arc:** Capture → Review → Process → Organized

**Critical Moment:** Running `stage.sh` and seeing the note move to the correct subfolder without manual path construction.

### Journey 2: The Incomplete Note (Edge Case / Recovery)

**Alex** drags a half-formed note from `00-INBOX/` to `01-STAGING/` and runs `stage.sh`. The script detects the note is missing its `ID` field—a required validation per the config. Instead of failing silently or breaking, the script moves the note to `02-REFACTORING/` and injects a callout right after the YAML frontmatter: `> [!WARNING] Validation Failed: Required field 'ID' is missing`. Alex opens the note in Obsidian, fills in the ID, moves it back to `01-STAGING/`, and re-runs. This time it processes successfully to `03-ZETTELKASTEN/Thoughts/`.

**Emotional Arc:** Attempt → Error → Clarity → Fix → Success

**Critical Moment:** The error callout appears in the exact place Alex needs to see it—no log diving required.

### Journey 3: The Media Organizer (Complex Routing)

**Alex** finished reading a book and creates a note with Type: `Media-Books`. They move it to `01-STAGING/` and run `stage.sh`. The config recognizes this type maps to `03-ZETTELKASTEN/Media/Books/` with additional required fields (Author, Rating). All validations pass, and the note lands in the correct folder. Alex can now browse their book notes alongside Anime, Films, and Games in the Media section.

**Emotional Arc:** Completion → Validation → Proper Placement

**Critical Moment:** The complex folder hierarchy (Media → Books → Tomes/Chapters/Quotes) is navigated automatically based on Type and Fields.

### Journey 4: The Infrastructure Developer (Maintenance/Extension)

**Alex** wants to add a new category: "Podcasts" under Media. They open `config/staging-workflow.md` in Obsidian, add the new type definition with destination `03-ZETTELKASTEN/Media/Podcasts/`, and save. They run the test suite: `sh infrastructure/tests/test-*.sh`. All tests pass, including a new validation test for the Podcast type. Alex runs `stage.sh` on a test note—it routes correctly. The foundation is solid.

**Emotional Arc:** Intent → Configuration → Verification → Confidence

**Critical Moment:** Tests pass, proving the refactor delivered testability and the config change didn't break existing types.

### Journey Requirements Summary

| Journey | Reveals Requirements |
|:---|:---|
| Daily Capture | iOS Shortcut → INBOX → manual staging → automated routing |
| Incomplete Note | Validation rules, error callout injection, REFACTORING folder workflow |
| Media Organizer | Complex nested folder routing, type-specific field validation |
| Infrastructure Developer | JSON configuration format, testability, extensible type system |

## CLI Tool Specific Requirements

### Project-Type Overview

This is a POSIX-compliant shell-based CLI toolset designed for silent, scriptable operation within an Obsidian vault context. The tools prioritize Unix philosophy principles: do one thing well, expect silent success, and provide clear errors on failure.

### Technical Architecture Considerations

- **POSIX Compliance:** Must execute without errors on both Linux `sh` (dash/bash) and iOS `a-shell` environments
- **Silent Operation:** Scripts produce no output on success; file creation/movement is the only side effect
- **Exit Codes:** Proper exit codes (0 = success, non-zero = failure) enable script chaining and automation
- **Logging:** Optional verbose mode (`-v` or `--verbose`) for debugging, silent by default
- **Error Handling:** Fail fast with clear error messages to stderr when operations fail
- **Path Resolution:** All paths resolved relative to script location; support for optional `VAULT_ROOT` environment variable override

### Implementation Considerations

- **Argument Parsing:** Simple positional arguments or basic flags (`--dry-run`, `--verbose`)
- **Config Loading:** Read `../config/staging-workflow.md` relative to script location in `infrastructure/bin/`
- **Atomic Operations:** File moves use atomic patterns where possible (critical for iOS sync scenarios)
- **Cross-Platform Compatibility:** Avoid GNU-specific features; use POSIX-compliant alternatives (e.g., `sed` without `-i`)

### Out of Scope

- Interactive prompts and TUI features
- Shell tab-completion
- Complex output formatting (JSON/Markdown output to stdout)
- Environment variable configuration overrides
- Daemon/long-running processes

## Project Scoping & Phased Development

### MVP Strategy & Philosophy

**MVP Approach:** Foundation-First Refactor — Deliver a robust, testable infrastructure that eliminates existing bugs and establishes clear structural boundaries. The MVP is complete when the system is demonstrably more reliable than the legacy version and provides a stable base for future enhancements.

**Resource Requirements:** Single developer (you) with shell scripting experience; no external dependencies beyond `jq` availability.

### MVP Feature Set (Phase 1)

**Core User Journeys Supported:**
- Daily Capture (iOS → INBOX → Zettelkasten routing)
- Incomplete Note handling (validation failure → REFACTORING with error callouts)
- Infrastructure Developer workflow (test-driven configuration changes)

**Must-Have Capabilities:**
- Directory structure: `infrastructure/bin/`, `config/`, `templates/`, `tests/`
- All scripts moved and executable with updated relative paths
- Configuration migrated from `type_to_folder.md` to `config/staging-workflow.md` (JSON-in-Markdown)
- Persistent content bug fixed via `env -i` environment isolation
- Underscore sanitization implemented (`NAME="${NAME%_}"`)
- Full test suite passing (`infrastructure/tests/*.sh`)
- POSIX compliance verified on both Linux/WSL and iOS (a-shell)

### Post-MVP Features

**Phase 2 (Growth):**
- Additional field validation rules beyond ID presence (e.g., date formats, regex patterns)
- Enhanced dry-run mode with diff output showing what would change
- Support for additional template types beyond ST-default and ST-task

**Phase 3 (Expansion):**
- Plugin architecture for custom validators
- Automatic backup before file moves
- Cross-vault synchronization capabilities

### Risk Mitigation Strategy

**Technical Risks:**
- **`env -i` Cross-Platform Behavior:** The environment isolation fix must be tested thoroughly on both Linux and iOS a-shell before considering Phase 1 complete. Risk mitigation: Include specific regression tests that verify no variable leakage occurs between script invocations.

**Resource Risks:**
- **Single Developer Bandwidth:** If time constraints emerge, the scope is already minimal—no deferrable features remain. The phased approach in `refactor_todo.md` provides natural stopping points if needed.

**Compatibility Risks:**
- **`jq` Version Differences:** Ensure JSON parsing works consistently across the jq versions available on Linux (typically 1.6+) and iOS a-shell. Mitigation: Use basic jq filters only, avoid advanced features.

## Functional Requirements

### Directory Structure & Organization

- FR1: System maintains executable scripts in `infrastructure/bin/` directory
- FR2: System maintains configuration files in `infrastructure/config/` directory
- FR3: System maintains templates in `infrastructure/templates/` directory
- FR4: System maintains test files in `infrastructure/tests/` directory
- FR5: Scripts execute from `infrastructure/bin/` with relative paths to sibling directories

### Configuration Management

- FR6: System reads routing configuration from `infrastructure/config/staging-workflow.md`
- FR7: System parses JSON configuration embedded within Markdown files
- FR8: System supports configurable note type definitions with destination folders
- FR9: System supports configurable field validation rules per note type
- FR10: Configuration changes take effect on next script execution (stateless reload)

### Note Processing & Routing

- FR11: System processes all files in `01-STAGING/` directory
- FR12: System extracts YAML frontmatter from Markdown files
- FR13: System routes validated notes to configured destinations in `03-ZETTELKASTEN/`
- FR14: System supports nested folder destinations (e.g., `Media/Books/Tomes/`)
- FR15: System treats filename collisions as validation failures

### Validation & Error Handling

- FR16: System validates presence of required fields per note type configuration
- FR17: System validates presence of "Type" field in note frontmatter
- FR18: System validates field values using configurable shell snippet rules
- FR19: System moves invalid notes to `02-REFACTORING/` directory
- FR20: System injects error callouts into invalid notes immediately after YAML frontmatter
- FR21: System preserves original note content except for injected error callouts

### Cross-Platform Execution

- FR22: System executes on Linux/WSL using POSIX `sh`
- FR23: System executes on iOS `a-shell` using POSIX `sh`
- FR24: System avoids GNU-specific shell features (e.g., `sed -i`, `[[ ]]`, arrays)
- FR25: System handles filenames with spaces correctly
- FR26: System isolates script environment to prevent variable leakage between invocations

### Testing & Quality Assurance

- FR27: System includes test suite executable via `infrastructure/tests/*.sh`
- FR28: System supports dry-run mode showing intended actions without file modifications
- FR29: System generates test data for validation of staging workflows
- FR30: System exits with non-zero status on failure for script chaining


## Non-Functional Requirements

### Performance

- **NFR-P1:** Script execution completes within 2 seconds for batches of 10 notes on iPhone (a-shell environment)
- **NFR-P2:** Template generation completes within 500ms for single note creation
- **NFR-P3:** Configuration loading overhead is negligible (<100ms) for typical config sizes

### Reliability

- **NFR-R1:** Scripts produce identical results on Linux `sh` and iOS `a-shell` for identical inputs
- **NFR-R2:** Failed script execution leaves filesystem in consistent state (no partial file moves)
- **NFR-R3:** Test suite passes 100% of runs on both target platforms

### Maintainability

- **NFR-M1:** All scripts pass shellcheck linting with zero warnings
- **NFR-M2:** New note types can be added via configuration change only (no script modification)
- **NFR-M3:** All functions include inline comments explaining complex logic (e.g., `sed`, `jq` operations)

### Integration

- **NFR-I1:** Scripts function correctly with Obsidian's file watching (atomic moves where possible)
- **NFR-I2:** Configuration file format is valid Markdown that renders correctly in Obsidian
- **NFR-I3:** Scripts exit with standard codes (0=success, 1=general error, 2=validation failure) for iOS Shortcuts integration


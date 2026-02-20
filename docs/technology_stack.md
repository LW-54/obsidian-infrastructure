# Technology Stack

**Analysis Date:** 2026-02-20
**Scan Level:** Deep

## Core Technologies

| Category | Technology | Version | Usage |
|----------|------------|---------|-------|
| **Language** | Bash / Shell | N/A | Primary logic for all scripts (`.sh`) |
| **Automation** | iOS Shortcuts / a-shell | N/A | Execution environment mentioned by user |
| **Testing** | Bash Scripts | Custom | Test files located in `tests/` (e.g., `test-1.1-infrastructure.sh`) |
| **Templates** | Markdown | N/A | Used for `type_to_folder` and script templates |

## Architecture Pattern

- **Style:** Procedural Scripting
- **Structure:**
  - **Scripts (`current_infrastructure/scripts/`):** Core logic implementation.
  - **Templates (`current_infrastructure/script_templates/`):** Blueprint files for generated content.
  - **Configuration (`current_infrastructure/type_to_folder.md`):** Data-driven configuration for folder routing.
  - **Tests (`tests/`):** Verification scripts.

## Observations
The project relies heavily on shell scripting conventions. The integration with iOS Shortcuts suggests a mobile-first or cross-platform usage scenario (a-shell on iOS).

# Component Inventory

**Analysis Date:** 2026-02-20
**Scan Level:** Deep

## Script Components

| Component | Path | Description | Type |
|-----------|------|-------------|------|
| **Template Engine** | `current_infrastructure/scripts/tmpl.sh` | Core logic for template expansion. Handles heredoc substitution. | Core |
| **UX Wrapper** | `current_infrastructure/scripts/tmpl_ux.sh` | Main entry point. Handles arguments, temp files, and safety checks. | Wrapper |
| **Task Wrapper** | `current_infrastructure/scripts/task.sh` | Convenience wrapper for creating tasks. Sets default template. | Wrapper |
| **Test Data Generator** | `scripts/generate_test_data.sh` | Generates sample data for testing purposes. | Tool |
| **Staging Script** | `scripts/stage.sh` | Prepares environment or data (assumed based on name). | Tool |

## Template Components

| Template | Path | Description |
|----------|------|-------------|
| **Task Template** | `current_infrastructure/script_templates/ST-task.md` | Blueprint for task notes. Includes fields for status, due date, etc. | Template |
| **Default Template** | `current_infrastructure/script_templates/ST-default.md` | Fallback template for generic notes. | Template |

## Configuration Components

| Config | Path | Description |
|--------|------|-------------|
| **Folder Map** | `current_infrastructure/staging-workflow.md` | JSON configuration for staging workflow rules. | Config |

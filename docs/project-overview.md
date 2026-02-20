# Project Overview

**Analysis Date:** 2026-02-20
**Scan Level:** Deep

## Purpose
This project provides a set of automation scripts for managing an Obsidian vault. It is designed to be used in conjunction with mobile automation tools (like iOS Shortcuts and a-shell) to quickly capture tasks and ideas.

## Key Features
- **Task Creation:** Quickly create tasks with pre-filled templates using `task.sh`.
- **Template Engine:** Powerful shell-based variable substitution using `tmpl.sh`.
- **User Wrapper:** Handles input parsing, variable files, and file naming via `tmpl_ux.sh`.
- **Extensible Configuration:** Uses `staging-workflow.md` to map content types to specific folders (e.g., Ideas -> Ideas/Box).

## Architecture Summary
- **Type:** CLI / Script Collection
- **Language:** Bash (POSIX sh compatible)
- **Repository Type:** Monolith (Single infrastructure folder)
- **Primary Integration:** iOS Shortcuts via a-shell

## Getting Started
See [Development Guide](./development_guide.md) for installation and usage instructions.

## Documentation Index
- [Architecture](./architecture.md)
- [Component Inventory](./component_inventory.md)
- [Source Tree Analysis](./source_tree_analysis.md)
- [Technology Stack](./technology_stack.md)

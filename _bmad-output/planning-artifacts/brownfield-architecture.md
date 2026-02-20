# home-manager Brownfield Architecture Document

## Introduction

This document captures the CURRENT STATE of the `home-manager` configuration codebase. It serves as a reference for AI agents to understand the project's structure, conventions, and goals to effectively assist in its development.

### Document Scope

This is a comprehensive documentation of the entire system, focusing on its use for managing a development environment across WSL and Windows, with a particular emphasis on the active development of **Obsidian Staging Automation**.

### Change Log

| Date       | Version | Description                 | Author    |
| ---------- | ------- | --------------------------- | --------- |
| 2026-01-18 | 1.0     | Initial brownfield analysis | Winston   |
| 2026-01-19 | 1.1     | Update with Obsidian Staging details | Winston   |

## Quick Reference - Key Files and Entry Points

### Critical Files for Understanding the System

- **Main Entry**: `flake.nix` - The Nix flake entry point that defines dependencies and outputs.
- **Core Configuration**: `home.nix` - The central `home-manager` configuration file that imports all other modules.
- **Configuration Modules**: `modules/*.nix` - Individual files that declaratively manage specific tools or aspects of the environment (e.g., git, zsh, clis).
- **Automation Scripts**: `scripts/*.sh` - Imperative scripts for managing the environment (e.g., applying updates).
- **Cross-Platform Scripts**: `misc/obsidian/` - Location for scripts intended to be cross-platform, especially for Obsidian workflows.

## High Level Architecture

### Technical Summary

This project is a declarative user environment configuration managed by Nix and the `home-manager` framework. It is designed to be the single source of truth for the user's shell, tools, and scripts on a Linux (WSL) system, with planned extensions to manage parts of the Windows workflow through symlinks and scripting.

### Actual Tech Stack

| Category            | Technology        | Version/Details                                 | Notes                                                                 |
| ------------------- | ----------------- | ----------------------------------------------- | --------------------------------------------------------------------- |
| Configuration       | Nix               | Unstable channel                                | The core declarative language for the entire system.                  |
| Management          | Home Manager      | Managed via Nix Flake                           | Framework for managing user-specific environment (`dotfiles`).        |
| Shell               | Bash, Zsh         | Configured via `modules/`                       | Both are configured, user can choose.                                 |
| Scripting           | POSIX `sh` / Bash | `bash` for system scripts, `sh` for Obsidian    | **CRITICAL**: Obsidian scripts must be POSIX-compliant for a-shell (iOS). |
| OS Environment      | WSL (Linux)       | Primary target for the Nix configuration.       | Windows Subsystem for Linux.                                          |
| Future Integration  | Windows           | Via symlinks, Komorebi, AutoHotkey              | Configuration and scripting for Windows tools is a future goal.       |

### Repository Structure Reality Check

- **Type**: Monolithic repository for all personal environment configuration.
- **Package Manager**: `nix`
- **Notable**: The structure cleanly separates Nix modules, scripts, and dotfiles, making it modular and extensible.

## Source Tree and Module Organization

### Project Structure (Actual)

```text
.
├── flake.nix              # Nix flake entry point
├── home.nix               # Main home-manager configuration
├── modules/               # Directory for individual Nix modules
│   ├── aliases.nix        # Shell aliases
│   ├── bash.nix           # Bash shell configuration
│   ├── clis.nix           # Command-line tools installation
│   ├── git.nix            # Git configuration
│   ├── obsidian.nix       # Configuration related to Obsidian
│   └── ...                # Other tool configurations
├── scripts/               # Helper scripts for managing the environment
│   ├── home-manager-*.sh  # Rebuild, update, push scripts
└── misc/
    └── obsidian/          # Scripts and infrastructure for Obsidian
        ├── infrastructure/
        │   ├── scripts/   # Where stage.sh will live
        │   ├── tests/     # Where test scripts will live
        │   └── staging-workflow.md # Configuration file
        └── logs/          # Symlinked logs folder
```

### Key Modules and Their Purpose

- **`flake.nix`**: Defines all dependencies (`nixpkgs`, `home-manager`) and builds the final `homeManagerConfiguration`.
- **`home.nix`**: Acts as the central hub, importing all the modular configurations from the `modules/` directory.
- **`modules/clis.nix`**: Manages the installation of command-line packages, providing a single place to add or remove tools.
- **`modules/scripts.nix`**: Manages user scripts, making them available in the shell's `PATH`.
- **`misc/obsidian/`**: This directory is designated for Obsidian-related infrastructure. It contains scripts that are symlinked into the iCloud vault for cross-platform use.

## Technical Debt and Known Issues

### Critical Technical Debt

1.  **Windows Integration is Manual**: The system does not yet declaratively manage Windows applications. Integration with tools like Komorebi or AutoHotkey is a future goal and will require a strategy for bridging Nix with Windows scripting.
2.  **No Automated Testing**: As is common for dotfile repositories, there are no automated tests. Changes must be verified manually by rebuilding the environment.

### Workarounds and Gotchas

- **POSIX `sh` Compliance**: This is a hard constraint for any scripts intended for the Obsidian workflow. The `a-shell` environment on iOS does not support Bash-specific features. All such scripts must be written in and tested against a POSIX-compliant `sh` interpreter.
- **iCloud Symlinking**: The Obsidian infrastructure relies on files in this repository being symlinked to the correct location in the user's iCloud Drive. This setup is managed manually and is a critical dependency for the cross-platform workflow.

## Integration Points and External Dependencies

### External Services

| Service | Purpose        | Integration Type | Key Files/Folders      |
| ------- | -------------- | ---------------- | ---------------------- |
| iCloud  | File Sync      | Filesystem       | `misc/obsidian/` (via symlink) |
| GitHub  | Source Control | Git              | `.git/`                |

## Development and Deployment

### Local Development Setup

1.  Clone the repository.
2.  Ensure Nix with flake support is installed.
3.  Run one of the management scripts.

### Build and Deployment Process

- **Build/Deploy Command**: `scripts/home-manager-rebuild.sh` is the primary command to apply the configuration to the local system.
- **Update Command**: `scripts/home-manager-update.sh` updates the Nix flake inputs (dependencies) to their latest versions.

## Current Enhancement: Obsidian Staging Automation

The active development focus is **Epic 1: Automated Obsidian Staging Workflow**.

### New Files/Modules
- `misc/obsidian/infrastructure/scripts/stage.sh`: The core automation script (POSIX sh).
- `misc/obsidian/infrastructure/staging-workflow.md`: The "Configuration as Code" file containing JSON logic.
- `misc/obsidian/infrastructure/tests/`: Directory for test scripts and mock data generators.

### Integration Considerations
- **Environment Detection**: Scripts must gracefully handle running on Linux (dev) vs `a-shell` (prod) by checking for dependency availability (`jq`).
- **Path Resolution**: Scripts must be relative-path aware or accept a `VAULT_ROOT` argument to facilitate testing in a mock environment without risking live data.
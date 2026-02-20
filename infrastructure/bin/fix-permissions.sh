#!/bin/sh

# ==============================================================================
# fix-permissions.sh - Fix script permissions
#
# Description:
#   Sets correct executable permissions on all infrastructure scripts.
#   Run this after cloning or if scripts fail with "Permission denied".
#
# Usage:
#   ./fix-permissions.sh
# ==============================================================================

echo "Fixing script permissions..."

# Get bin directory and infrastructure root
BIN_DIR="$(cd "$(dirname "$0")" && pwd)"
INFRA_DIR="$(cd "$BIN_DIR/.." && pwd)"

# Make all scripts in bin/ executable
echo "  Setting bin/ scripts executable..."
chmod +x "$BIN_DIR/"*.sh 2>/dev/null || true

# Make all test scripts executable
echo "  Setting tests/ scripts executable..."
chmod +x "$INFRA_DIR/tests/"*.sh 2>/dev/null || true
echo "Done!"

echo "Done!"

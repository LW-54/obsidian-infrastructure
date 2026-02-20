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

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Make all scripts in bin/ executable
echo "  Setting bin/ scripts executable..."
chmod +x "$SCRIPT_DIR/bin/"*.sh 2>/dev/null || true

# Make all test scripts executable
echo "  Setting tests/ scripts executable..."
chmod +x "$SCRIPT_DIR/tests/"*.sh 2>/dev/null || true

# Make this script itself executable
chmod +x "$SCRIPT_DIR/fix-permissions.sh" 2>/dev/null || true

echo "Done!"

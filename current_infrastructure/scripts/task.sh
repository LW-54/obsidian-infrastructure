#!/bin/sh
# task.sh - small wrapper to create task notes via tmpl_ux.sh
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P)
TUX="${TUX:-$SCRIPT_DIR/tmpl_ux.sh}"
TEMPLATE="${TEMPLATE:-ST-task.md}"

[ -x "$TUX" ] || { echo "Error: tmpl_ux.sh not found/executable: $TUX" >&2; exit 1; }

# forward all args; first arg is NAME, others are passed through
exec sh "$TUX" "$@" -T "$TEMPLATE"

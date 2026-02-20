#!/bin/sh
# tmpl_ux.sh - Generic wrapper to create notes from templates
# Usage: tmpl_ux.sh NAME [ -T TEMPLATE ] [ -e varsfile ] [ --list VAR=a,b ] [ KEY=VALUE ... ]
# Default template: ST-default.md (looked up in TEMPLATE_DIR)
set -eu

# locations (adjust if you want)
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P)
VAULT_ROOT=$(cd "$SCRIPT_DIR/../../.." && pwd -P)
TEMPLATE_DIR="${TEMPLATE_DIR:-$SCRIPT_DIR/../script_templates}"
DEFAULT_TEMPLATE="${DEFAULT_TEMPLATE:-ST-default.md}"
TEMPLATE_FILE=""
INBOX_DIR="${INBOX_DIR:-$VAULT_ROOT/00-INBOX}"
TMPL_SH="${TMPL_SH:-$SCRIPT_DIR/tmpl.sh}"

usage() {
  cat <<USAGE >&2
Usage: $0 NAME [ -T TEMPLATE ] [ -e varsfile ] [ --list VAR=a,b ] [ KEY=VALUE ... ]

NAME          note filename (adds .md if needed) placed in 00-INBOX
-T TEMPLATE   template path or name (if name found in TEMPLATE_DIR, that is used)
-e FILE       source extra vars file (optional)
--list VAR=a,b  create YAML list variable
KEY=VALUE     set variables for template (supports quoted multi-word values)
USAGE
  exit 2
}

# basic checks
[ -x "$TMPL_SH" ] || { echo "Error: tmpl.sh not found/executable: $TMPL_SH" >&2; exit 1; }
[ -d "$INBOX_DIR" ] || { echo "Error: inbox dir not found: $INBOX_DIR" >&2; exit 1; }

if [ $# -lt 1 ]; then usage; fi

NAME="$1"; shift

case "$NAME" in
  *.md) OUTFILE="$INBOX_DIR/$NAME" ;;
  *)    OUTFILE="$INBOX_DIR/$NAME.md" ;;
esac

[ ! -e "$OUTFILE" ] || { echo "Error: target exists: $OUTFILE" >&2; exit 1; }

# vars handling
USER_VARS_FILE=""   # user-supplied -e
TMP_VARS=""         # temp file we will create (if needed)
trap_files=""
cleanup_trap_add() { trap_files="${trap_files}$1 "; }
cleanup() { for f in $trap_files; do [ -n "$f" ] && rm -f -- "$f" 2>/dev/null || true; done; }
trap 'cleanup' EXIT INT TERM

# replaced mktemp usage with portable unique-file creation
ensure_tmp_varsfile() {
  if [ -z "$TMP_VARS" ]; then
    TMPDIR="${TMPDIR:-/tmp}"
    TMP_VARS="$TMPDIR/tmplux.vars.$$"
    n=0
    while [ -e "$TMP_VARS" ]; do
      n=$((n + 1))
      TMP_VARS="$TMPDIR/tmplux.vars.$$.$n"
    done
    : > "$TMP_VARS" || { echo "Error: cannot create tmp vars file: $TMP_VARS" >&2; exit 1; }
    cleanup_trap_add "$TMP_VARS"
  fi
}

# helper: strip matching surrounding quotes
strip_surrounding_quotes() {
  s="$1"
  case "$s" in
    \"*\")
      s=${s#\"}; s=${s%\"}
      ;;
    \'*\')
      s=${s#\'}; s=${s%\'}
      ;;
  esac
  printf '%s' "$s"
}

# parse options after NAME
while [ $# -gt 0 ]; do
  case "$1" in
    -T)
      if [ $# -lt 2 ]; then echo "Error: -T requires an argument" >&2; exit 2; fi
      TEMPLATE_FILE="$2"; shift 2
      ;;
    -e)
      if [ $# -lt 2 ]; then echo "Error: -e requires a file" >&2; exit 2; fi
      USER_VARS_FILE=$2
      [ -f "$USER_VARS_FILE" ] || { echo "Error: vars file not found: $USER_VARS_FILE" >&2; exit 1; }
      shift 2
      ;;
    --list)
      if [ $# -lt 2 ]; then echo "Error: --list requires VAR=a,b" >&2; exit 2; fi
      pair=$2; shift 2
      var=${pair%%=*}
      vals=${pair#*=}
      if [ -z "$var" ] || [ "$var" = "$vals" ]; then echo "Error: bad --list syntax" >&2; exit 2; fi
      case "$var" in
        ''|*[!A-Za-z0-9_]*)
          echo "Error: invalid variable name for --list: $var" >&2; exit 2;;
      esac

      # build YAML block without leading newline
      OLDIFS=$IFS; IFS=','
      list=""
      for elt in $vals; do
        trimmed=$(strip_surrounding_quotes "$elt")
        trimmed=$(printf '%s' "$trimmed" | sed 's/^ *//; s/ *$//')
        list="${list}  - ${trimmed}\n"
      done
      IFS=$OLDIFS

      ensure_tmp_varsfile
      # open assignment without newline, then append the list and close quote
      printf "%s='" "$var" >> "$TMP_VARS"
      printf "%b" "$list" >> "$TMP_VARS"
      printf "'\n" >> "$TMP_VARS"
      ;;
    *=*)
      # KEY=VALUE. value might contain spaces and may be split; handle quoted multi-token values.
      k=${1%%=*}
      v=${1#*=}
      shift

      # If value starts with a quote and doesn't end with it, consume more arguments
      case "$v" in
        \"* )
          case "$v" in
            *\" ) ;; # already closed
            * )
              while [ $# -gt 0 ]; do
                nxt=$1; shift
                v="$v $nxt"
                case "$v" in *\" ) break ;; esac
              done
              ;;
          esac
          ;;
        \'* )
          case "$v" in
            *\' ) ;;  # already closed
            * )
              while [ $# -gt 0 ]; do
                nxt=$1; shift
                v="$v $nxt"
                case "$v" in *\' ) break ;; esac
              done
              ;;
          esac
          ;;
      esac

      v=$(strip_surrounding_quotes "$v")

      case "$k" in
        ''|*[!A-Za-z0-9_]*)
          echo "Warning: ignoring invalid var name: $k" >&2
          ;;
        *)
          ensure_tmp_varsfile
          esc=$(printf '%s' "$v" | sed "s/'/'\"'\"'/g")
          printf "%s='%s'\n" "$k" "$esc" >> "$TMP_VARS"
          ;;
      esac
      ;;
    -h|--help) usage ;;
    *)
      # unknown token — ignore
      shift
      ;;
  esac
done

# resolve template file: if TEMPLATE_FILE is empty use default; if name not an existing file, try TEMPLATE_DIR/TEMPLATE_FILE
if [ -z "$TEMPLATE_FILE" ]; then
  TEMPLATE_FILE="$TEMPLATE_DIR/$DEFAULT_TEMPLATE"
fi
if [ ! -f "$TEMPLATE_FILE" ]; then
  # try TEMPLATE_DIR/TEMPLATE_FILE if not already
  if [ -f "$TEMPLATE_DIR/$TEMPLATE_FILE" ]; then
    TEMPLATE_FILE="$TEMPLATE_DIR/$TEMPLATE_FILE"
  else
    echo "Error: template not found: $TEMPLATE_FILE" >&2
    exit 1
  fi
fi

# if we created tmp vars and user supplied a -e, merge (user file first so CLI overrides)
if [ -n "$TMP_VARS" ] && [ -n "$USER_VARS_FILE" ]; then
  # replaced mktemp with portable unique-file creation for MERGED
  TMPDIR="${TMPDIR:-/tmp}"
  MERGED="$TMPDIR/tmplux.vars.merged.$$"
  k=0
  while [ -e "$MERGED" ]; do
    k=$((k + 1))
    MERGED="$TMPDIR/tmplux.vars.merged.$$.$k"
  done
  : > "$MERGED" || { echo "Error: cannot create merged file: $MERGED" >&2; exit 1; }
  cleanup_trap_add "$MERGED"
  cat "$USER_VARS_FILE" > "$MERGED"
  echo "" >> "$MERGED"
  cat "$TMP_VARS" >> "$MERGED"
  VARS_TO_PASS="$MERGED"
elif [ -n "$TMP_VARS" ]; then
  VARS_TO_PASS="$TMP_VARS"
elif [ -n "$USER_VARS_FILE" ]; then
  VARS_TO_PASS="$USER_VARS_FILE"
else
  VARS_TO_PASS=""
fi

# build args for tmpl.sh
set -- "$TMPL_SH"
[ -n "$VARS_TO_PASS" ] && set -- "$@" -e "$VARS_TO_PASS"
set -- "$@" -o "$OUTFILE" "$TEMPLATE_FILE"

echo "Creating: $OUTFILE"
echo "Using template: $TEMPLATE_FILE"

exec sh "$@"

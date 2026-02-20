#!/bin/sh
# tmpl.sh - POSIX template expander (heredoc-runner + runtime evaluation)
# Usage: tmpl.sh [-e vars.env] [-o outfile] template.md
set -eu

VARSFILE=""
OUTFILE=""
TEMPLATE=""

usage() {
  cat <<'USAGE' >&2
Usage: tmpl.sh [-e vars.env] [-o outfile] template.md

  -e file   source and export variables from file (optional)
  -o file   write result to file (otherwise stdout)
  -h        show this help
USAGE
}

# parse options
while [ $# -gt 0 ]; do
  case "$1" in
    -e) VARSFILE=$2; shift 2 ;;
    -o) OUTFILE=$2; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*)
      echo "Unknown option: $1" >&2
      usage
      exit 2
      ;;
    *) TEMPLATE=$1; shift ;;
  esac
done

if [ -z "$TEMPLATE" ]; then
  echo "Error: missing template file" >&2
  usage
  exit 1
fi

if [ ! -f "$TEMPLATE" ]; then
  echo "Error: template not found: $TEMPLATE" >&2
  exit 1
fi

if [ -n "$VARSFILE" ]; then
  if [ ! -f "$VARSFILE" ]; then
    echo "Error: vars file not found: $VARSFILE" >&2
    exit 1
  fi
  # export assignments so child sees them
  set -a
  # shellcheck disable=SC1090
  . "$VARSFILE"
  set +a
fi

# create a safe, unlikely heredoc marker that is not present in template
BASE_MARKER="__TMPL_END__$$"
marker="$BASE_MARKER"
i=0
while grep -Fq "$marker" "$TEMPLATE" 2>/dev/null; do
  i=$((i + 1))
  marker="${BASE_MARKER}_$i"
done

# create runner script that uses an unquoted heredoc so expansions happen in the child shell
# REPLACED mktemp with portable unique-filename logic (avoid mktemp on a-Shell extension)
# Find writable temp directory (iOS/a-shell doesn't have /tmp)
# First try user-provided TMPDIR, then a local tmp folder in infrastructure, then fallback
SCRIPT_DIR="$(dirname "$0")"
LOCAL_TMP="$SCRIPT_DIR/../tmp"

if [ -n "${TMPDIR:-}" ] && [ -d "$TMPDIR" ] && [ -w "$TMPDIR" ]; then
  : # use existing valid TMPDIR
elif [ -d "$LOCAL_TMP" ] && [ -w "$LOCAL_TMP" ]; then
  TMPDIR="$LOCAL_TMP"
else
  # Try to create local tmp if it doesn't exist
  mkdir -p "$LOCAL_TMP" 2>/dev/null
  if [ -d "$LOCAL_TMP" ] && [ -w "$LOCAL_TMP" ]; then
    TMPDIR="$LOCAL_TMP"
  elif [ -w "/tmp" ]; then
    TMPDIR="/tmp"
  else
    # Last resort: current directory
    TMPDIR="."
  fi
fi

RUNNER="$TMPDIR/tmpl.run.$$"
n=0
while [ -e "$RUNNER" ]; do
  n=$((n + 1))
  RUNNER="$TMPDIR/tmpl.run.$$.$n"
done
# attempt to create the runner file
: > "$RUNNER" || {
  echo "Error: cannot create runner file: $RUNNER" >&2
  exit 1
}

cleanup() {
  [ -n "${RUNNER:-}" ] && [ -e "$RUNNER" ] && rm -f -- "$RUNNER" 2>/dev/null || true
  [ -n "${TMPOUT:-}" ] && [ -e "$TMPOUT" ] && rm -f -- "$TMPOUT" 2>/dev/null || true
}
trap 'cleanup' EXIT INT TERM

# write runner: a small portable shell script that emits the template via an unquoted heredoc
printf '%s\n' '#!/bin/sh' "cat <<$marker" > "$RUNNER"
# append the raw template contents (no expansion by parent shell)
cat "$TEMPLATE" >> "$RUNNER"
# ensure there is a trailing newline before marker (in case template doesn't end with newline)
printf '\n' >> "$RUNNER"
# close the heredoc marker
printf '%s\n' "$marker" >> "$RUNNER"
chmod +x "$RUNNER"

# run runner and capture output
if [ -n "${OUTFILE:-}" ]; then
  # write to a temp file in same dir then move into place (atomic-ish)
  dir=$(dirname -- "$OUTFILE")
  # ensure directory exists
  if [ ! -d "$dir" ]; then
    mkdir -p -- "$dir" || { echo "Error: cannot create directory: $dir" >&2; exit 1; }
  fi

  # REPLACED mktemp for output with portable unique filename in same dir
  base=".tmp.$(basename "$OUTFILE")"
  TMPOUT="$dir/${base}.$$"
  k=0
  while [ -e "$TMPOUT" ]; do
    k=$((k + 1))
    TMPOUT="$dir/${base}.$$.$k"
  done

  if sh "$RUNNER" > "$TMPOUT"; then
    mv "$TMPOUT" "$OUTFILE"
    rc=0
  else
    echo "Error: template expansion failed" >&2
    rm -f "$TMPOUT" 2>/dev/null || true
    rc=1
  fi
else
  if sh "$RUNNER"; then
    rc=0
  else
    rc=1
  fi
fi

# cleanup happens via trap
[ "$rc" -eq 0 ] || exit "$rc"

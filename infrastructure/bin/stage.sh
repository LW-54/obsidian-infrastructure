#!/bin/sh

# ==============================================================================
# stage.sh - Obsidian Staging Automation
#
# Description:
#   Automates the movement of notes from 01-STAGING to 03-ZETTELKASTEN based
#   on YAML frontmatter configuration.
#
# Usage:
#   ./stage.sh [--dry-run]
#
# Dependencies:
#   jq (1.6+)
# ==============================================================================

# Exit on error
set -e

# ------------------------------------------------------------------------------
# Constants & Configuration
# ------------------------------------------------------------------------------
LOG_FILE_REL="99-SYSTEM/logs/staging_logs.md"
CONFIG_FILE_REL="infrastructure/config/staging-workflow.md"
STAGING_DIR_REL="01-STAGING"
DRY_RUN=0

# Detect Vault Root
# If VAULT_ROOT is set, use it. Otherwise, assume we are in infrastructure/scripts
# and the vault root is two levels up.
if [ -z "$VAULT_ROOT" ]; then
    # Resolve absolute path to the directory containing this script
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    # Vault root is .../infrastructure/scripts/../../
    # Note: We use logical directory traversal for simplicity, assuming standard structure.
    # In a real environment, readlink -f might be safer but less portable to non-GNU.
    VAULT_ROOT="$SCRIPT_DIR/../.."
fi

# ------------------------------------------------------------------------------
# Functions
# ------------------------------------------------------------------------------

# check_dependencies
# Verifies that required tools are in the PATH.
check_dependencies() {
    if ! command -v jq >/dev/null 2>&1; then
        printf "ERROR: 'jq' is not installed or not in PATH.\n" >&2
        exit 1
    fi
}

# load_config
# Extracts the first JSON block from staging-workflow.md.
load_config() {
    config_md="$VAULT_ROOT/$CONFIG_FILE_REL"
    if [ ! -f "$config_md" ]; then
        log_message "ERROR" "Config file not found: $config_md"
        exit 1
    fi

    # Extract content between ```json and ```
    config_json=$(sed -n '/^```json$/,/^```$/p' "$config_md" | sed '1d;$d')
    
    if [ -z "$config_json" ]; then
        log_message "ERROR" "No JSON config block found in $config_md"
        exit 1
    fi

    if ! printf "%s" "$config_json" | jq . >/dev/null 2>&1; then
        log_message "ERROR" "Invalid JSON in $config_md"
        exit 1
    fi
    
    echo "$config_json"
}

# extract_frontmatter <file>
# Extracts YAML frontmatter from a markdown file.
extract_frontmatter() {
    file="$1"
    # Check if we have at least two --- lines
    count=$(grep -c "^---$" "$file" || true)
    if [ "$count" -lt 2 ]; then
        return
    fi
    # Extract lines between first and second ---
    # Using sed to get only the first block
    sed -n '/^---$/,/^---$/p' "$file" | sed '1d;$d'
}

# get_metadata <frontmatter_content>
# Converts flat YAML frontmatter to a JSON string for jq.
get_metadata() {
    fm_content="$1"
    if [ -z "$fm_content" ]; then
        printf "{}"
        return
    fi

    # Simple YAML-to-JSON conversion for flat Key: Value pairs
    printf "%s\n" "$fm_content" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | \
        sed -n 's/^\([^:]\{1,\}\):[[:space:]]*\(.*\)$/"\1": "\2"/p' | \
        paste -sd, - | \
        { printf "{"; cat; printf "}"; }
}

# validate_note <metadata_json> <fields_config_json>
# Returns a newline-separated list of validation errors.
validate_note() {
    _vn_metadata="$1"
    _vn_fields="$2"

    # 1. Mandatory id Check
    _vn_id=$(printf "%s" "$_vn_metadata" | jq -r '.id // empty')
    if [ -z "$_vn_id" ]; then
        printf "Missing mandatory field: id\n"
    fi

    # 2. Field Validation Loop
    # If fields is null or empty, skip loop
    if [ "$_vn_fields" != "null" ] && [ -n "$_vn_fields" ]; then
        printf "%s" "$_vn_fields" | jq -r 'keys_unsorted[]' | while read -r _vn_key; do
            [ -n "$_vn_key" ] || continue
            _vn_rule=$(printf "%s" "$_vn_fields" | jq -r --arg key "$_vn_key" '.[$key]')
            _vn_value=$(printf "%s" "$_vn_metadata" | jq -r --arg key "$_vn_key" '.[$key] // empty')

            if [ -z "$_vn_rule" ]; then
                # Existence check
                if [ -z "$_vn_value" ]; then
                    printf "Missing or empty required field: %s\n" "$_vn_key"
                fi
            else
                # Snippet validation
                if ! (
                    # Export metadata fields as variables
                    eval "$(printf "%s" "$_vn_metadata" | jq -r 'to_entries[] | "\(.key)=\"\(.value)\""')"
                    eval "$_vn_rule"
                ) >/dev/null 2>&1; then
                    printf "Validation snippet failed for %s: %s\n" "$_vn_key" "$_vn_rule"
                fi
            fi
        done
    fi
}

# inject_error <file> <error_message>
# Appends an error callout to the file after the frontmatter.
inject_error() {
    _ie_file="$1"
    _ie_msg="$2"
    
    # Create temp file for error message
    _ie_err_tmp=$(mktemp)
    printf "\n> [!WARNING] %s\n" "$_ie_msg" > "$_ie_err_tmp"
    
    # Use sed to insert content of _ie_err_tmp after the second ---
    # Strategy: Find line number of second ---, then use 'r' command
    # 1. Find line number of second ---
    _ie_line=$(grep -n "^---$" "$_ie_file" | sed -n '2s/:.*//p')
    
    if [ -n "$_ie_line" ]; then
        if [ "$DRY_RUN" -eq 1 ]; then
             log_message "INFO" "DRY RUN: Would inject error into $_ie_file at line $_ie_line: $_ie_msg"
        else
            # 2. Insert error message
            _ie_tmp=$(mktemp)
            sed "${_ie_line}r $_ie_err_tmp" "$_ie_file" > "$_ie_tmp" && mv "$_ie_tmp" "$_ie_file"
        fi
    else
        log_message "WARN" "Could not find end of frontmatter in $_ie_file. Appending error to end."
        if [ "$DRY_RUN" -eq 1 ]; then
             log_message "INFO" "DRY RUN: Would append error to $_ie_file: $_ie_msg"
        else
            cat "$_ie_err_tmp" >> "$_ie_file"
        fi
    fi
    
    rm -f "$_ie_err_tmp"
}

# log_message <level> <message>
# Appends a formatted log entry to the log file.
log_message() {
    level="$1"
    message="$2"
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    log_path="$VAULT_ROOT/$LOG_FILE_REL"

    # Ensure log directory exists
    log_dir="$(dirname "$log_path")"
    if [ ! -d "$log_dir" ]; then
        mkdir -p "$log_dir"
    fi

    # Append to log file
    # Format: [YYYY-MM-DD HH:MM:SS] [LEVEL] Message
    printf "[%s] [%s] %s\n" "$timestamp" "$level" "$message" >> "$log_path"

    # Also print to stdout for user feedback
    printf "[%s] [%s] %s\n" "$timestamp" "$level" "$message"
}

# parse_arguments
# Handles command line arguments.
parse_arguments() {
    for arg in "$@"; do
        case "$arg" in
            --dry-run)
                DRY_RUN=1
                ;;
            *)
                # Unknown argument, ignore
                ;;
        esac
    done
}

# process_file <file> <filename> <note_type> <match_config> <metadata_json>
# Handles validation, collision detection, and moving files.
process_file() {
    _pf_file="$1"
    _pf_filename="$2"
    _pf_type="$3"
    _pf_match="$4"
    _pf_metadata="$5"
    
    # 1. Validate
    _pf_fields_config=$(printf "%s" "$_pf_match" | jq -c '.fields // empty')
    _pf_errors=$(validate_note "$_pf_metadata" "$_pf_fields_config")
    
    _pf_destination=$(printf "%s" "$_pf_match" | jq -r '.destination // empty')
    
    if [ -z "$_pf_errors" ]; then
        # Valid so far. Check destination collision.
        if [ -n "$_pf_destination" ]; then
            _pf_dest_path="$VAULT_ROOT/$_pf_destination/$_pf_filename"
            if [ -e "$_pf_dest_path" ]; then
                _pf_errors="Collision: File already exists at destination $_pf_destination"
            fi
        else
             _pf_errors="Config Error: No destination defined for type $_pf_type"
        fi
    fi
    
    # 2. Act based on validity
    if [ -z "$_pf_errors" ]; then
        # SUCCESS PATH
        log_message "INFO" "Processing $_pf_filename: [PASS] -> $_pf_destination"
        if [ "$DRY_RUN" -eq 1 ]; then
            log_message "INFO" "DRY RUN: Would move $_pf_file to $VAULT_ROOT/$_pf_destination/"
        else
            mkdir -p "$VAULT_ROOT/$_pf_destination"
            mv "$_pf_file" "$VAULT_ROOT/$_pf_destination/"
        fi
        return 0
    else
        # FAILURE PATH
        # Log each error
        printf "%s\n" "$_pf_errors" | while read -r error; do
            [ -n "$error" ] || continue
            log_message "WARN" "Processing $_pf_filename: [FAIL] $error"
        done
        
        # Inject Error
        # Join errors with newlines for injection
        _pf_err_str=$(printf "%s" "$_pf_errors" | paste -sd "; " -)
        inject_error "$_pf_file" "Staging Failed: $_pf_err_str"
        
        # Move to Refactoring
        log_message "INFO" "Moving $_pf_filename to 02-REFACTORING"
        if [ "$DRY_RUN" -eq 1 ]; then
            log_message "INFO" "DRY RUN: Would move $_pf_file to $VAULT_ROOT/02-REFACTORING/"
        else
            mkdir -p "$VAULT_ROOT/02-REFACTORING"
            # Handle collision in Refactoring? Overwrite or rename? 
            # Simple mv overwrites. Let's assume overwrite or standard mv behavior is acceptable for MVP.
            mv "$_pf_file" "$VAULT_ROOT/02-REFACTORING/"
        fi
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Main Execution
# ------------------------------------------------------------------------------

main() {
    check_dependencies
    parse_arguments "$@"
    
    # Counters
    total_processed=0
    success_count=0
    failure_count=0

    if [ "$DRY_RUN" -eq 1 ]; then
        log_message "INFO" "Starting stage.sh in DRY RUN mode."
    else
        log_message "INFO" "Starting stage.sh execution."
    fi

    log_message "INFO" "Vault Root detected at: $VAULT_ROOT"

    # 1. Load Configuration
    config_json=$(load_config)
    
    # 2. Iterate through 01-STAGING
    staging_dir="$VAULT_ROOT/$STAGING_DIR_REL"
    if [ ! -d "$staging_dir" ]; then
        log_message "ERROR" "Staging directory not found: $staging_dir"
        exit 1
    fi

    # Check if there are any .md files
    # We use a loop that handles spaces in filenames
    count=0
    # Use find to avoid issues with empty directory globbing or too many files
    # But for POSIX sh, a simple loop is often enough if we check for existence.
    for file in "$staging_dir"/*.md; do
        # Handle case where no files match the glob
        [ -e "$file" ] || continue
        
        filename=$(basename "$file")
        count=$((count + 1))
        
        # 3. Extract metadata
        fm=$(extract_frontmatter "$file")
        metadata_json=$(get_metadata "$fm")
        
        # 4. Identify Type
        note_type=$(printf "%s" "$metadata_json" | jq -r '.Type // empty')
        
        if [ -z "$note_type" ]; then
            log_message "WARN" "Processing $filename: No Type found."
            # Treat as failure -> Move to Refactoring
            inject_error "$file" "Staging Failed: No Type found in frontmatter"
            if [ "$DRY_RUN" -eq 0 ]; then
                mkdir -p "$VAULT_ROOT/02-REFACTORING"
                mv "$file" "$VAULT_ROOT/02-REFACTORING/"
            fi
            failure_count=$((failure_count + 1))
            continue
        fi

        # 5. Match against config
        match=$(printf "%s" "$config_json" | jq -r --arg type "$note_type" '.[$type] // empty')
        
        if [ -n "$match" ]; then
             if process_file "$file" "$filename" "$note_type" "$match" "$metadata_json"; then
                success_count=$((success_count + 1))
             else
                failure_count=$((failure_count + 1))
             fi
        else
            log_message "WARN" "Processing $filename: Type '$note_type' [NO_MATCH]"
            # No match -> Refactoring
            inject_error "$file" "Staging Failed: Type '$note_type' not defined in workflow config"
            if [ "$DRY_RUN" -eq 0 ]; then
                mkdir -p "$VAULT_ROOT/02-REFACTORING"
                mv "$file" "$VAULT_ROOT/02-REFACTORING/"
            fi
            failure_count=$((failure_count + 1))
        fi
        
        total_processed=$((total_processed + 1))
    done

    if [ "$count" -eq 0 ]; then
        log_message "INFO" "No files found in $STAGING_DIR_REL."
    else
        log_message "INFO" "Finished processing. Total: $count, Success: $success_count, Failure: $failure_count."
    fi
}

# Invoke main with all arguments
main "$@"

# Staging Workflow Guide

This guide explains how to configure and use the `stage.sh` script to automate your Obsidian note staging process.

## 1. Introduction

The `stage.sh` script is a POSIX-compliant shell script that reads notes from your `01-STAGING` directory, validates them based on a set of rules you define, and moves them to the appropriate location in your Zettelkasten (`03-ZETTELKASTEN`).

## 2. Configuration (`staging-workflow.md`)

The entire workflow is controlled by a JSON block inside `99-SYSTEM/infrastructure/staging-workflow.md`.

### JSON Schema

The root of the JSON object contains keys that correspond to the `Type` you set in your notes' YAML frontmatter.

```json
{
  "TypeName1": { ... },
  "TypeName2": { ... }
}
```

#### Type Object

Each `Type` object has two main properties:

- `destination` (string, required): The path relative to your vault root where valid notes of this type should be moved.
- `fields` (object, optional): An object defining the validation rules for the frontmatter fields.

**Example:**

```json
"Idea": {
  "destination": "03-ZETTELKASTEN/Ideas",
  "fields": { ... }
}
```

#### Fields Object (Validation Rules)

The `fields` object contains key-value pairs where the key is the frontmatter field to validate, and the value is the validation rule.

There are two types of rules:

**1. Existence-Only Check (`""`)**

If the rule is an empty string, the script simply checks that the field exists in the frontmatter and is **not empty**.

**Example:**
This rule requires a `Topic` field that has some content.
```json
"fields": {
  "Topic": ""
}
```

**2. Snippet Validation (string)**

If the rule is a non-empty string, it is treated as a **POSIX `sh` command snippet** that will be executed to determine validity.
- The script must exit with a status code of `0` (success) for the validation to pass.
- Any non-zero exit code is a failure.
- All frontmatter fields are available as shell variables (e.g., `Topic` is available as `$Topic`).

**Example Snippets:**

- **Check for a specific value:** This rule passes only if the `Status` is "Active".
  ```json
  "fields": {
    "Status": "[ \"$Status\" = \"Active\" ]"
  }
  ```
  *(Note: The `[ ... ]` is standard POSIX `sh` syntax for a test command.)*

- **Check for one of several values:**
  ```json
  "fields": {
    "Priority": "[ \"$Priority\" = \"High\" ] || [ \"$Priority\" = \"Medium\" ]"
  }
  ```

- **Check string length:** This rule passes if the `Topic` is longer than 5 characters.
  ```json
  "fields": {
    "Topic": "[ ${#Topic} -gt 5 ]"
  }
  ```

- **Check a date format (YYYY-MM-DD) using `grep`:**
  ```json
  "fields": {
    "Date": "echo \"$Date\" | grep -Eq \"^[0-9]{4}-[0-9]{2}-[0-9]{2}$\""
  }
  ```

## 3. Usage

To run the script, open a terminal (like `a-shell` on iOS) and execute it.

```sh
# Navigate to the scripts directory
cd misc/obsidian/infrastructure/scripts/

# Run the script
./stage.sh
```

### Dry Run Mode

It is **highly recommended** to first run the script with the `--dry-run` flag. This will simulate all operations (validation, moves) and log the intended actions without actually moving or modifying any files.

```sh
./stage.sh --dry-run
```

## 4. Troubleshooting

- **`ERROR: 'jq' is not installed or not in PATH.`**: The script requires the `jq` command-line JSON processor. Please install it on your system.
- **`[FAIL] Invalid JSON in ...`**: The JSON block in your `staging-workflow.md` has a syntax error. Use a JSON validator to check for missing commas, brackets, or quotes.
- **`[FAIL] Staging Failed: No Type found in frontmatter`**: A note in `01-STAGING` is missing the `Type:` field in its YAML frontmatter.
- **`[FAIL] Staging Failed: Type '...' not defined in workflow config`**: The `Type` in a note does not have a corresponding entry in your `staging-workflow.md` JSON.
- **`[FAIL] Validation snippet failed for ...`**: The shell command snippet for a field returned a non-zero exit code, meaning the validation failed. Check the logic of your snippet.

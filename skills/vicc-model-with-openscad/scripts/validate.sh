#!/bin/bash
# Validate an OpenSCAD file for syntax errors and warnings
# Usage: validate.sh input.scad

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

check_openscad

if [ $# -lt 1 ]; then
    echo "Usage: $0 input.scad"
    exit 1
fi

INPUT="$1"

if [ ! -f "$INPUT" ]; then
    echo "Error: File not found: $INPUT"
    exit 1
fi

echo "Validating: $INPUT"

# Give each invocation its own echo file, including when runs overlap.
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/openscad_validate.XXXXXX")
TEMP_OUTPUT="$TEMP_DIR/output.echo"
trap 'rm -f "$TEMP_OUTPUT"; rmdir "$TEMP_DIR"' EXIT
: > "$TEMP_OUTPUT"

# Echo export evaluates the model without rendering. Some OpenSCAD versions
# write warnings to the echo file and return success, even with --hardwarnings.
exit_status=0
diagnostics=$("$OPENSCAD" -o "$TEMP_OUTPUT" --export-format=echo "$INPUT" 2>&1) || exit_status=$?
if [ -n "$diagnostics" ]; then
    printf '%s\n' "$diagnostics"
fi
if [ -s "$TEMP_OUTPUT" ]; then
    cat "$TEMP_OUTPUT"
fi

if [ "$exit_status" -ne 0 ] ||
   grep -Eq '^(WARNING|ERROR):' "$TEMP_OUTPUT" ||
   grep -Eq '^(WARNING|ERROR):' <<< "$diagnostics"; then
    echo "Validation failed" >&2
    exit 1
fi

echo "Syntax OK"

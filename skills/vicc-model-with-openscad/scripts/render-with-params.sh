#!/bin/bash
# Render OpenSCAD with parameters from a JSON file
# Usage: render-with-params.sh input.scad params.json output.stl|output.png

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

check_openscad

if [ $# -lt 3 ]; then
    echo "Usage: $0 input.scad params.json output.[stl|png]"
    echo ""
    echo "params.json format:"
    echo '  {"width": 60, "height": 40, "include_lid": true}'
    exit 1
fi

INPUT="$1"
PARAMS_FILE="$2"
OUTPUT="$3"

if [ ! -f "$INPUT" ]; then
    echo "Error: Input file not found: $INPUT"
    exit 1
fi

if [ ! -f "$PARAMS_FILE" ]; then
    echo "Error: Params file not found: $PARAMS_FILE"
    exit 1
fi

# Build -D arguments from JSON. Keep the path and JSON values as data by passing
# the filename through argv instead of interpolating it into Python source.
if ! command -v python3 &> /dev/null; then
    echo "Error: Requires python3 to parse JSON parameters safely"
    exit 1
fi

PARAM_LINES=$(python3 - "$PARAMS_FILE" <<'PY'
import json
import math
import re
import sys

identifier = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")

def openscad_literal(value):
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, int) and not isinstance(value, bool):
        return str(value)
    if isinstance(value, float):
        if not math.isfinite(value):
            raise ValueError("numbers must be finite")
        return repr(value)
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, list):
        return "[" + ", ".join(openscad_literal(item) for item in value) + "]"
    if value is None:
        return "undef"
    raise TypeError(f"unsupported parameter value type: {type(value).__name__}")

with open(sys.argv[1], "r", encoding="utf-8") as file:
    params = json.load(file)

if not isinstance(params, dict):
    raise SystemExit("params JSON must be an object")

for key, value in params.items():
    if not identifier.fullmatch(key):
        raise SystemExit(f"invalid OpenSCAD parameter name: {key!r}")
    print(f"{key}={openscad_literal(value)}")
PY
)

DEFINES=()
while IFS= read -r line; do
    if [ -n "$line" ]; then
        DEFINES+=("-D" "$line")
    fi
done <<< "$PARAM_LINES"

echo "Rendering with parameters from: $PARAMS_FILE"
if [ ${#DEFINES[@]} -gt 0 ]; then
    echo "Parameters: ${DEFINES[*]}"
fi

# Determine output type and set appropriate options
EXT="${OUTPUT##*.}"
mkdir -p "$(dirname "$OUTPUT")"
case "$EXT" in
    stl|STL)
        "$OPENSCAD" "${DEFINES[@]}" -o "$OUTPUT" "$INPUT"
        ;;
    png|PNG)
        "$OPENSCAD" "${DEFINES[@]}" \
            --camera="0,0,0,55,0,25,0" \
            --imgsize="800,600" \
            --colorscheme="Tomorrow Night" \
            --autocenter --viewall \
            -o "$OUTPUT" "$INPUT"
        ;;
    *)
        echo "Unsupported output format: $EXT"
        echo "Supported: stl, png"
        exit 1
        ;;
esac

echo "Output saved: $OUTPUT"

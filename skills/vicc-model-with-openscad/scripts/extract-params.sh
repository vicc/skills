#!/bin/bash
# Extract customizable parameters from an OpenSCAD file
# Usage: extract-params.sh input.scad [--json]
#
# Parses parameter declarations with special comments:
#   param = value;           // [min:max] Description
#   param = value;           // [min:step:max] Description
#   param = value;           // [opt1, opt2] Description
#   param = value;           // Description only

set -eo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 input.scad [--json]"
    exit 1
fi

INPUT="$1"
JSON_OUTPUT=false

if [ "$2" = "--json" ]; then
    JSON_OUTPUT=true
fi

if [ ! -f "$INPUT" ]; then
    echo "Error: File not found: $INPUT"
    exit 1
fi

python3 - "$INPUT" "$JSON_OUTPUT" <<'PY'
import json
import re
import sys

filename = sys.argv[1]
json_output = sys.argv[2] == "true"
params = []
block_depth = 0
quoted = r'"(?:\\.|[^"\\])*"'
comment_or_string = re.compile(
    rf'(?P<block_comment>/\*.*?(?:\*/|\Z))|//[^\n]*|{quoted}',
    re.DOTALL,
)
assignment = re.compile(
    rf'^\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*((?:{quoted}|[^";])+);\s*(?://\s*(.*))?'
)


def blank_token(match):
    return re.sub(r"[^\n]", " ", match.group())

with open(filename, "r", encoding="utf-8") as file:
    source = file.read()
    # Mask multiline comments in the source while preserving line comments for
    # Customizer metadata. In the structure, mask strings and all comments.
    source = comment_or_string.sub(
        lambda match: blank_token(match) if match.lastgroup == "block_comment" else match.group(),
        source,
    )
    structure = comment_or_string.sub(blank_token, source)
    for line, structural_line in zip(source.split("\n"), structure.split("\n")):
        at_top_level = block_depth == 0
        block_depth += structural_line.count("{") - structural_line.count("}")
        if not at_top_level or not structural_line.strip():
            continue

        match = assignment.match(line)
        if not match:
            continue

        name = match.group(1)
        value = match.group(2).strip()
        comment = match.group(3) or ""

        if value in ("true", "false"):
            value_type = "boolean"
        elif re.match(r"^-?\d+$", value):
            value_type = "integer"
        elif re.match(r"^-?\d*\.?\d+$", value):
            value_type = "number"
        elif value.startswith('"') and value.endswith('"'):
            value_type = "string"
            value = value[1:-1]
        elif value.startswith("["):
            value_type = "array"
        else:
            value_type = "expression"

        range_value = ""
        options_value = ""
        description = comment
        range_match = re.match(r"\[([^\]]+)\]\s*(.*)", comment)
        if range_match:
            bracket_content = range_match.group(1)
            description = range_match.group(2)
            if ":" in bracket_content and "," not in bracket_content:
                range_value = bracket_content
            else:
                options_value = bracket_content

        item = {
            "name": name,
            "value": value,
            "type": value_type,
        }
        if range_value:
            item["range"] = range_value
        if options_value:
            item["options"] = options_value
        if description:
            item["description"] = description
        params.append(item)

if json_output:
    print(json.dumps(params, indent=2))
else:
    print(f"Parameters in: {filename}")
    print("===============================================")
    print(f"{'NAME':<20} {'VALUE':<15} {'TYPE':<10} CONSTRAINT/DESC")
    print("-----------------------------------------------")
    for item in params:
        constraint = ""
        if "range" in item:
            constraint = f"[{item['range']}]"
        elif "options" in item:
            constraint = f"[{item['options']}]"
        if "description" in item:
            constraint = f"{constraint} {item['description']}".strip()
        print(f"{item['name']:<20} {item['value']:<15} {item['type']:<10} {constraint}")
PY

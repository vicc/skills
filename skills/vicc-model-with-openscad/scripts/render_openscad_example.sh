#!/usr/bin/env bash
set -euo pipefail

skill_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
scad_file="$skill_dir/assets/cad/mechanical_connectors.scad"
out_file="${1:-$skill_dir/assets/cad/mechanical_connectors_example.stl}"
example_name="${2:-showcase}"

if ! command -v openscad >/dev/null 2>&1; then
  echo "openscad is not installed; static validation only."
  exit 2
fi

openscad -D "example=\"$example_name\"" -o "$out_file" "$scad_file"
echo "Rendered $example_name to $out_file"

#!/bin/bash
# Rebuild real GPU captures and labeled comparisons. Requires macOS + Xcode + Python 3.
set -euo pipefail
example_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="$example_root/.build"
host_arch="$(uname -m)"
mkdir -p "$build_dir"
for dependency in xcrun python3; do
  command -v "$dependency" >/dev/null || { echo "Missing required command: $dependency" >&2; exit 1; }
done

python3 "$example_root/tools/make-inputs.py"
xcrun clang++ -std=c++17 -fobjc-arc -mmacosx-version-min=14.0 \
  "$example_root/tools/render-glsl.mm" -framework OpenGL -framework Foundation \
  -framework CoreGraphics -framework ImageIO -o "$build_dir/render-glsl"
xcrun swiftc -target "$host_arch-apple-macos14.0" "$example_root/tools/render-metal.swift" -o "$build_dir/render-metal"
xcrun swiftc -target "$host_arch-apple-macos14.0" "$example_root/tools/compare.swift" -o "$build_dir/compare"

for slug in aurora-ribbons ripple-distortion two-texture-blend; do
  example_dir="$example_root/$slug"
  capture_args=(--width 640 --height 400 --time 1.25)
  case "$slug" in
    aurora-ribbons) title="Aurora ribbons" ;;
    ripple-distortion) title="Ripple distortion"; capture_args+=(--texture0 "$example_root/assets/grid.png") ;;
    two-texture-blend) title="Two-texture blend"; capture_args+=(--texture0 "$example_root/assets/grid.png" --texture1 "$example_root/assets/stripes.png") ;;
  esac
  xcrun -sdk macosx metal -std=metal3.1 -mmacosx-version-min=14.0 -DCOMPARISON_CAPTURE=1 \
    -c "$example_dir/effect.metal" -o "$build_dir/$slug.air"
  xcrun -sdk macosx metallib "$build_dir/$slug.air" -o "$build_dir/$slug.metallib"
  "$build_dir/render-glsl" "$example_dir/effect.glsl" "$example_dir/glsl.png" \
    "${capture_args[@]}" > "$build_dir/$slug-glsl.log" 2>&1
  "$build_dir/render-metal" --library "$build_dir/$slug.metallib" --output "$example_dir/metal.png" \
    "${capture_args[@]}" > "$build_dir/$slug-metal.json"
  "$build_dir/compare" "$example_dir/glsl.png" "$example_dir/metal.png" \
    "$example_dir/comparison.png" "$example_dir/metrics.json" --title "$title"
done
python3 "$example_root/tools/record-capture.py"
printf 'Captures regenerated. Review PNGs and metrics before committing.\n'

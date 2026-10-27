#!/bin/bash
# Rebuild real GPU captures and labeled comparisons. Requires macOS + Xcode + Python 3.
set -euo pipefail
example_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="$example_root/.build"
host_arch="$(uname -m)"
mkdir -p "$build_dir/tool-module-cache"
for dependency in xcrun python3; do
  command -v "$dependency" >/dev/null || { echo "Missing required command: $dependency" >&2; exit 1; }
done

python3 "$example_root/tools/make-inputs.py"
xcrun clang++ -std=c++17 -fobjc-arc -mmacosx-version-min=14.0 \
  "$example_root/tools/render-glsl.mm" -framework OpenGL -framework Foundation \
  -framework CoreGraphics -framework ImageIO -o "$build_dir/render-glsl"
xcrun swiftc -module-cache-path "$build_dir/tool-module-cache" -target "$host_arch-apple-macos14.0" "$example_root/tools/render-metal.swift" -o "$build_dir/render-metal"
xcrun swiftc -module-cache-path "$build_dir/tool-module-cache" -target "$host_arch-apple-macos14.0" "$example_root/tools/compare.swift" -o "$build_dir/compare"

# The same production entry point is used in every capture. Compiler settings and
# optional diagnostic defines are recorded from the exact arguments used here.
capture_metal() {
  local slug="$1" suffix="$2" mode="$3" functions="$4"
  shift 4
  local name="$slug$suffix"
  local flags=(-std=metal3.1 -mmacosx-version-min=14.0 -DCOMPARISON_CAPTURE=1
    "-fmetal-math-mode=$mode" "-fmetal-math-fp32-functions=$functions" "$@")
  xcrun -sdk macosx metal "${flags[@]}" -c "$example_root/$slug/effect.metal" -o "$build_dir/$name.air"
  xcrun -sdk macosx metallib "$build_dir/$name.air" -o "$build_dir/$name.metallib"
  "$build_dir/render-metal" --library "$build_dir/$name.metallib" \
    --output "$example_root/$slug/metal$suffix.png" "${capture_args[@]}" > "$build_dir/$name-metal.json"
  python3 - "$build_dir/$name-compile.json" "${flags[@]}" <<'PYFLAGS'
import json, sys
from pathlib import Path
Path(sys.argv[1]).write_text(json.dumps({"metalCompilerFlags": sys.argv[2:]}, indent=2) + "\n")
PYFLAGS
}

for slug in aurora-ribbons ripple-distortion two-texture-blend negative-modulo noise-hash; do
  example_dir="$example_root/$slug"
  capture_args=(--width 640 --height 400 --time 1.25)
  right_label="Metal · offscreen"
  math_mode=fast
  math_functions=fast
  case "$slug" in
    aurora-ribbons) title="Aurora ribbons" ;;
    ripple-distortion) title="Ripple distortion"; capture_args+=(--texture0 "$example_root/assets/grid.png") ;;
    two-texture-blend) title="Two-texture blend"; capture_args+=(--texture0 "$example_root/assets/grid.png" --texture1 "$example_root/assets/stripes.png") ;;
    negative-modulo) title="Negative modulo: preserve the repeat"; right_label="Metal · floor-based modulo"; math_mode=safe; math_functions=precise ;;
    noise-hash) title="Sine hash: checking fast math"; right_label="Metal · fast math + fast functions" ;;
  esac
  "$build_dir/render-glsl" "$example_dir/effect.glsl" "$example_dir/glsl.png" \
    "${capture_args[@]}" > "$build_dir/$slug-glsl.log" 2>&1
  capture_metal "$slug" "" "$math_mode" "$math_functions"
  "$build_dir/compare" "$example_dir/glsl.png" "$example_dir/metal.png" \
    "$example_dir/comparison.png" "$example_dir/metrics.json" --title "$title" --right-label "$right_label"
done

# An intentionally incorrect translation, kept out of normal app builds.
capture_args=(--width 640 --height 400 --time 1.25)
capture_metal negative-modulo -fmod safe precise -DMODULO_USE_FMOD=1
"$build_dir/compare" "$example_root/negative-modulo/glsl.png" "$example_root/negative-modulo/metal-fmod.png" \
  "$example_root/negative-modulo/fmod-comparison.png" "$example_root/negative-modulo/fmod-metrics.json" \
  --title "Negative modulo: the fmod trap" --right-label "Metal · fmod (intentionally incorrect)"

# Same sine hash and inputs, changing both Metal math controls explicitly.
capture_metal noise-hash -precise safe precise
"$build_dir/compare" "$example_root/noise-hash/glsl.png" "$example_root/noise-hash/metal-precise.png" \
  "$example_root/noise-hash/precise-comparison.png" "$example_root/noise-hash/precise-metrics.json" \
  --title "Sine hash: checking safe + precise math" --right-label "Metal · safe math + precise functions"

# A deliberately different algorithm as a control, applied to BOTH backends.
{ printf '#define NOISE_INTEGER_HASH 1\n'; cat "$example_root/noise-hash/effect.glsl"; } > "$build_dir/noise-hash-integer.glsl"
"$build_dir/render-glsl" "$build_dir/noise-hash-integer.glsl" "$example_root/noise-hash/glsl-integer.png" \
  "${capture_args[@]}" > "$build_dir/noise-hash-integer-glsl.log" 2>&1
capture_metal noise-hash -integer fast fast -DNOISE_INTEGER_HASH=1
"$build_dir/compare" "$example_root/noise-hash/glsl-integer.png" "$example_root/noise-hash/metal-integer.png" \
  "$example_root/noise-hash/integer-comparison.png" "$example_root/noise-hash/integer-metrics.json" \
  --title "Integer hash control: a different pattern" \
  --left-label "GLSL · integer hash" --right-label "Metal · integer hash, fast math"

# Keep baseline matches visible, and test additional finite seeds in portrait.
# Large-seed images are published; all probe measurements are saved in capture.json.
for seed in 0 17 4095; do
  capture_args=(--width 400 --height 640 --time "$seed")
  glsl_output="$build_dir/noise-probe-$seed-glsl.png"
  if [ "$seed" = 4095 ]; then glsl_output="$example_root/noise-hash/large-seed-glsl.png"; fi
  "$build_dir/render-glsl" "$example_root/noise-hash/effect.glsl" "$glsl_output" \
    "${capture_args[@]}" > "$build_dir/noise-probe-$seed-glsl.log" 2>&1
  for mode in fast precise; do
    library="$build_dir/noise-hash.metallib"
    if [ "$mode" = precise ]; then library="$build_dir/noise-hash-precise.metallib"; fi
    output="$build_dir/noise-probe-$seed-$mode.png"
    comparison="$build_dir/noise-probe-$seed-$mode-comparison.png"
    metrics="$build_dir/noise-probe-$seed-$mode-metrics.json"
    if [ "$seed" = 4095 ]; then
      output="$example_root/noise-hash/metal-large-seed-$mode.png"
      comparison="$example_root/noise-hash/large-seed-$mode-comparison.png"
      metrics="$example_root/noise-hash/large-seed-$mode-metrics.json"
    fi
    "$build_dir/render-metal" --library "$library" --output "$output" \
      "${capture_args[@]}" > "$build_dir/noise-probe-$seed-$mode.json"
    "$build_dir/compare" "$glsl_output" "$output" "$comparison" "$metrics" \
      --title "Sine hash: seed $seed, $mode math" --right-label "Metal · $mode configuration"
  done
done

# Confirm the integer control at the same large seed as well.
"$build_dir/render-glsl" "$build_dir/noise-hash-integer.glsl" "$example_root/noise-hash/large-seed-integer-glsl.png" \
  "${capture_args[@]}" > "$build_dir/noise-probe-4095-integer-glsl.log" 2>&1
"$build_dir/render-metal" --library "$build_dir/noise-hash-integer.metallib" \
  --output "$example_root/noise-hash/metal-large-seed-integer.png" "${capture_args[@]}" > "$build_dir/noise-probe-4095-integer.json"
"$build_dir/compare" "$example_root/noise-hash/large-seed-integer-glsl.png" "$example_root/noise-hash/metal-large-seed-integer.png" \
  "$example_root/noise-hash/large-seed-integer-comparison.png" "$example_root/noise-hash/large-seed-integer-metrics.json" \
  --title "Integer control: seed 4095" --left-label "GLSL · integer hash" --right-label "Metal · integer hash, fast math"

python3 "$example_root/tools/check-math-captures.py"
python3 "$example_root/tools/record-capture.py"
printf 'Captures regenerated. Review PNGs and metrics before committing.\n'

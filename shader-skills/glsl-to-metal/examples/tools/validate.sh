#!/bin/bash
# Compile the actual app-facing Swift and Metal at the declared minimum targets.
set -euo pipefail
example_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="$example_root/.build"
mkdir -p "$build_dir/production-module-cache" "$build_dir/tool-module-cache"
for sdk in macosx iphoneos; do
  sdk_path="$(xcrun --sdk "$sdk" --show-sdk-path)"
  if [ "$sdk" = macosx ]; then
    target=arm64-apple-macos14.0
    metal_min=-mmacosx-version-min=14.0
  else
    target=arm64-apple-ios17.0
    metal_min=-mios-version-min=17.0
  fi
  xcrun swiftc -swift-version 6 -parse-as-library -whole-module-optimization \
    -emit-module -emit-object -module-name ShaderExamples \
    -module-cache-path "$build_dir/production-module-cache" -target "$target" -sdk "$sdk_path" \
    "$example_root/SwiftUIExamples.swift" "$example_root/two-texture-blend/TwoTextureBlendView.swift" \
    -o "$build_dir/ShaderExamples-$sdk.o" -emit-module-path "$build_dir/ShaderExamples-$sdk.swiftmodule"
  shader_objects=()
  for slug in aurora-ribbons ripple-distortion two-texture-blend negative-modulo noise-hash; do
    shader_object="$build_dir/production-$sdk-$slug.air"
    xcrun -sdk "$sdk" metal -std=metal3.1 "$metal_min" -c "$example_root/$slug/effect.metal" -o "$shader_object"
    shader_objects+=("$shader_object")
  done
  xcrun -sdk "$sdk" metallib "${shader_objects[@]}" -o "$build_dir/production-$sdk.metallib"
  printf 'PASS: Swift 6 + Metal 3.1 compiled and linked for %s.\n' "$target"
done
host_arch="$(uname -m)"
xcrun swiftc -module-cache-path "$build_dir/tool-module-cache" -parse-as-library -target "$host_arch-apple-macos14.0" \
  "$example_root/tools/check-bindings.swift" -o "$build_dir/check-bindings"
"$build_dir/check-bindings" "$build_dir/production-macosx.metallib"
printf 'Compilation is not minimum-OS execution or UI validation.\n'

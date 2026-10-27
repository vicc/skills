#!/usr/bin/env python3
"""Record capture conditions and hashes without personal paths or machine names."""
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import platform
import subprocess

root = Path(__file__).resolve().parent.parent
slugs = ["aurora-ribbons", "ripple-distortion", "two-texture-blend", "negative-modulo", "noise-hash"]

def command(*args):
    return subprocess.check_output(args, text=True, stderr=subprocess.STDOUT).strip()

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

glsl_lines = (root / ".build/aurora-ribbons-glsl.log").read_text().splitlines()
metal = json.loads((root / ".build/aurora-ribbons-metal.json").read_text())
report = {
    "capturedAtUTC": datetime.now(timezone.utc).isoformat(),
    "method": "Native GLSL/OpenGL and offscreen Metal GPU renders; not SwiftUI window screenshots",
    "size": [640, 400], "timeSeconds": 1.25, "userSpaceUnitsPerPixel": 1,
    "format": "RGBA8 UNORM; no blending, MSAA, dithering, or sRGB texture decoding",
    "textureSampling": "Normalized coordinates, linear filtering, clamp-to-edge, no mipmaps, top row v=0",
    "os": command("sw_vers", "-productVersion"),
    "osBuild": command("sw_vers", "-buildVersion"),
    "architecture": platform.machine(),
    "gpu": metal["device"],
    "openGL": next(line.split(": ", 1)[1] for line in glsl_lines if line.startswith("OpenGL: ")),
    "glslDriver": next(line.split(": ", 1)[1] for line in glsl_lines if line.startswith("GLSL: ")),
    "sourceLanguages": {"GLSL": "330 core", "Metal": "3.1"},
    "xcode": command("xcodebuild", "-version").splitlines(),
    "swift": command("xcrun", "swiftc", "--version").splitlines()[:1],
    "metalCompiler": command("xcrun", "-sdk", "macosx", "metal", "--version").splitlines()[:1],
    "sdkVersions": {sdk: command("xcrun", "--sdk", sdk, "--show-sdk-version") for sdk in ["macosx", "iphoneos"]},
    "examples": {},
    "sharedSourceSHA256": {},
}
def compilation(name):
    return json.loads((root / ".build" / f"{name}-compile.json").read_text())

for slug in slugs:
    report["examples"][slug] = {
        "metrics": json.loads((root / slug / "metrics.json").read_text()),
        **compilation(slug),
        "capture": json.loads((root / ".build" / f"{slug}-metal.json").read_text()),
        "sha256": {
            path.name: digest(path) for path in sorted((root / slug).iterdir())
            if path.suffix in {".glsl", ".metal", ".png", ".json"}
        },
    }

# These pairs test known hazards rather than promising pixel parity. In the
# integer control, BOTH languages use a deliberately different hash algorithm.
variants = {
    "negative-modulo": {
        "fmod": ("glsl.png", "metal-fmod.png", "Intentionally incorrect fmod translation", []),
    },
    "noise-hash": {
        "precise": ("glsl.png", "metal-precise.png", "Same sine hash, safe arithmetic and precise FP32 functions", []),
        "integer": ("glsl-integer.png", "metal-integer.png", "Different integer hash algorithm in both languages", ["NOISE_INTEGER_HASH=1"]),
    },
}
for slug, settings in variants.items():
    report["examples"][slug]["variants"] = {}
    for variant, (left, right, purpose, glsl_defines) in settings.items():
        report["examples"][slug]["variants"][variant] = {
            "leftImage": left, "rightImage": right,
            "comparisonImage": f"{variant}-comparison.png",
            "purpose": purpose, "glslDefines": glsl_defines,
            **compilation(f"{slug}-{variant}"),
            "metrics": json.loads((root / slug / f"{variant}-metrics.json").read_text()),
        }
report["additionalChecks"] = []
for seed in [0, 17, 4095]:
    for mode in ["fast", "precise"]:
        public = seed == 4095
        base = root / "noise-hash" if public else root / ".build"
        metrics_path = base / (f"large-seed-{mode}-metrics.json" if public else f"noise-probe-{seed}-{mode}-metrics.json")
        left = base / ("large-seed-glsl.png" if public else f"noise-probe-{seed}-glsl.png")
        right = base / (f"metal-large-seed-{mode}.png" if public else f"noise-probe-{seed}-{mode}.png")
        name = "noise-hash" if mode == "fast" else "noise-hash-precise"
        report["additionalChecks"].append({
            "example": "noise-hash", "algorithm": "sine hash", "configuration": mode,
            "capture": json.loads((root / ".build" / f"noise-probe-{seed}-{mode}.json").read_text()),
            **compilation(name), "metrics": json.loads(metrics_path.read_text()),
            "leftImageSHA256": digest(left), "rightImageSHA256": digest(right),
            "publishedComparison": f"noise-hash/large-seed-{mode}-comparison.png" if public else None,
        })
report["additionalChecks"].append({
    "example": "noise-hash", "algorithm": "integer hash control", "configuration": "fast",
    "glslDefines": ["NOISE_INTEGER_HASH=1"],
    "capture": json.loads((root / ".build/noise-probe-4095-integer.json").read_text()),
    **compilation("noise-hash-integer"),
    "metrics": json.loads((root / "noise-hash/large-seed-integer-metrics.json").read_text()),
    "leftImageSHA256": digest(root / "noise-hash/large-seed-integer-glsl.png"),
    "rightImageSHA256": digest(root / "noise-hash/metal-large-seed-integer.png"),
    "publishedComparison": "noise-hash/large-seed-integer-comparison.png",
})
for base in [root / "assets", root / "tools"]:
    for path in sorted(base.rglob("*")):
        if path.is_file() and "__pycache__" not in path.parts:
            report["sharedSourceSHA256"][str(path.relative_to(root))] = digest(path)
(root / "capture.json").write_text(json.dumps(report, indent=2) + "\n")
print("Recorded capture.json (conditions, source hashes, and measured differences).")

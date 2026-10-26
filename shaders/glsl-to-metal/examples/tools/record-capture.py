#!/usr/bin/env python3
"""Record capture conditions and hashes without personal paths or machine names."""
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import platform
import subprocess

root = Path(__file__).resolve().parent.parent
slugs = ["aurora-ribbons", "ripple-distortion", "two-texture-blend"]

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
for slug in slugs:
    report["examples"][slug] = {
        "metrics": json.loads((root / slug / "metrics.json").read_text()),
        "sha256": {name: digest(root / slug / name) for name in ["effect.glsl", "effect.metal", "glsl.png", "metal.png", "comparison.png"]},
    }
for base in [root / "assets", root / "tools"]:
    for path in sorted(base.rglob("*")):
        if path.is_file():
            report["sharedSourceSHA256"][str(path.relative_to(root))] = digest(path)
(root / "capture.json").write_text(json.dumps(report, indent=2) + "\n")
print("Recorded capture.json (conditions, source hashes, and measured differences).")

#!/usr/bin/env python3
"""Check the rendered math examples without treating sine hashes as portable goldens."""
import json
import math
from pathlib import Path

root = Path(__file__).resolve().parent.parent

def metrics(slug, name="metrics.json", size=(640, 400)):
    path = root / slug / name
    result = json.loads(path.read_text())
    if (result["width"], result["height"]) != size:
        raise SystemExit(f"Unexpected capture dimensions: {path}")
    for key in ["meanAbsoluteRGBError", "rootMeanSquareRGBError", "maxRGBError"]:
        if not math.isfinite(result[key]) or not 0 <= result[key] <= 255:
            raise SystemExit(f"Invalid {key}: {path}")
    if result["maxAlphaError"] != 0:
        raise SystemExit(f"Opaque output alpha differs: {path}")
    return result

correct = metrics("negative-modulo")
wrong = metrics("negative-modulo", "fmod-metrics.json")
if correct["maxRGBError"] > 1:
    raise SystemExit("Correct floor-based modulo exceeds the 1/255 RGB comparison bound.")
if wrong["meanAbsoluteRGBError"] <= correct["meanAbsoluteRGBError"] + 1:
    raise SystemExit("The fmod diagnostic failed to expose the negative-coordinate regression.")
integer = metrics("noise-hash", "integer-metrics.json")
if integer["maxRGBError"] > 1:
    raise SystemExit("Matching integer hash control exceeds the 1/255 RGB comparison bound.")
large_integer = metrics("noise-hash", "large-seed-integer-metrics.json", size=(400, 640))
if large_integer["maxRGBError"] > 1:
    raise SystemExit("The large-seed integer control exceeds the 1/255 RGB comparison bound.")
for seed in [0, 17, 4095]:
    for mode in ["fast", "precise"]:
        if seed == 4095:
            metrics("noise-hash", f"large-seed-{mode}-metrics.json", size=(400, 640))
        else:
            metrics(".build", f"noise-probe-{seed}-{mode}-metrics.json", size=(400, 640))
fast = metrics("noise-hash")
precise = metrics("noise-hash", "precise-metrics.json")
print("PASS: correct modulo and integer control stay within 1/255 RGB; the fmod mistake is detected.")
print(f"Sine hash measured RGB maxima: fast={fast['maxRGBError']}/255, safe+precise={precise['maxRGBError']}/255.")
print("Sine-hash differences are reported, not forced to match or required to improve with precise math.")

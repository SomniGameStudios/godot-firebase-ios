#!/usr/bin/env python3
"""Link all vendor archives using the same force-load policy as the Godot export."""
from pathlib import Path
import subprocess
import sys
import tempfile

sdk_directory = Path(sys.argv[1]).resolve()
frameworks = sys.argv[2:]
source = Path(__file__).resolve().parents[1] / "tests/firebase_link_smoke.swift"
with tempfile.TemporaryDirectory(prefix="firebase-link-") as temporary:
    for sdk, target, slice_name in (
        ("iphoneos", "arm64-apple-ios17.0", "ios-arm64"),
        ("iphonesimulator", "arm64-apple-ios17.0-simulator", "ios-arm64_x86_64-simulator"),
        ("iphonesimulator", "x86_64-apple-ios17.0-simulator", "ios-arm64_x86_64-simulator"),
    ):
        sdk_path = subprocess.check_output(["xcrun", "--sdk", sdk, "--show-sdk-path"], text=True).strip()
        command = ["xcrun", "--sdk", sdk, "swiftc", "-sdk", sdk_path, "-target", target,
                   "-F", str(sdk_directory / slice_name), str(source),
                   "-o", str(Path(temporary) / target), "-Xlinker", "-ObjC"]
        for framework in frameworks:
            name = framework.removesuffix(".xcframework")
            binary = sdk_directory / framework / slice_name / (name + ".framework") / name
            command += ["-Xlinker", "-force_load", "-Xlinker", str(binary)]
        subprocess.run(command, check=True)
        print(f"Vendor link passed: {target}", flush=True)

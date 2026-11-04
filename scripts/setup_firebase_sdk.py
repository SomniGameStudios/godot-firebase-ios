#!/usr/bin/env python3
"""Install the pinned Firebase ZIP; never accept an unversioned or partial cache."""
import argparse
from pathlib import Path
import plistlib
import shutil
import subprocess
import tempfile

SLICES = ("ios-arm64", "ios-arm64_x86_64-simulator")


def validate(root, version, frameworks):
    for framework in frameworks:
        name = framework.removesuffix(".xcframework")
        for slice_name in SLICES:
            for bundle in (
                root / framework / slice_name / (name + ".framework"),
                root / slice_name / (name + ".framework"),
            ):
                if not (bundle / name).is_file():
                    raise ValueError(f"Missing {bundle.relative_to(root)}/{name}")
                if name in ("FirebaseCore", "FirebaseFirestoreInternal"):
                    with (bundle / "Info.plist").open("rb") as source:
                        actual = plistlib.load(source)["CFBundleShortVersionString"]
                    if actual != version:
                        raise ValueError(f"{name}: expected {version}, found {actual}")



def install(version, url, destination, frameworks):
    marker = destination / ".firebase-version"
    try:
        if marker.read_text().strip() == version:
            validate(destination, version, frameworks)
            print(f"Firebase SDK {version} cache verified")
            return
    except (OSError, ValueError, KeyError, plistlib.InvalidFileException):
        pass

    destination.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=".firebase-download-", dir=destination.parent) as temporary:
        work = Path(temporary)
        archive = work / "Firebase.zip"
        subprocess.run(["curl", "--fail", "--location", "--retry", "3", "--output", str(archive), url], check=True)
        extracted = work / "extracted"
        subprocess.run(["unzip", "-oq", str(archive), "-d", str(extracted)], check=True)
        for nested in extracted.rglob("Firebase-*-latest.zip"):
            subprocess.run(["unzip", "-oq", str(nested), "-d", str(extracted)], check=True)
        staged = work / "sdk"
        staged.mkdir()
        for framework in frameworks:
            matches = sorted(extracted.rglob(framework))
            if not matches:
                raise ValueError(f"Missing required framework: {framework}")
            shutil.copytree(matches[0], staged / framework)
            name = framework.removesuffix(".xcframework") + ".framework"
            for slice_name in SLICES:
                shutil.copytree(staged / framework / slice_name / name, staged / slice_name / name)
        validate(staged, version, frameworks)
        (staged / ".firebase-version").write_text(version + "\n")
        if destination.exists():
            shutil.rmtree(destination)
        staged.rename(destination)
        print(f"Firebase SDK {version} installed and verified")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("version")
    parser.add_argument("url")
    parser.add_argument("destination", type=Path)
    parser.add_argument("frameworks", nargs="+")
    args = parser.parse_args()
    install(args.version, args.url, args.destination, args.frameworks)

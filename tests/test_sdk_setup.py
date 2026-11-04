import importlib.util
import json
from pathlib import Path
import plistlib
import re
import subprocess
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("setup_sdk", ROOT / "scripts/setup_firebase_sdk.py")
sdk = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sdk)
VERSION = "12.19.3"
FRAMEWORKS = ["FirebaseCore.xcframework", "FirebaseFirestoreInternal.xcframework"]


class SDKSetupTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.destination = self.root / "sdk"
        self.archive = self.root / "Firebase.zip"
        self.make_archive()

    def make_archive(self, version=VERSION, omit=None):
        with zipfile.ZipFile(self.archive, "w") as archive:
            for framework in FRAMEWORKS:
                name = framework.removesuffix(".xcframework")
                for slice_name in sdk.SLICES:
                    if (framework, slice_name) == omit:
                        continue
                    prefix = f"Firebase/{framework}/{slice_name}/{name}.framework/"
                    archive.writestr(prefix + name, b"fixture binary")
                    archive.writestr(prefix + "Info.plist", plistlib.dumps({"CFBundleShortVersionString": version}))

    def install(self, url=None):
        sdk.install(VERSION, url or self.archive.as_uri(), self.destination, FRAMEWORKS)

    def test_old_and_unversioned_caches_are_replaced(self):
        for marker in (None, "11.15.0"):
            with self.subTest(marker=marker):
                self.destination.mkdir(exist_ok=True)
                (self.destination / "stale").touch()
                version_file = self.destination / ".firebase-version"
                if marker:
                    version_file.write_text(marker)
                else:
                    version_file.unlink(missing_ok=True)
                self.install()
                self.assertFalse((self.destination / "stale").exists())
                self.assertEqual(version_file.read_text().strip(), VERSION)

    def test_verified_cache_needs_no_download(self):
        self.install()
        self.install((self.root / "missing.zip").as_uri())

    def test_partial_cache_is_rebuilt(self):
        self.install()
        binary = self.destination / "ios-arm64/FirebaseCore.framework/FirebaseCore"
        binary.unlink()
        self.install()
        self.assertTrue(binary.is_file())

    def test_wrong_binary_version_is_not_trusted(self):
        self.install()
        for relative in (
            "FirebaseFirestoreInternal.xcframework/ios-arm64/FirebaseFirestoreInternal.framework/Info.plist",
            "ios-arm64/FirebaseFirestoreInternal.framework/Info.plist",
        ):
            with self.subTest(relative=relative):
                info = self.destination / relative
                info.write_bytes(plistlib.dumps({"CFBundleShortVersionString": "11.15.0"}))
                self.install()
                self.assertEqual(plistlib.loads(info.read_bytes())["CFBundleShortVersionString"], VERSION)

    def test_failed_download_preserves_old_cache_but_fails(self):
        self.destination.mkdir()
        marker = self.destination / ".firebase-version"
        marker.write_text("11.15.0")
        with self.assertRaises(subprocess.CalledProcessError):
            self.install((self.root / "missing.zip").as_uri())
        self.assertEqual(marker.read_text(), "11.15.0")

    def test_incomplete_or_wrong_version_archive_is_rejected(self):
        for kwargs in ({"omit": (FRAMEWORKS[1], sdk.SLICES[1])}, {"version": "11.15.0"}):
            with self.subTest(kwargs=kwargs):
                self.make_archive(**kwargs)
                with self.assertRaises((ValueError, FileNotFoundError)):
                    self.install()
                self.assertFalse(self.destination.exists())

    def test_dependency_paths_and_export_list_agree(self):
        makefile = (ROOT / "Makefile").read_text()
        self.assertIn(f"FIREBASE_VERSION = {VERSION}", makefile)
        self.assertIn(f'exact: "{VERSION}"', (ROOT / "GodotFirebaseiOS/Package.swift").read_text())
        pins = json.loads((ROOT / "GodotFirebaseiOS/Package.resolved").read_text())["pins"]
        self.assertEqual(next(p["state"]["version"] for p in pins if p["identity"] == "firebase-ios-sdk"), VERSION)
        make_frameworks = set(re.findall(r'^\s+(\w+\.xcframework)', makefile, re.M))
        export = (ROOT / "demo/addons/GodotFirebaseiOS/export_plugin.gd").read_text()
        export_frameworks = set(re.findall(r'"(\w+\.xcframework)"', export))
        self.assertEqual(make_frameworks, export_frameworks)
        self.assertIn("GoogleAdsOnDeviceConversion.xcframework", make_frameworks)
        self.assertIn("Promises.xcframework", make_frameworks)


if __name__ == "__main__":
    unittest.main()

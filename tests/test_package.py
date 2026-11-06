"""Development build validation; no game or external application access."""
import importlib.util
import io
import json
import struct
import unittest
import wave
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("package", ROOT / "tools/package.py")
package = importlib.util.module_from_spec(spec); spec.loader.exec_module(package)


class PackageTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.payload, cls.version = package.working_payload()
        cls.data = package.build(cls.payload, cls.version, "0" * 40)

    def test_repeatable_bytes_and_single_install_root(self):
        self.assertEqual(self.data, package.build(dict(reversed(list(self.payload.items()))), self.version, "0" * 40))
        with zipfile.ZipFile(io.BytesIO(self.data)) as archive:
            self.assertTrue(all(name.startswith("LumenShift/") for name in archive.namelist()))
            self.assertIn("LumenShift/Core/Bootstrap.lua", archive.namelist())
            self.assertIn("LumenShift/ASSET-LICENSE.md", archive.namelist())

    def test_source_commit_and_all_content_hashes(self):
        with zipfile.ZipFile(io.BytesIO(self.data)) as archive:
            info = json.loads(archive.read("LumenShift/BUILD.json"))
            self.assertEqual(info["source_commit"], "0" * 40)
            for name, sha in info["files"].items():
                self.assertEqual(sha, package.digest(archive.read("LumenShift/" + name)))

    def test_unsafe_or_case_colliding_paths_refused(self):
        for name in ("../outside", "/absolute", "C:/path", "Core\\bad", "core/Bootstrap.lua"):
            with self.assertRaises(AssertionError):
                package.build(dict(self.payload, **{name: b"bad"}), self.version, "0" * 40)

    def test_asset_tga_headers_and_bounded_audio(self):
        for name, data in self.payload.items():
            if name.endswith(".tga"):
                self.assertEqual(data[2], 2); self.assertEqual(data[16:18], b"\x20\x28")
                width, height = struct.unpack_from("<HH", data, 12)
                self.assertEqual(len(data), 18 + width * height * 4)
            if name.endswith(".wav"):
                with wave.open(io.BytesIO(data)) as sound:
                    self.assertEqual((sound.getnchannels(), sound.getsampwidth(), sound.getframerate()), (1, 2, 22050))
                    self.assertAlmostEqual(sound.getnframes() / sound.getframerate(), .32)
                    frames = sound.readframes(sound.getnframes())
                    self.assertLess(max(abs(n) for n in struct.unpack("<" + "h" * (len(frames) // 2), frames)), 32767)

    def test_missing_or_changed_archive_members_refused(self):
        with zipfile.ZipFile(io.BytesIO(self.data)) as archive:
            expected = {name[len("LumenShift/"):]: archive.read(name) for name in archive.namelist()}
        expected.pop("Core/Bootstrap.lua")
        with self.assertRaises(AssertionError): package.validate(self.data, expected)
        expected["Core/Bootstrap.lua"] = b"changed"
        with self.assertRaises(AssertionError): package.validate(self.data, expected)


if __name__ == "__main__": unittest.main()

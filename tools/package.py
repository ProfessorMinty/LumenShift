"""Allowlisted, deterministic local development ZIP. No upload or installation functionality."""
import argparse
import hashlib
import io
import json
import posixpath
import re
import subprocess
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
NOTICES = {"LICENSE": "LICENSE", "ASSET-LICENSE.md": "ASSET-LICENSE.md",
           "README.md": "docs/21-BETA-USER-GUIDE.md", "CHANGELOG.md": "CHANGELOG.md",
           "ASSET-PROVENANCE.md": "assets/PROVENANCE.md", "ASSET-MANIFEST.json": "assets/manifest.json",
           "THIRD-PARTY-NOTICES.md": "THIRD-PARTY-NOTICES.md", "ASSET-SOURCES.json": "assets/theme-sources.json"}


def digest(data):
    return hashlib.sha256(data).hexdigest()


def collect(read):
    prefix = "addon/LumenShift/"
    toc = read(prefix + "LumenShift.toc").decode("utf-8")
    entries = [line.strip() for line in toc.splitlines() if line.strip() and not line.startswith("#")]
    assets = json.loads(read("assets/manifest.json"))["files"]
    names = entries + ["LumenShift.toc", "Bindings.xml"] + list(assets)
    assert len(set(names)) == len(names) and all(re.fullmatch(r"[A-Za-z0-9_/.-]+", name) and ".." not in name
        and not name.startswith("/") for name in names), "Invalid runtime paths"
    payload = {name: read(prefix + name) for name in names}
    for name, expected in assets.items():
        assert digest(payload[name]) == expected, "Asset provenance hash mismatch: " + name
    payload.update({name: read(source) for name, source in NOTICES.items()})
    version = re.search(r"^## Version: (.+)$", toc, re.M).group(1).strip()
    assert "## Interface: 16001" in toc and version in payload["CHANGELOG.md"].decode("utf-8")
    assert b"MIT License" in payload["LICENSE"] and b"All Rights Reserved" in payload["ASSET-LICENSE.md"]
    return payload, version


def working_payload():
    # Development tests only. Release candidates are assembled from clean recorded Git blobs.
    def read(name):
        path = ROOT / name
        assert not path.is_symlink()
        data = path.read_bytes()
        return data if path.suffix in (".tga", ".wav") else data.replace(b"\r\n", b"\n")
    return collect(read)


def build(payload, version, commit):
    assert re.fullmatch(r"[0-9a-f]{40}", commit), "Full source commit required"
    assert len({name.casefold() for name in payload}) == len(payload), "Case-colliding paths"
    for name in payload:
        assert not name.startswith("/") and ".." not in name and "\\" not in name and ":" not in name
    payload = dict(payload)
    # The bundled guide lives at the ZIP root, not in repository docs/. Pin its
    # relative documentation links to this exact source instead of shipping
    # broken links or silently following later changes on a mutable branch.
    def guide_link(match):
        target = match.group(1)
        if ":" in target or target.startswith("#"):
            return match.group(0)
        target = posixpath.normpath(posixpath.join("docs", target))
        assert not target.startswith(("/", "../")), "Guide link outside repository"
        return "](https://github.com/ProfessorMinty/LumenShift/blob/" + commit + "/" + target + ")"
    payload["README.md"] = re.sub(r"\]\(([^)]+)\)", guide_link,
                                  payload["README.md"].decode("utf-8")).encode("utf-8")
    assert "Core/Build.lua" in payload, "Runtime build identity module required"
    payload["Core/Build.lua"] = ('local _, ns = ...\nns.build = "' + commit + '"\n').encode("ascii")
    compatibility = payload["Core/Compatibility.lua"].decode("utf-8")
    signatures = sorted(re.findall(r'\["(\d+\.\d+\.\d+:\d+:\d+)"\] = true', compatibility))
    contract = re.findall(r'local policy = \{ version = "(\d+\.\d+\.\d+)", interface = (\d+), minimumBuild = (\d+), mismatchAction = "(warn)" \}', compatibility)
    assert len(contract) == 1, "One runtime compatibility policy required"
    family, interface, minimum, mismatch = contract[0]
    assert signatures and len(signatures) == len(set(signatures)), "Observed identities required"
    for signature in signatures:
        ver, build_number, ui = signature.split(":")
        assert ver == family and ui == interface and int(build_number) >= int(minimum), "Observed identity outside runtime policy"
    manifest = {"version": version, "source_commit": commit, "observed_identities": signatures,
                "experimental_client_policy": {"reference_version": family, "reference_interface": int(interface),
                                               "reference_minimum_build": int(minimum), "mismatch_action": mismatch,
                                               "capability_checks": "per-operation"},
                "production_admission": False,
                "generated": {"Core/Build.lua": "source commit identifier; deterministic build substitution",
                              "README.md": "relative documentation links pinned to source commit"},
                "status": "development candidate; integrated native acceptance pending; not published",
                "code_license": "MIT", "creative_asset_license": "Original assets: All Rights Reserved; third-party assets: CC BY 4.0 / Craftwork Commercial License; see bundled notices",
                "files": {name: digest(data) for name, data in sorted(payload.items())}}
    contents = dict(payload)
    contents["BUILD.json"] = (json.dumps(manifest, indent=2, sort_keys=True) + "\n").encode("utf-8")
    buffer = io.BytesIO()
    # Stored entries eliminate compression-library differences. Small, self-contained archive.
    with zipfile.ZipFile(buffer, "w", compression=zipfile.ZIP_STORED) as archive:
        for name, data in sorted(contents.items()):
            info = zipfile.ZipInfo("LumenShift/" + name, (1980, 1, 1, 0, 0, 0))
            info.create_system = 3; info.external_attr = 0o100644 << 16
            archive.writestr(info, data)
    result = buffer.getvalue()
    validate(result, contents)
    return result


def validate(data, expected):
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        names = archive.namelist()
        assert len(names) == len(set(names)), "Duplicate ZIP member"
        assert set(names) == {"LumenShift/" + name for name in expected}, "Archive allowlist mismatch"
        assert archive.testzip() is None, "ZIP CRC failure"
        for name in names:
            assert archive.read(name) == expected[name[len("LumenShift/"):]], "Archive content mismatch"
            info = archive.getinfo(name)
            assert info.date_time == (1980, 1, 1, 0, 0, 0) and info.external_attr >> 16 == 0o100644
        manifest = json.loads(archive.read("LumenShift/BUILD.json"))
        assert set(manifest["files"]) == set(expected) - {"BUILD.json"}
        for name, sha in manifest["files"].items():
            assert digest(archive.read("LumenShift/" + name)) == sha


def main():
    parser = argparse.ArgumentParser(); parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    def git(*argv):
        return subprocess.check_output(["git", *argv], cwd=ROOT)
    assert not git("status", "--porcelain").strip(), "Commit or preserve all work before building a recorded candidate"
    commit = git("rev-parse", "HEAD").decode().strip()
    paths = git("ls-tree", "-r", "--name-only", "HEAD", "addon/LumenShift").decode().splitlines()
    payload, version = collect(lambda name: git("show", "HEAD:" + name))
    assert set(paths) == {"addon/LumenShift/" + name for name in payload if name not in NOTICES}, "Unlisted runtime file"
    modes = git("ls-tree", "-r", "HEAD", "addon/LumenShift").decode().splitlines()
    assert all(line.startswith("100644 blob ") for line in modes), "Unexpected executable, symlink or submodule"
    one, two = build(payload, version, commit), build(payload, version, commit)
    assert one == two, "Reproducibility failure"
    args.output.mkdir(parents=True, exist_ok=True)
    target = args.output / f"LumenShift-{version}-{commit[:8]}.zip"
    target.write_bytes(one)
    receipt = f"{digest(one)}  {target.name}\n"
    target.with_suffix(".zip.sha256").write_text(receipt, encoding="utf-8")
    print(f"PACKAGE PASS: {len(payload) + 1} files; two identical builds; {len(one)} bytes")
    print(receipt.strip()); print(target.resolve())


if __name__ == "__main__":
    main()

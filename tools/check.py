"""Source/TOC checks; optional Lua 5.1 syntax + mocks through development-only Lupa."""
import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RUNTIME = ROOT / "addon" / "LumenShift"


def check():
    toc = (RUNTIME / "LumenShift.toc").read_text(encoding="utf-8")
    entries = [line.strip() for line in toc.splitlines() if line.strip() and not line.startswith("#")]
    actual = sorted(p.relative_to(RUNTIME).as_posix() for p in RUNTIME.rglob("*") if p.is_file())
    assert sorted(entries + ["LumenShift.toc"]) == actual, "TOC/runtime allowlist mismatch"
    assert len(entries) == len(set(entries)), "Duplicate TOC entry"
    assert "## Interface: 16001\n" in toc, "Candidate Forever interface changed; review live evidence"
    assert "## SavedVariables: LumenShiftDB\n" in toc
    version = re.search(r"^## Version: (.+)$", toc, re.M).group(1)
    assert f'ns.version = "{version}"' in (RUNTIME / "Core/Namespace.lua").read_text()
    assert version in (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")
    forbidden = re.compile(r"\b(SetCVar\w*|SetTempCVar|RemoveTempCVar|RegisterCVar|ResetTestCVars|"
                           r"ConsoleExec|SetDefaultVideoOptions|SetVideoOptions|SetGraphicsQuality|"
                           r"ResetAllCvars|RunScript|RunMacro\w*|loadstring|loadfile|dofile|require|"
                           r"PlaySound\w*|OnUpdate|hooksecurefunc)\b")
    for entry in entries:
        assert ".." not in entry and "\\" not in entry and not Path(entry).is_absolute()
        path = RUNTIME / entry
        assert not path.is_symlink()
        source = path.read_text(encoding="utf-8")
        code = re.sub(r"(?m)^\s*--.*$", "", source)
        inspected = re.sub(r"\bSetCVar\b", "", code) if entry == "Core/WriteBoundary.lua" else code
        assert not forbidden.search(inspected), f"Forbidden runtime API/token in {entry}"
        if entry not in {"Core/ReadOnly.lua", "Core/Bootstrap.lua", "Core/WriteBoundary.lua"}:
            assert not re.search(r"\b(_G|C_CVar)\b", source), f"Native API boundary leak: {entry}"
    boundary = (RUNTIME / "Core/WriteBoundary.lua").read_text()
    assert boundary.count(".SetCVar") == 2, "Only availability inspection and the single native call are allowed"
    assert boundary.count('ns.ReadOnly.Call(reader, reader.env.C_CVar.SetCVar, "Brightness", target)') == 1
    assert 'function B.Request() return nil, "TEST_NOT_ENABLED" end' in boundary
    print(f"STRUCTURAL PASS: {len(entries)} Lua modules, exact TOC paths, versions, one Brightness-only write boundary")
    return entries


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--lua-runtime", type=Path, help="Optional isolated Lupa 2.6 directory")
    parser.add_argument("--mocks", action="store_true", help="Execute Lua 5.1 syntax and mock checks")
    args = parser.parse_args()
    entries = check()
    if args.mocks:
        if args.lua_runtime:
            sys.path.insert(0, str(args.lua_runtime.resolve()))
        from lupa.lua51 import LuaRuntime
        import os
        os.chdir(ROOT)
        lua = LuaRuntime()
        for file in [RUNTIME / entry for entry in entries] + [ROOT / "tests/run.lua"]:
            lua.execute("assert(loadstring(...))", file.read_text(encoding="utf-8"))
        print(f"SYNTAX PASS: {len(entries) + 1} files under {lua.eval('_VERSION')}", flush=True)
        lua.execute((ROOT / "tests/run.lua").read_text(encoding="utf-8"))


if __name__ == "__main__":
    main()

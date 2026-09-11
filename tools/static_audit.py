#!/usr/bin/env python3
"""Static integrity audit for the complete experimental project.

This does not replace Godot parser/runtime execution.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def bracket_error(path: Path) -> str | None:
    text = path.read_text(encoding="utf-8-sig")
    stack: list[tuple[str, int, int]] = []
    pairs = {")": "(", "]": "[", "}": "{"}
    opens = set(pairs.values())
    quote: str | None = None
    triple = False
    escaped = False
    comment = False
    line = 1
    col = 0
    i = 0
    while i < len(text):
        char = text[i]
        col += 1
        if char == "\n":
            line += 1
            col = 0
            comment = False
            i += 1
            continue
        if comment:
            i += 1
            continue
        if quote is not None:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif triple and text[i : i + 3] == quote * 3:
                quote = None
                triple = False
                i += 2
                col += 2
            elif not triple and char == quote:
                quote = None
            i += 1
            continue
        if char == "#":
            comment = True
            i += 1
            continue
        if char in ('"', "'"):
            if text[i : i + 3] == char * 3:
                quote = char
                triple = True
                i += 3
                col += 2
                continue
            quote = char
            i += 1
            continue
        if char in opens:
            stack.append((char, line, col))
        elif char in pairs:
            if not stack or stack[-1][0] != pairs[char]:
                return f"unmatched {char} at {line}:{col}"
            stack.pop()
        i += 1
    if quote is not None:
        return "unclosed string"
    if stack:
        return f"unclosed {stack[-1]}"
    return None


def main() -> int:
    failures: list[str] = []
    checks = 0
    gd_files = sorted(path for path in ROOT.rglob("*.gd") if "diagnostic_logs" not in path.parts)
    function_map: dict[str, set[str]] = {}
    for script_path in gd_files:
        script_text = script_path.read_text(encoding="utf-8-sig")
        function_map[script_path.relative_to(ROOT).as_posix()] = set(
            re.findall(r"^\s*(?:static\s+)?func\s+([A-Za-z_]\w*)\s*\(", script_text, re.MULTILINE)
        )
    forbidden_markers = (
        "[... ELLIPSIZATION ...]",
        "CONTEXT TRUNCATED",
        "TODO_PLACEHOLDER",
        "NOT_IMPLEMENTED_PLACEHOLDER",
    )

    for path in gd_files:
        text = path.read_text(encoding="utf-8-sig")
        for match in re.finditer(r'preload\("res://([^\"]+)"\)', text):
            checks += 1
            target = ROOT / match.group(1)
            if not target.is_file():
                failures.append(f"missing preload: {path.relative_to(ROOT)} -> {match.group(1)}")
        error = bracket_error(path)
        checks += 1
        if error:
            failures.append(f"delimiter error: {path.relative_to(ROOT)}: {error}")
        for number, line in enumerate(text.splitlines(), 1):
            checks += 1
            if line.startswith(" "):
                failures.append(f"space indentation: {path.relative_to(ROOT)}:{number}")
            if line.rstrip() != line:
                failures.append(f"trailing whitespace: {path.relative_to(ROOT)}:{number}")
        for match in re.finditer(r":=\s*[A-Za-z_][A-Za-z0-9_]*\s*\[", text):
            checks += 1
            line = text[: match.start()].count("\n") + 1
            failures.append(f"unsafe inferred dictionary access: {path.relative_to(ROOT)}:{line}")
        checks += len(forbidden_markers)
        for marker in forbidden_markers:
            if marker in text:
                failures.append(f"context-damage marker in {path.relative_to(ROOT)}: {marker}")
        checks += 1
        significant = [line.strip() for line in text.splitlines() if line.strip() and not line.lstrip().startswith("#")]
        if not significant or not significant[0].startswith("extends "):
            failures.append(f"script lacks leading extends declaration: {path.relative_to(ROOT)}")

        # Catch accidental adjacent duplicate declarations (a real defect found
        # in the full integration suite) without treating branch-local names as
        # collisions. Godot remains the authority for full lexical scoping.
        lines = text.splitlines()
        previous_declaration: tuple[int, str, int] | None = None
        for line_number, source_line in enumerate(lines, 1):
            declaration = re.match(r"^(\s+)var\s+([A-Za-z_]\w*)\b", source_line)
            if declaration:
                indent = len(declaration.group(1))
                local_name = declaration.group(2)
                checks += 1
                if previous_declaration is not None:
                    previous_indent, previous_name, previous_line = previous_declaration
                    if indent == previous_indent and local_name == previous_name and line_number - previous_line <= 2:
                        failures.append(f"adjacent duplicate local variable: {path.relative_to(ROOT)}:{line_number}: {local_name}")
                previous_declaration = (indent, local_name, line_number)
            elif source_line.strip() and not source_line.lstrip().startswith("#"):
                # Keep one-line gaps/comments but reset after executable content.
                if previous_declaration is not None and line_number - previous_declaration[2] > 1:
                    previous_declaration = None

        if path.relative_to(ROOT).as_posix().startswith("src/core/"):
            for match in re.finditer(r'preload\(["\']res://src/ai/', text):
                checks += 1
                line = text[: match.start()].count("\n") + 1
                failures.append(f"core-to-ai dependency inversion: {path.relative_to(ROOT)}:{line}")

    # Cross-file contract check for direct calls through preload aliases.
    # This catches context drift such as ModuleA calling a renamed or removed
    # static method in ModuleB. Dynamic module calls remain runtime checks.
    for path in gd_files:
        text = path.read_text(encoding="utf-8-sig")
        aliases = {
            match.group(1): match.group(2).replace("res://", "")
            for match in re.finditer(
                r"^\s*const\s+([A-Za-z_]\w*)\s*(?::=|=)\s*preload\([\"\'](res://[^\"\']+)[\"\']\)",
                text,
                re.MULTILINE,
            )
        }
        for alias, target in aliases.items():
            for call in re.finditer(r"\b" + re.escape(alias) + r"\.([A-Za-z_]\w*)\s*\(", text):
                checks += 1
                method = call.group(1)
                if method == "new":
                    continue
                if target not in function_map:
                    failures.append(
                        f"preload call target missing: {path.relative_to(ROOT)} -> {target}"
                    )
                elif method not in function_map[target]:
                    line = text[: call.start()].count("\n") + 1
                    failures.append(
                        f"preload method missing: {path.relative_to(ROOT)}:{line} -> {target}.{method}()"
                    )

    for scene_path in sorted(path for path in ROOT.rglob("*.tscn") if "diagnostic_logs" not in path.parts):
        scene_text = scene_path.read_text(encoding="utf-8-sig")
        for match in re.finditer(r'path="res://([^"]+)"', scene_text):
            checks += 1
            if not (ROOT / match.group(1)).is_file():
                failures.append(f"missing scene resource: {scene_path.relative_to(ROOT)} -> {match.group(1)}")

    for path in sorted(path for path in ROOT.rglob("*.json") if "diagnostic_logs" not in path.parts):
        checks += 1
        try:
            json.loads(path.read_text(encoding="utf-8-sig"))
        except Exception as exc:  # noqa: BLE001
            failures.append(f"invalid JSON: {path.relative_to(ROOT)}: {exc}")

    checks += 1
    project = (ROOT / "project.godot").read_text(encoding="utf-8")
    match = re.search(r'run/main_scene="res://([^\"]+)"', project)
    if not match or not (ROOT / match.group(1)).is_file():
        failures.append("project.godot main scene is missing or invalid")

    required = [
        "src/core/identifier_rules.gd",
        "src/core/legal_action.gd",
        "src/core/module_protocol.gd",
        "src/core/runtime_snapshot.gd",
        "src/core/universal_card_engine.gd",
        "src/cards/card_state.gd",
        "src/random/deterministic_rng.gd",
        "src/session/player_registry.gd",
        "src/turns/turn_state.gd",
        "src/turns/phase_machine.gd",
        "src/scoring/score_state.gd",
        "src/persistence/save_codec.gd",
        "src/persistence/replay_service.gd",
        "src/network/sync_packet.gd",
        "games/high_card_arena/high_card_arena_module.gd",
        "src/diagnostics/engine_diagnostic_runner.gd",
        "demo/diagnostic_bootstrap.gd",
        "demo/diagnostic_bootstrap.tscn",
        "tests/diagnostics/run_engine_diagnostics.gd",
        "RUN_DIAGNOSTIC_WINDOWS.bat",
        "RUN_FULL_AUDIT_WINDOWS.bat",
        "RUN_PACKAGE_INTEGRITY_WINDOWS.bat",
        "tools/verify_manifest.ps1",
        "DIAGNOSTIC_README_FIRST.txt",
        "tests/full/run_complete_engine_experiment.gd",
        "tests/run_uce_f01_foundations.gd",
        "tests/run_uce_f02_cards_hardening.gd",
        "tests/run_uce_f03_session_flow.gd",
        "tests/run_uce_f04_persistence_sync.gd",
        "tests/run_uce_f05_interfaces_ai.gd",
    ]
    for relative in required:
        checks += 1
        if not (ROOT / relative).is_file():
            failures.append(f"required file missing: {relative}")

    # Foundation contract: every concrete rule module declaring module_id() must
    # also declare or inherit module_version(). Direct source modules are checked
    # mechanically here; inherited hostile fixtures are covered by F01 runtime tests.
    concrete_modules = [
        "games/high_card_arena/high_card_arena_module.gd",
        "tests/fixtures/minimal_turn_module.gd",
        "tests/fixtures/draw_card_module.gd",
        "tests/fixtures/shuffle_deal_module.gd",
        "tests/fixtures/action_mutation_module.gd",
    ]
    for relative in concrete_modules:
        checks += 1
        methods = function_map.get(relative, set())
        if "module_id" not in methods or "module_version" not in methods:
            failures.append(f"module identity contract incomplete: {relative}")

    engine_text = (ROOT / "src/core/universal_card_engine.gd").read_text(encoding="utf-8-sig")
    for required_symbol in ("ModuleProtocol", "RuntimeSnapshot", "validate_internal_consistency", "_validate_viewer"):
        checks += 1
        if required_symbol not in engine_text:
            failures.append(f"foundation kernel symbol missing: {required_symbol}")

    audit_batch = (ROOT / "RUN_FULL_AUDIT_WINDOWS.bat").read_text(encoding="utf-8-sig")
    for suite_name in ("uce_f01", "uce_f02", "uce_f03", "uce_f04", "uce_f05", "complete"):
        checks += 1
        if f"RUN_TEST {suite_name} " not in audit_batch:
            failures.append(f"full audit does not run required suite: {suite_name}")
    checks += 1
    if "RUN_MAIN main_scene" not in audit_batch:
        failures.append("full audit does not run the project main scene")

    result = {
        "status": "PASS" if not failures else "FAIL",
        "checks": checks,
        "gd_files": len(gd_files),
        "failures": failures,
        "warning": "Static audit does not execute the Godot parser or runtime.",
    }
    (ROOT / "STATIC_AUDIT.json").write_text(
        json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0 if not failures else 1


if __name__ == "__main__":
    sys.exit(main())

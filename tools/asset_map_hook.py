#!/usr/bin/env python3
"""PostToolUse hook — keep docs/technical/asset-map.md current automatically (spec: dependency-map / TD-051).

Wired in .claude/settings.json as a PostToolUse (Write|Edit) hook. Reads the tool payload on stdin;
if the edited file is a client script/scene/generator (a `.gd`/`.tscn`, or a generator `.py` under
client/assets/), it regenerates the dependency map so an ongoing session always has the latest graph.
A no-op for any other edit. Never blocks or errors the edit — a map failure is swallowed.

Stdlib only. Invoked as:  python3 "$CLAUDE_PROJECT_DIR/tools/asset_map_hook.py"
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))

# Only these edits change the script<->asset graph worth regenerating for.
RELEVANT = re.compile(r"client/.*\.(gd|tscn)$|client/assets/.*\.py$")


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        return 0
    ti = data.get("tool_input") or {}
    tr = data.get("tool_response") or {}
    path = ti.get("file_path") or tr.get("filePath") or ""
    if not RELEVANT.search(path):
        return 0
    sys.path.insert(0, HERE)
    try:
        import asset_map
        txt = asset_map.generate()
        os.makedirs(os.path.dirname(asset_map.OUT), exist_ok=True)
        with open(asset_map.OUT, "w", encoding="utf-8") as f:
            f.write(txt)
    except Exception:
        pass  # never fail the edit on a map hiccup
    return 0


if __name__ == "__main__":
    sys.exit(main())

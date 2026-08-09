#!/usr/bin/env python3
"""PostToolUse (Write|Edit) hook — nudge a spec-registry refresh, but only when due.

`spec_status.py --check` has guarded the markdown report since TD-074, and
`spec_status_html.py --check` now guards the page. Neither can guard the PUBLISHED
artifact: only the Artifact tool can publish, so a shell hook can surface the need but
never satisfy it. That gap is how the published registry sat two weeks and fifteen
specs behind without anything complaining (TD-108).

Deliberately quieter than `board_artifact_hook.py`, which nags on every `main.gd`
edit whether or not the board actually changed. This one RUNS THE CHECK and stays
silent when the page already matches the tree — a reminder that fires when nothing is
wrong is one people learn to skip, which is the same failure mode as a flaky test.

Reads the PostToolUse JSON on stdin. Never blocks; never fails a tool call.
"""
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ARTIFACT = "https://claude.ai/code/artifact/3a1b29ba-2404-4cae-8328-e911f1bfb41b"

# Files whose change can move a spec's status, its counts, or its findings.
SPEC_PATTERNS = [
    r"specs/[^/]+/tasks\.md$",
    r"specs/[^/]+/requirements\.md$",
    r"specs/[^/]+/design\.md$",
    r"^CLAUDE\.md$",
    r"/CLAUDE\.md$",
]


def _stale() -> bool:
    """True when the committed page disagrees with the tree.

    Shelling out to the tool rather than importing it keeps ONE definition of
    staleness — if the rule changes there, this follows automatically instead of
    drifting into a second, quietly different opinion.
    """
    try:
        done = subprocess.run(
            [sys.executable, os.path.join(ROOT, "tools", "spec_status_html.py"), "--check"],
            capture_output=True, text=True, timeout=45, cwd=ROOT,
        )
    except Exception:
        return False        # never let a hook break a tool call
    return done.returncode != 0


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0
    path = (payload.get("tool_input") or {}).get("file_path", "") or ""
    norm = path.replace("\\", "/")
    rel = norm[len(ROOT) + 1:] if norm.startswith(ROOT + "/") else norm
    if not any(re.search(p, rel) for p in SPEC_PATTERNS):
        return 0
    if not _stale():
        return 0            # the page already matches the tree — say nothing

    msg = (
        "[spec-registry] A spec file changed and `docs/technical/spec-status.html` is "
        "now stale. At your next stopping point: `python3 tools/spec_status.py && "
        "python3 tools/spec_status_html.py`, then RE-PUBLISH the page to the SAME "
        f"artifact URL via the Artifact tool (`url={ARTIFACT}`). The page and the "
        "published copy are separate — regenerating the file does not update the "
        "artifact, which is how it once fell fifteen specs behind (TD-108)."
    )
    json.dump(
        {
            "suppressOutput": True,
            "hookSpecificOutput": {
                "hookEventName": "PostToolUse",
                "additionalContext": msg,
            },
        },
        sys.stdout,
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())

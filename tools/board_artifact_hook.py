#!/usr/bin/env python3
"""PostToolUse (Write|Edit) hook — nudge a board-artifact refresh.

When a file that feeds the Contract Board preview artifact is edited, inject a
one-line reminder back into Claude's context so the published board artifact gets
re-captured + re-published (a shell hook cannot publish to claude.ai itself — only
the Artifact tool can — so this surfaces the need rather than doing the publish).

Quiet for every other edit. Reads the PostToolUse JSON on stdin.
"""
import json
import re
import sys

# Files whose change alters how the Contract Board LOOKS (what the artifact shows).
BOARD_PATTERNS = [
    r"client/scripts/main\.gd$",
    r"client/scripts/ui/(board_|wax_seal|threat_pips|notice).*\.gd$",
    r"client/assets/ui/board_surface\.gdshader$",
    r"client/assets/ui/gen_(logo|heraldry|structure|detail|banner|parch|board|emblems|normals)\w*\.py$",
    r"client/assets/ui/(board_|stone_|torch_|parch_|tack_|collegium_logo|crest|nameplate|banner|cobweb|votive|foxing|panel|seal_|badge_).*\.png$",
]


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0
    path = (payload.get("tool_input") or {}).get("file_path", "") or ""
    norm = path.replace("\\", "/")
    if not any(re.search(p, norm) for p in BOARD_PATTERNS):
        return 0
    name = norm.rsplit("/", 1)[-1]
    msg = (
        f"[board-artifact] `{name}` feeds the Contract Board preview artifact. "
        "At your next stopping point, refresh it: re-capture the board "
        "(`--board-preview`), rebuild the HTML with the scratchpad `gen_artifact.py`, "
        "and re-publish to the SAME artifact URL via the Artifact tool (pass `url=`)."
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

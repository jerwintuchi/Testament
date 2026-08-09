#!/usr/bin/env python3
"""Check the sign lexicon against its client prose — the seam no type system covers.

TD-093. Two claims that live on opposite sides of the trust boundary and so cannot be
checked by either side's test suite:

  P155  No string in `sign_prose.gd` names an axis or a trait value. The server table
        stopped handing the player its own answer; the client must not hand it back.
        `Notes: frail to flame` on the client is the same defect in a different file.

  Coverage  Every token in `SIGN_LEXICON` has authored prose, and the prose table
        invents no token the lexicon does not carry. A token without prose renders as
        "Something here, and no words for it yet." — a silent, shippable hole, because
        the fallback is deliberately not the raw token.

Stdlib only, same as the other tools here. Parses rather than imports: the server is
TypeScript and the client is GDScript, so text is the only common ground.

  python3 tools/lexicon_check.py             # report
  python3 tools/lexicon_check.py --selftest  # assert the RULES against fixtures
"""
import re
import sys
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
LEXICON = ROOT / 'src/server/src/incarnate/lexicon.ts'
TYPES = ROOT / 'src/server/src/incarnate/types.ts'
PROSE = ROOT / 'client/scripts/field/sign_prose.gd'
DERIVE_REACTION = ROOT / 'src/server/src/incarnate/deriveReaction.ts'

TOKEN_RE = re.compile(r"token:\s*'([a-z0-9-]+)'")
AXIS_RE = re.compile(r"axis:\s*'([A-Z_]+)'")
# AXIS_VALUES entries: `  ASPECT:      ['EMBER', 'FROST', ...],`
AXIS_VALUES_RE = re.compile(r"^\s*([A-Z_]+):\s*\[([^\]]*)\]", re.M)
# GDScript prose entries: `  "run-wax": "Candles slumped...",`
PROSE_RE = re.compile(r'"([a-z0-9-]+)":\s*"((?:[^"\\]|\\.)*)"')


def read(p: pathlib.Path) -> str:
    return p.read_text(encoding='utf-8')


def forbidden_words(types_src: str) -> list[str]:
    """Axis names + every trait value — the vocabulary prose may not use."""
    words = set()
    body = types_src.split('export const AXIS_VALUES', 1)[-1].split('} as const', 1)[0]
    for axis, values in AXIS_VALUES_RE.findall(body):
        words.add(axis)
        for v in re.findall(r"'([A-Z_]+)'", values):
            words.add(v)
    return sorted(words)


def lexicon_tokens(src: str) -> list[str]:
    return TOKEN_RE.findall(src)


def prose_entries(src: str) -> dict[str, str]:
    # Only the PROSE block, so CHANNEL_HEADING's values are not mistaken for prose.
    body = src.split('const PROSE := {', 1)[-1].split('\n}', 1)[0]
    return dict(PROSE_RE.findall(body))


def check(lex_src: str, types_src: str, prose_src: str, extra_tokens: list[str]) -> list[str]:
    problems = []
    words = forbidden_words(types_src)
    tokens = set(lexicon_tokens(lex_src)) | set(extra_tokens)
    prose = prose_entries(prose_src)

    # P155 — prose must not name an axis or a trait value, in any casing. Whole words
    # only: "brand" must not trip on nothing, but "cold" inside "colder" should, and
    # a bare substring rule would flag "scattered" for containing... nothing, while
    # missing "Cold." with punctuation. \b handles both.
    for token, text in sorted(prose.items()):
        for word in words:
            if re.search(rf'\b{re.escape(word)}\b', text, re.I):
                problems.append(f'P155: prose for {token!r} names {word!r}: {text!r}')

    for token in sorted(tokens - set(prose)):
        problems.append(f'coverage: token {token!r} has no authored prose')
    for token in sorted(set(prose) - tokens):
        problems.append(f'coverage: prose for {token!r} matches no lexicon token')

    return problems


def selftest() -> int:
    """Assert the RULES against fixtures, not against whatever the tree says today.

    `--check`-style runs go green whenever the tree happens to agree with itself;
    these fixtures fail if the checker itself stops working. (`asset_map.py`'s
    selftest sat red for eleven specs because nothing asserted the rules — TD-069.)
    """
    types = """
export const AXIS_VALUES = {
  ASPECT:  ['EMBER', 'MIRE'],
  FRAILTY: ['FLAME', 'COLD'],
} as const satisfies X;
"""
    lex = """
  { axis: 'ASPECT', value: 'EMBER', channel: 'RESIDUE', token: 'run-wax' },
  { axis: 'FRAILTY', value: 'FLAME', channel: 'STRESS_MARK', token: 'tallow-sweat' },
"""
    ok_prose = 'const PROSE := {\n\t"run-wax": "Candles slumped.",\n\t"tallow-sweat": "A fatty film.",\n}\n'

    cases = [
        ('clean table passes', ok_prose, []),
        ('prose naming a trait value is caught',
         'const PROSE := {\n\t"run-wax": "It is frail to flame.",\n\t"tallow-sweat": "A fatty film.",\n}\n',
         ['P155']),
        ('prose naming an axis is caught',
         'const PROSE := {\n\t"run-wax": "Its aspect shows.",\n\t"tallow-sweat": "A fatty film.",\n}\n',
         ['P155']),
        ('a value inside a longer word is still caught',
         'const PROSE := {\n\t"run-wax": "Candles.",\n\t"tallow-sweat": "It runs colder.",\n}\n',
         []),  # "colder" is not the whole word "cold" — documents the \\b boundary
        ('a token with no prose is caught',
         'const PROSE := {\n\t"run-wax": "Candles slumped.",\n}\n',
         ['coverage']),
        ('prose for an unknown token is caught',
         ok_prose.replace('}\n', '\t"ghost-token": "Nothing.",\n}\n'),
         ['coverage']),
    ]

    failures = 0
    for name, prose_src, expect in cases:
        found = check(lex, types, prose_src, [])
        kinds = {p.split(':')[0] for p in found}
        if expect:
            if not all(e in kinds for e in expect):
                print(f'  FAIL {name}: expected {expect}, got {found}')
                failures += 1
            else:
                print(f'  ok   {name}')
        else:
            if found:
                print(f'  FAIL {name}: expected clean, got {found}')
                failures += 1
            else:
                print(f'  ok   {name}')

    print('selftest: %s' % ('PASS' if failures == 0 else f'{failures} FAILED'))
    return 1 if failures else 0


def main() -> int:
    if '--selftest' in sys.argv:
        return selftest()

    # NO_REACTION_SIGN lives outside the table (deriveReaction.ts) but is a token a
    # player reads, so it needs prose too.
    extra = re.findall(r"token:\s*'([a-z0-9-]+)'", read(DERIVE_REACTION))
    problems = check(read(LEXICON), read(TYPES), read(PROSE), extra)

    if problems:
        print(f'{len(problems)} problem(s):')
        for p in problems:
            print(f'  {p}')
        return 1

    tokens = set(lexicon_tokens(read(LEXICON))) | set(extra)
    print(f'lexicon_check: OK — {len(tokens)} tokens, all with prose, no axis or trait '
          f'value named on the client.')
    return 0


if __name__ == '__main__':
    sys.exit(main())

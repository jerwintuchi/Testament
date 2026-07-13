# Spec Workflow

Every feature in Testament follows this chain. Nothing skips a step.

## The Chain
```
R# (requirement) → design.md entry → T# (task) → test → implementation → mark T# done
```

**Nothing is "done" without a passing test that is named in the task.**

## Step-by-Step

### 1. Write requirements first (`requirements.md`)
- Each requirement gets an `R#` ID (R1, R2, …)
- Format: user story + testable acceptance criterion
  ```
  **R3**: As a Seeker, when I probe an Incarnate on a channel I perceive, the server
  returns the sign for that channel derived from the Incarnate's hidden trait.
  - AC: deriveSign returns the same sign for the same trait value (determinism)
  - AC: the response never includes the underlying trait value (trait roll stays server-side)
  ```
- Correctness properties (determinism, server authority, trait-roll-never-on-wire) are requirements too: give them R# IDs

### 2. Write the design entry (`design.md`)
- Data models for new types
- Algorithm description with inputs/outputs
- Correctness properties (P#) that the implementation must satisfy
- Wire-protocol messages emitted/received (name, JSON payload shape). Signs cross the wire; trait rolls never do.
- Reference the R# IDs this design satisfies

### 3. Write tasks (`tasks.md`)
- Each task gets a `T#` ID
- Format:
  ```
  - [ ] T2 [R3, P1] — Implement `deriveSign` in `src/server/src/incarnate/signs.ts`
    Test: `signs.test.ts` — property: same trait → same sign; the trait value never appears in the output
  ```
- The test file and test description must be named BEFORE writing implementation code

### 4. Write the test
- Tests go alongside source: `src/server/src/**/*.test.ts`
- Write enough test cases to cover the ACs in the requirement
- For correctness properties (determinism, purity): use property-based patterns

### 5. Write the implementation
- Make the tests pass
- Do not exceed what the spec requires

### 6. Mark task done
- Change `[ ]` to `[x]` in tasks.md
- If you discover the requirement was wrong or incomplete, update requirements.md and add an entry to DECISION_LOG.md explaining why

## Switching Active Spec
When moving from one feature to another, update CLAUDE.md's active-work block:
```markdown
## Active Work
<!-- SWAP THESE LINES when switching features -->
@specs/<new-feature>/requirements.md
@specs/<new-feature>/design.md
@specs/<new-feature>/tasks.md
```
Add a DECISION_LOG.md entry: "Switched active spec from X to Y — reason."

## Keep the dependency map current
When a task adds or removes a **script↔asset dependency** (a new `load()`/`preload()`, a new
generator output, a new scene `ext_resource`), regenerate the map so the next session can trust it:
```bash
python3 tools/asset_map.py          # regenerate docs/technical/asset-map.md
python3 tools/asset_map.py --check  # exit 1 if stale — run before marking the task done
```
Record non-obvious wiring (the *why*) with a provenance header; see
[docs/technical/code-map.md](../../docs/technical/code-map.md).

## Golden Rule
If you can't point to a test that verifies it, the feature doesn't exist.

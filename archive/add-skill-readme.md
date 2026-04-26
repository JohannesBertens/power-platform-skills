# Plan: Add README.md to `skills/power-platform-connect/` and refactor `docs/skills.md`

## Current State

- `skills/power-platform-connect/` has only `SKILL.md` and `scripts/check-pac.sh`
- `docs/skills.md` contains both a **catalog overview** (table + generic "Adding a New Skill" section) and **detailed per-skill documentation** (lines 13–103)
- The detailed docs belong closer to the skill itself

## Step 1 — Create `skills/power-platform-connect/README.md`

Move lines 13–103 from `docs/skills.md` into a new `README.md` inside the skill directory. This includes:

| Section | Lines in `docs/skills.md` |
|---------|---------------------------|
| Frontmatter table | 17–24 |
| What It Does | 26–36 |
| Files | 38–45 |
| Bundled Script: `check-pac.sh` | 47–62 |
| Activation Triggers | 64–76 |
| Direct Invocation | 78–89 |
| Dependencies | 91–102 |

The new README.md will be self-contained, using relative paths (e.g. `./scripts/check-pac.sh` instead of `skills/power-platform-connect/scripts/check-pac.sh`).

## Step 2 — Simplify `docs/skills.md`

Replace the detailed per-skill content (lines 13–103) with a brief entry and a link to the new README:

```markdown
## power-platform-connect

Validates `pac` CLI installation and checks for updates.

→ **Full documentation:** [`skills/power-platform-connect/README.md`](../skills/power-platform-connect/README.md)
```

Keep the table in the Overview section, the `---` separator, and the "Adding a New Skill" section (lines 106–116) untouched.

## Step 3 — Update top-level `README.md` (optional)

The existing link `[power-platform-connect](./skills/power-platform-connect/)` already points to the skill directory. Once a `README.md` exists there, GitHub will auto-render it — **no change needed**.

## Summary of file changes

| File | Action |
|------|--------|
| `skills/power-platform-connect/README.md` | **Create** — detailed skill docs (moved from `docs/skills.md`) |
| `docs/skills.md` | **Edit** — replace detailed section with link to new README |
| `README.md` | No change needed (link already resolves correctly) |

# Publishing & Lifecycle

This document covers how to validate, publish, update, and consume skills from this repository using `gh skill`.

## Prerequisites

- GitHub CLI v2.90.0+ (`gh --version`)
- Push access to `JohannesBertens/power-platform-skills`
- Repository admin access (for `gh skill publish` interactive prompts)

## Publishing Workflow

### 1. Create or Update a Skill

Place skill files in `skills/<skill-name>/`. The directory name must match the `name` field in `SKILL.md`.

```
skills/my-new-skill/
├── SKILL.md              # Required
├── scripts/              # Optional
│   └── my-script.sh
└── references/           # Optional
    └── guide.md
```

### 2. Validate Locally

Run a dry-run validation against the agentskills.io spec:

```bash
gh skill publish --dry-run
```

This checks:

- `name` field: lowercase alphanumeric + hyphens, starts/ends with alphanumeric, 3-64 chars
- `name` matches the directory name
- `description` field is present
- `allowed-tools` is a string (not an array) if present
- No `metadata.github-*` fields (those are install-time metadata added by `gh skill install`)
- `license` field present (warning if missing)
- Tag protection rulesets are active (warning if not)

Auto-fix common issues:

```bash
gh skill publish --dry-run --fix
```

### 3. Commit and Push

```bash
git add skills/<skill-name>/
git commit -m "Add <skill-name> skill"
git push origin main
```

At this point the skill is already installable:

```bash
gh skill install JohannesBertens/power-platform-skills <skill-name>
```

### 4. Publish (Recommended)

`gh skill publish` automates the release process:

```bash
gh skill publish
```

Interactive prompts:

1. **Add `agent-skills` topic** — makes the repo discoverable via `gh skill search`
2. **Tagging strategy** — Semver recommended (e.g., `v1.0.0`)
3. **Version tag** — defaults to next semver bump
4. **Immutable releases** — prevents tag tampering after publication
5. **Release notes** — auto-generated from commits

This creates a GitHub Release with a git tag, enabling version-pinned installs.

## Consuming Skills

### Search

```bash
gh skill search power-platform
```

### Preview Before Installing

```bash
gh skill preview JohannesBertens/power-platform-skills power-platform-connect
```

Shows all files in the skill and lets you inspect each one.

### Install

```bash
# Interactive
gh skill install JohannesBertens/power-platform-skills

# Specific skill
gh skill install JohannesBertens/power-platform-skills power-platform-connect

# Pinned to a version tag
gh skill install JohannesBertens/power-platform-skills power-platform-connect --pin v1.0.0

# Pinned to a commit SHA (most secure)
gh skill install JohannesBertens/power-platform-skills power-platform-connect --pin abc123def

# Specific agent and scope
gh skill install JohannesBertens/power-platform-skills power-platform-connect \
  --agent claude-code --scope user
```

### Update

```bash
# Update all installed skills
gh skill update --all

# Update a specific skill
gh skill update power-platform-connect

# Check what's updatable without applying
gh skill update --dry-run
```

Pinned skills are skipped during updates.

## Versioning Strategy

This repository uses Semver tags:

- **`v1.0.3`** — fix: search full pac output for version, fail on unknown version instead of false "up to date"
- **`v1.0.2`** — patch: parse version from pac output, use dotnet tool search instead of curl
- **`v1.0.1`** — patch: improved version check in check-pac.sh, added NuGet latest check and upgrade suggestion
- **`v1.0.0`** — initial release of `power-platform-connect`
- **`v1.1.0`** — minor: new non-breaking skill content
- **`v2.0.0`** — major: breaking changes to skill instructions

Each skill can also be independently versioned using scoped tags (e.g., `power-platform-connect@v1.0.0`) if needed.

## Tag Protection

The repository has a ruleset (`protect-skill-tags`) enforcing:

| Action | Policy |
|--------|--------|
| Create tags matching `v*` | Allowed |
| Update (force-push) tags | Blocked |
| Delete tags | Blocked |
| Bypass | Repository admin only |

This ensures published versions are immutable.

## Provenance Metadata

When a skill is installed via `gh skill install`, the following metadata is appended to `SKILL.md` frontmatter:

```yaml
metadata:
  github-repo: https://github.com/JohannesBertens/power-platform-skills
  github-path: skills/power-platform-connect
  github-ref: v1.0.0
  github-pinned: v1.0.0        # only if --pin was used
  github-tree-sha: abc123...   # content hash for change detection
```

This metadata is used by `gh skill update` to detect upstream changes. Do **not** include these fields in the source `SKILL.md` — `gh skill publish` will flag them as errors.

## Troubleshooting

### `gh skill publish --dry-run` shows errors

- **`missing required field: description`** — add a `description` to frontmatter
- **`name does not match directory`** — rename the directory or the `name` field so they match
- **`metadata.github-* fields present`** — remove install-time metadata from source files

### `unknown command "skill" for "gh"`

Upgrade GitHub CLI to v2.90.0+.

### Skill not found by `gh skill search`

Ensure the repository has the `agent-skills` topic:

```bash
gh repo edit JohannesBertens/power-platform-skills --add-topic agent-skills
```

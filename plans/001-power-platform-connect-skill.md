# Plan: Publish `power-platform-connect` Skill for `gh skill`

## Context

`gh skill` (aliased as `gh skills`) was launched in GitHub CLI v2.90.0 on April 16, 2026. It provides package-manager-style commands (`search`, `install`, `preview`, `update`, `publish`) for Agent Skills following the open [agentskills.io](https://agentskills.io) spec.

Skills are folders containing a `SKILL.md` file with YAML frontmatter. `gh skill` discovers them in standard scan paths including `skills/*/SKILL.md`, `.github/skills/*/SKILL.md`, and others.

**Repository:** `JohannesBertens/power-platform-skills`

## Goal

Create and publish a skill called `power-platform-connect` that checks whether the `pac` CLI (Power Platform CLI) is installed, and guides the user through installation if it is not.

## Files to Create

### 1. `skills/power-platform-connect/SKILL.md`

```markdown
---
name: power-platform-connect
description: Check and validate the Power Platform CLI (pac) installation. Use when working with Power Platform, Dataverse, Power Apps, Power Automate, or Dynamics 365. Activates on prompts about pac CLI, Power Platform deployment, environment management, solution packaging, or any Power Platform CLI task.
allowed-tools: shell
license: MIT
---

# Power Platform Connect

## Prerequisites Check

Before performing any Power Platform task, verify the `pac` CLI is installed by running:

```bash
bash skills/power-platform-connect/scripts/check-pac.sh
```

If the check fails (pac not found):
1. Inform the user that the Power Platform CLI is required
2. Provide the install command: `dotnet tool install --global Microsoft.PowerApps.CLI.Tool`
3. Alternatively point to: https://learn.microsoft.com/en-us/power-platform/developer/cli/introduction
4. After installation, run `pac install latest` to ensure the latest version
5. Re-run the check script to confirm

## If pac is installed

Report the installed version and confirm readiness for Power Platform tasks.
```

### 2. `skills/power-platform-connect/scripts/check-pac.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

if ! command -v pac &>/dev/null; then
  echo "ERROR: pac CLI is not installed."
  echo "Install with: dotnet tool install --global Microsoft.PowerApps.CLI.Tool"
  echo "Docs: https://learn.microsoft.com/en-us/power-platform/developer/cli/introduction"
  exit 1
fi

echo "pac CLI found:"
pac --version
```

## SKILL.md Frontmatter Reference

| Field | Required | Value |
|-------|----------|-------|
| `name` | Yes | `power-platform-connect` — lowercase, hyphens, must match directory name, 3+ chars |
| `description` | Yes | Keyword-rich text that agents use to decide when to activate the skill |
| `allowed-tools` | No | `shell` — pre-approves shell command execution without user confirmation |
| `license` | Recommended | `MIT` — warning if missing during `gh skill publish` |

## Execution Steps

| # | Action | Command / Detail |
|---|--------|------------------|
| 1 | Create directory structure | `mkdir -p skills/power-platform-connect/scripts` |
| 2 | Create `SKILL.md` | Write frontmatter + markdown instructions |
| 3 | Create `check-pac.sh` | Write bash script, `chmod +x` |
| 4 | Commit & push | `git add skills/ && git commit -m "Add power-platform-connect skill"` |
| 5 | Validate | `gh skill publish --dry-run` — checks name rules, required fields, spec compliance |
| 6 | Publish | `gh skill publish` — adds `agent-skills` repo topic, creates `v1.0.0` tag + GitHub Release |
| 7 | Verify install | `gh skill install JohannesBertens/power-platform-skills power-platform-connect` |

## Prerequisites

- GitHub CLI v2.90.0+ (`gh --version`)
- Push access to `JohannesBertens/power-platform-skills`

## Validation Rules (enforced by `gh skill publish`)

- `name`: lowercase alphanumeric + hyphens, starts/ends with alphanumeric, 3+ chars, max 64
- `name` must match directory name
- `description` and `name` are required
- `allowed-tools` must be a string (not an array)
- No `metadata.github-*` fields in published source (those are added by `gh skill install`)
- `license` recommended (warning if missing)

## Publish Flow (`gh skill publish`)

Interactive prompts:
1. Add `agent-skills` topic to repo (required for `gh skill search` discoverability)
2. Tagging strategy (Semver recommended)
3. Version tag (e.g., `v1.0.0`)
4. Enable Immutable Releases (prevents tag tampering)
5. Auto-generate release notes

## Post-Publish Usage

```bash
# Search
gh skill search power-platform

# Preview before installing
gh skill preview JohannesBertens/power-platform-skills power-platform-connect

# Install (project scope, default agent)
gh skill install JohannesBertens/power-platform-skills power-platform-connect

# Install pinned to a version
gh skill install JohannesBertens/power-platform-skills power-platform-connect --pin v1.0.0
```

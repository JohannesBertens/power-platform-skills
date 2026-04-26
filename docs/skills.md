# Skills Catalog

This document catalogs all Agent Skills available in this repository.

## Overview

| Skill | Description | Version | Scripts |
|-------|-------------|---------|---------|
| [power-platform-connect](#power-platform-connect) | Validates `pac` CLI installation and checks for updates | v1.0.4 | `check-pac.sh` |

---

## power-platform-connect

Validates `pac` CLI installation and checks for updates.

→ **Full documentation:** [`skills/power-platform-connect/README.md`](../skills/power-platform-connect/README.md)

**Companion agent:** The `power-platform-developer` Copilot agent ([`.github/agents/power-platform-developer.agent.md`](../.github/agents/power-platform-developer.agent.md)) uses this skill for pac CLI prerequisite checks. See [Agent Definitions](./agents.md) for details.

---

## Adding a New Skill

To add a new skill to this repository:

1. Create a directory under `skills/<skill-name>/` (lowercase, hyphens, 3+ chars)
2. Add a `SKILL.md` with required frontmatter (`name`, `description`)
3. Optionally add scripts, templates, or reference files
4. Validate: `gh skill publish --dry-run`
5. Publish: `gh skill publish`

See [publishing.md](./publishing.md) for the full workflow.

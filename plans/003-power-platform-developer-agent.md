# Plan: Add Copilot Subagent Definition

## Context

This repository has one skill (`power-platform-connect`) installable via `gh skill install`. The goal is to add a Copilot **custom agent definition** (`.agent.md`) that acts as a Power Platform specialist subagent. This subagent references the existing skill and provides a full persona with commands, standards, and boundaries.

**Key constraint**: `gh skill install` only handles `SKILL.md` skills. There is no `gh agent install` command. The `.agent.md` will be distributed via `gh api` (download from the repo) and placed in `.github/agents/` or `~/.copilot/agents/`.

## Step 1: Create `.github/agents/power-platform-developer.agent.md`

Frontmatter following [docs/agents.md](../docs/agents.md) and the [GitHub config reference](https://docs.github.com/en/copilot/reference/custom-agents-configuration):

```yaml
---
name: Power Platform Developer
description: Power Platform and Dynamics 365 specialist. Use for solution export/import, environment management, Dataverse schema work, Power Automate flows, canvas/model-driven apps, and pac CLI operations. Activates on mentions of Power Platform, Dataverse, Power Apps, Power Automate, Dynamics 365, or pac CLI.
tools: ["read", "edit", "search", "execute"]
---
```

Body covering the six core areas from `docs/agents.md`:

1. **Persona** — specialist identity and expertise
2. **Commands** — pac CLI commands + skill script reference
3. **Testing** — validation steps (solution check, pack/unpack round-trip)
4. **Project structure** — expected file layout
5. **Code style** — naming, publisher prefixes, environment variables
6. **Boundaries** — always/ask-first/never tiers

The agent prompt references the `power-platform-connect` skill's `check-pac.sh` for prerequisite validation before any `pac` command.

## Step 2: Define the `gh` installation method

Two-step installation for end users:

```bash
# 1. Install the skill (provides check-pac.sh and validation instructions)
gh skill install JohannesBertens/power-platform-skills power-platform-connect

# 2. Install the agent definition
# Project-level (current repo):
mkdir -p .github/agents
gh api repos/JohannesBertens/power-platform-skills/contents/.github/agents/power-platform-developer.agent.md \
  --jq '.content' | base64 -d > .github/agents/power-platform-developer.agent.md

# Or user-level (all repos):
mkdir -p ~/.copilot/agents
gh api repos/JohannesBertens/power-platform-skills/contents/.github/agents/power-platform-developer.agent.md \
  --jq '.content' | base64 -d > ~/.copilot/agents/power-platform-developer.agent.md
```

## Step 3: Update documentation

| File | Change |
|------|--------|
| `README.md` | Add agent to the Agents table with install command |
| `docs/agents.md` | Add concrete example under "Adding an Agent to This Repository"; update file tree |
| `docs/skills.md` | Cross-reference the agent that uses the skill |

## Step 4: Validate and commit

1. Run `gh skill publish --dry-run` to confirm existing skill still validates
2. Manually verify `.agent.md` frontmatter has required fields (`description`)
3. Commit with message: `feat: add power-platform-developer Copilot subagent definition`

## Files to create/modify

| Action | Path |
|--------|------|
| **Create** | `.github/agents/power-platform-developer.agent.md` |
| **Modify** | `README.md` |
| **Modify** | `docs/agents.md` |
| **Modify** | `docs/skills.md` |

## Decision: One agent only

Start with `power-platform-developer.agent.md` only. Additional agents (solution-architect, power-platform-reviewer) can be added later.

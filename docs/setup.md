# Repository Setup

This guide covers everything needed to set up the `power-platform-skills` repository for local development and skill publishing.

## Repository Overview

- **Name:** `JohannesBertens/power-platform-skills`
- **License:** MIT
- **Purpose:** A collection of Agent Skills for Power Platform and Dynamics 365, publishable via `gh skill` and compatible with GitHub Copilot, Claude Code, Cursor, Codex, Gemini CLI, and other agents supporting the [agentskills.io](https://agentskills.io) open standard.

## Directory Structure

```
power-platform-skills/
├── .github/                    # GitHub configuration
├── .vscode/                    # VS Code settings
├── docs/                       # Documentation
│   ├── setup.md                # This file — repository setup
│   ├── skills.md               # Skills catalog and details
│   └── publishing.md           # Publishing and lifecycle management
├── plans/                      # Implementation plans and decisions
├── skills/                     # Agent Skills (primary skill directory)
│   └── power-platform-connect/ # Skill: Power Platform CLI check
│       ├── SKILL.md            # Skill definition (required)
│       └── scripts/            # Skill helper scripts
│           └── check-pac.sh
├── LICENSE                     # MIT License
└── README.md                   # Repository overview
```

## Prerequisites

| Tool | Minimum Version | Purpose |
|------|----------------|---------|
| Git | Any recent | Version control |
| GitHub CLI (`gh`) | v2.90.0+ | `gh skill` commands (install, publish, search, update) |
| Bash | 3+ | Skill helper scripts |

Check your `gh` version:

```bash
gh --version
```

If you need to install or upgrade, see the full platform-specific instructions at [github.com/cli/cli#installation](https://github.com/cli/cli#installation).

Quick reference:

```bash
# macOS
brew upgrade gh

# Ubuntu/Debian
sudo apt update && sudo apt install gh

# Windows
winget upgrade GitHub.cli
```

## Clone the Repository

```bash
git clone https://github.com/JohannesBertens/power-platform-skills.git
cd power-platform-skills
```

## Install a Skill from This Repository

You can install any skill from this repo into your local agent environment:

```bash
# Interactive — browse and pick
gh skill install JohannesBertens/power-platform-skills

# Specific skill
gh skill install JohannesBohannes/power-platform-skills power-platform-connect

# Pinned to a version
gh skill install JohannesBertens/power-platform-skills power-platform-connect --pin v1.0.0

# For a specific agent host
gh skill install JohannesBertens/power-platform-skills power-platform-connect --agent claude-code
```

### Supported Agent Hosts

When installing, you choose a scope and agent. Skills are placed in the correct directory automatically:

| Agent | Project Scope | User Scope |
|-------|--------------|------------|
| GitHub Copilot | `.agents/skills/` | `~/.copilot/skills/` |
| Claude Code | `.claude/skills/` | `~/.claude/skills/` |
| Cursor | `.agents/skills/` | `~/.cursor/skills/` |
| Codex | `.agents/skills/` | `~/.codex/skills/` |
| Gemini CLI | `.agents/skills/` | `~/.gemini/skills/` |

## Repository Security

### Tag Protection

A repository ruleset (`protect-skill-tags`) is configured to protect tags matching `refs/tags/v*`:

- **Tag creation:** allowed
- **Tag update (force-push):** blocked
- **Tag deletion:** blocked
- **Bypass:** repository admin only

This ensures published skill versions are immutable — a pinned install via `gh skill install --pin v1.0.0` always delivers the same content.

## Agent Skills Specification

All skills in this repository follow the [agentskills.io](https://agentskills.io) open standard. Each skill is a folder containing a `SKILL.md` file with YAML frontmatter and Markdown instructions.

### SKILL.md Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Unique identifier. Lowercase, hyphens, 3-64 chars. Must match directory name. |
| `description` | Yes | When the agent should activate this skill. Be keyword-rich. |
| `allowed-tools` | No | Pre-approved tools (string, e.g., `"shell"`). Omit to require user confirmation. |
| `license` | Recommended | License identifier (e.g., `MIT`). Warning if missing during publish. |

### Skill Discovery Paths

`gh skill` scans the following patterns in a repository:

- `skills/*/SKILL.md`
- `skills/{scope}/*/SKILL.md`
- `.github/skills/*/SKILL.md`
- `.claude/skills/*/SKILL.md`
- `.agents/skills/*/SKILL.md`

This repository uses the top-level `skills/` directory.

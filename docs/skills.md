# Skills Catalog

This document catalogs all Agent Skills available in this repository.

## Overview

| Skill | Description | Version | Scripts |
|-------|-------------|---------|---------|
| [power-platform-connect](#power-platform-connect) | Validates `pac` CLI installation and checks for updates | v1.0.4 | `check-pac.sh` |

---

## power-platform-connect

**Location:** `skills/power-platform-connect/`

**Frontmatter:**

| Field | Value |
|-------|-------|
| `name` | `power-platform-connect` |
| `description` | Check and validate the Power Platform CLI (pac) installation. Use when working with Power Platform, Dataverse, Power Apps, Power Automate, or Dynamics 365. Activates on prompts about pac CLI, Power Platform deployment, environment management, solution packaging, or any Power Platform CLI task. |
| `allowed-tools` | `shell` |
| `license` | `MIT` |

### What It Does

When an agent encounters a Power Platform-related task, this skill activates and:

1. Runs `check-pac.sh` to verify the `pac` CLI is installed
2. Parses the installed version from `pac` output (with fallback to `dotnet tool list --global`)
3. If version cannot be determined, exits with error and suggests reinstalling
4. Fetches the latest version via `dotnet tool search` and compares
5. If `pac` is missing, provides the user with installation instructions
6. If `pac` is outdated, suggests the upgrade command
7. Confirms readiness for Power Platform work once the CLI is installed and up to date

### Files

```
skills/power-platform-connect/
├── SKILL.md                # Skill definition and instructions
└── scripts/
    └── check-pac.sh        # Validates pac CLI installation
```

### Bundled Script: `check-pac.sh`

**Purpose:** Checks whether the `pac` CLI is available on `PATH`, parses the installed version from `pac` output, fetches the latest version via `dotnet tool search`, and reports if an upgrade is available.

**Usage (standalone):**

```bash
bash skills/power-platform-connect/scripts/check-pac.sh
```

**Exit codes:**

| Code | Meaning |
|------|---------|
| `0` | `pac` is installed and either up to date or outdated with warning |
| `1` | `pac` not found, or installed version could not be determined |

### Activation Triggers

The skill activates when the user prompt contains keywords related to:

- Power Platform
- Dataverse
- Power Apps
- Power Automate
- Dynamics 365
- `pac` CLI
- Solution packaging or deployment
- Environment management

### Direct Invocation

From an agent prompt:

```
Use the /power-platform-connect skill
```

From the CLI:

```bash
gh skill install JohannesBertens/power-platform-skills power-platform-connect
```

### Dependencies

- **Bash** 3+
- **`pac` CLI** (Microsoft Power Platform CLI) — the skill itself checks for this and guides installation if missing

To install `pac`:

```bash
dotnet tool install --global Microsoft.PowerApps.CLI.Tool
```

Reference: https://learn.microsoft.com/en-us/power-platform/developer/cli/introduction

---

## Adding a New Skill

To add a new skill to this repository:

1. Create a directory under `skills/<skill-name>/` (lowercase, hyphens, 3+ chars)
2. Add a `SKILL.md` with required frontmatter (`name`, `description`)
3. Optionally add scripts, templates, or reference files
4. Validate: `gh skill publish --dry-run`
5. Publish: `gh skill publish`

See [publishing.md](./publishing.md) for the full workflow.

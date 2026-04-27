---
name: power-platform-connect
description: Check and validate the Power Platform CLI (pac) installation. Use when working with Power Platform, Dataverse, Power Apps, Power Automate, or Dynamics 365. Activates on prompts about pac CLI, Power Platform deployment, environment management, solution packaging, or any Power Platform CLI task.
allowed-tools: shell
license: MIT
---

# Power Platform Connect

## Prerequisites Check

Before performing any Power Platform task, run the bootstrap entrypoint to ensure `pwsh`, `.NET SDK`, and `pac` are all present and up to date.

### Linux / macOS / WSL

```bash
bash skills/power-platform-connect/scripts/ensure-pwsh.sh
```

### Windows

```cmd
skills\power-platform-connect\scripts\ensure-pwsh.cmd
```

### When pwsh is already available

```bash
pwsh skills/power-platform-connect/scripts/check-pac.ps1
```

## Reading the Output

The scripts emit machine-readable status markers that you can act on directly:

| Marker | Meaning |
|--------|---------|
| `STATUS: OK` | `pac` is installed and up to date |
| `STATUS: DEGRADED (latest-version-unavailable)` | `pac` is installed but latest-version lookup failed; treat as a warning |
| `STATUS: ACTION_REQUIRED (pwsh-missing)` | PowerShell 7 could not be installed automatically |
| `STATUS: ACTION_REQUIRED (dotnet-missing)` | .NET SDK 10.x could not be installed automatically |
| `STATUS: ACTION_REQUIRED (admin-required)` | Elevation is needed to install a prerequisite |
| `STATUS: ERROR (pac-install-failed)` | `pac` install step failed |

When `ACTION_REQUIRED` or `ERROR` is emitted, the output also includes:

- `REMEDIATION:` — a single actionable sentence
- `NEXT_COMMAND:` — the exact command to run next
- `DETAIL:` — specific version, path, or failure reason

### If an automatic step fails

Follow the `NEXT_COMMAND` in the output. After completing the manual step, re-run the bootstrap entrypoint to continue.

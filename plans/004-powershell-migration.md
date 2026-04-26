# Plan: PowerShell Migration + Modular Self-Healing Bootstrap

**Date:** 2026-04-26  
**Version:** v1.1.0  
**Status:** Revised

## Summary

Replace the legacy `check-pac.sh` flow with a modular PowerShell-based bootstrap and validation system. Keep thin platform entrypoints for Unix and Windows, move reusable logic into PowerShell helper modules, auto-install or auto-upgrade `pac`, and emit actionable status markers so an LLM using the skill can recover from missing prerequisites without guessing.

## Decisions

| Decision | Choice |
|---|---|
| Primary runtime | PowerShell 7 cross-platform |
| Unix bootstrapper | `ensure-pwsh.sh` remains the only Bash entrypoint |
| Windows bootstrapper | `ensure-pwsh.cmd` as a thin launcher into Windows PowerShell 5.1 |
| Windows PowerShell install method | **Pinned MSI primary** for deterministic machine-wide install; optional `winget --installer-type wix` fallback if it remains available |
| .NET baseline | **.NET SDK 10.0** (`pac` .NET tool docs recommend .NET 10) |
| Script layout | Modular PowerShell helpers under `scripts/modules/` |
| Auto-heal behavior | Install missing `pac`, upgrade outdated `pac`, and provide explicit remediation markers when `pwsh` or `dotnet` are missing |
| Supply-chain policy | Pin artifact versions and verify downloaded installers/archives before execution |
| Degraded-network behavior | Latest-version lookup failures remain non-fatal and emit a distinct degraded marker |

## Current State

- `skills/power-platform-connect/scripts/check-pac.sh` checks whether `pac` is installed and compares the local version to the latest NuGet version.
- The source skill, installed skill copies, and companion agent docs all point directly to `check-pac.sh`.
- There is no PowerShell bootstrap path for missing `pwsh`.
- There is no modular separation between logging, prerequisite handling, and `pac` logic.
- The previous draft plan referenced several install methods that are no longer current:
  - macOS PowerShell via `brew install --cask powershell`
  - Alpine PowerShell via `apk add powershell`
  - Fedora grouped with supported Microsoft PowerShell repo installs
  - Windows `winget install Microsoft.PowerShell` without accounting for the current MSIX default
  - `.NET SDK 8.0` as the required baseline

## Target State

- All reusable logic lives in PowerShell.
- Unix and Windows retain only the minimum entrypoint logic needed to bootstrap `pwsh`.
- `pac` is silently installed when missing and silently upgraded when outdated.
- Missing prerequisite paths produce deterministic machine-readable output with a human-readable remediation command.
- The skill instructions and companion agent docs point to the bootstrap entrypoint instead of the old shell checker.

## Planned File Structure

```text
skills/power-platform-connect/scripts/
├── ensure-pwsh.sh                 # Unix bootstrapper: ensure pwsh, then hand off
├── ensure-pwsh.cmd                # Native Windows launcher
├── ensure-pwsh.ps1                # Windows PowerShell bootstrapper for pwsh + dotnet
├── check-pac.ps1                  # PowerShell 7 entrypoint: ensure dotnet, ensure/update pac
├── modules/
│   ├── Common.ps1                 # logging, status markers, retries, path refresh, version helpers
│   ├── PrereqTools.ps1            # ensure-dotnet, verify-download, platform detection helpers
│   └── PacTools.ps1               # pac discovery, install/update, latest-version lookup
└── (check-pac.sh deleted)
```

## Pinned Artifact Baseline

These versions are current at the time of this plan update and should be treated as the initial pinned baseline for implementation:

| Component | Version |
|---|---|
| PowerShell | `7.6.1` |
| .NET SDK | `10.0.203` |
| PAC CLI | latest from NuGet at runtime |

The implementation should keep these pins easy to update in one place.

## Installation Method Reference (Current)

### PowerShell

| Platform | Current install method to implement |
|---|---|
| Windows | **Primary:** pinned MSI download, SHA256 verify, Authenticode verify, silent `msiexec`; **Fallback:** `winget install --id Microsoft.PowerShell --source winget --installer-type wix` if available |
| macOS | **Primary:** pinned Microsoft `.pkg` with SHA256 verify; optional Homebrew fallback `brew install powershell` may be documented as community-managed, not primary |
| Debian / Ubuntu | Microsoft package repository + `apt-get install -y powershell` |
| RHEL | Microsoft package repository + `dnf install -y powershell` |
| Alpine | pinned `linux-musl` archive with SHA256 verify; install dependencies first |
| Other Linux | pinned `tar.gz` archive to `/opt/microsoft/powershell/7` with `/usr/bin/pwsh` symlink |

### .NET SDK

| Platform | Current install method to implement |
|---|---|
| Windows | `winget install Microsoft.DotNet.SDK.10` when available; fallback to pinned `dotnet-sdk-10.0.203-win-*.exe` with integrity verification |
| macOS | pinned Microsoft `.pkg` with hash verification; Homebrew `brew install --cask dotnet-sdk` may be documented as an optional local convenience path |
| Debian | Microsoft package repository + `apt-get install -y dotnet-sdk-10.0` |
| Ubuntu | Prefer Ubuntu/native package feeds where available; do **not** assume the Microsoft feed is the default path on newer releases |
| RHEL / Fedora / Alpine | use distro-native package repos when available for `.NET 10`; otherwise fall back to pinned Microsoft SDK artifacts |
| Script fallback | `https://dot.net/v1/dotnet-install.sh` or `dotnet-install.ps1` only as automation-oriented fallback, not as the primary persistent machine setup path |

## Implementation Steps

### Step 1 — Replace the old entrypoint model

Move from:

```text
check-pac.sh -> print status
```

To:

```text
ensure-pwsh.(sh|cmd) -> ensure pwsh exists -> hand off to PowerShell modules -> ensure dotnet -> ensure/update pac -> emit final status
```

### Step 2 — Create `scripts/ensure-pwsh.sh`

Bash bootstrapper for Linux, macOS, and WSL.

**Responsibilities**

1. Detect whether `pwsh` is already available.
2. Install `pwsh` using the current platform-specific method listed above.
3. Fail fast when elevation is required but unavailable.
4. Delegate to:

```bash
pwsh -File "<script_dir>/check-pac.ps1" -Bootstrap "$@"
```

**Notes**

- Do not keep `pac`-specific logic in Bash.
- Keep the shell portion focused on the chicken-and-egg problem only.
- For Alpine, use the musl archive path, not `apk add powershell`.
- For generic Linux archive installs, use `/opt/microsoft/powershell/7` and `/usr/bin/pwsh`.

### Step 3 — Create `scripts/ensure-pwsh.cmd`

Thin launcher for native Windows.

**Responsibilities**

1. Invoke Windows PowerShell 5.1:

```cmd
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0ensure-pwsh.ps1" %*
```

2. Avoid embedding the full install logic in batch syntax.

### Step 4 — Create `scripts/ensure-pwsh.ps1`

Windows PowerShell 5.1-compatible bootstrapper.

**Responsibilities**

1. Detect whether `pwsh.exe` is already on `PATH`.
2. If missing, install PowerShell 7 using the pinned MSI path:
   - choose architecture-specific MSI
   - verify SHA256
   - verify Authenticode signature
   - install silently with `ADD_PATH=1`
3. If the MSI path is unavailable but `winget` is present, optionally try:

```powershell
winget install --id Microsoft.PowerShell --source winget --installer-type wix --accept-package-agreements --accept-source-agreements
```

4. Refresh `PATH` in the current process.
5. Delegate to PowerShell 7:

```powershell
pwsh -File "$PSScriptRoot/check-pac.ps1" -Bootstrap @args
```

**Reasoning**

This plan intentionally chooses MSI semantics for the bootstrapper because the current default WinGet path installs MSIX by default, and MSIX has single-user and sandbox-related limitations that are a poor fit for a deterministic prerequisite bootstrap.

### Step 5 — Create modular PowerShell helpers

#### `scripts/modules/Common.ps1`

Shared helpers for:

- consistent log prefixes
- `STATUS:` markers
- `REMEDIATION:` and `NEXT_COMMAND:` lines
- retry wrappers with exponential backoff
- version parsing
- path refresh helpers
- explicit failure helpers that do not silently swallow errors

#### `scripts/modules/PrereqTools.ps1`

Helpers for:

- OS and architecture detection
- download + checksum verification
- Windows signature verification
- `Ensure-DotNetSdk`
- package-manager-specific install wrappers

#### `scripts/modules/PacTools.ps1`

Helpers for:

- discovering `pac`
- parsing installed `pac` version
- reading the latest version from NuGet JSON as the primary source
- optional fallback parsing from `dotnet tool search`
- installing or updating `Microsoft.PowerApps.CLI.Tool`

### Step 6 — Create `scripts/check-pac.ps1`

PowerShell 7 entrypoint.

**Responsibilities**

1. Import the helper modules.
2. If `-Bootstrap` is present, auto-install missing `.NET SDK 10.0`.
3. If `.NET` is still missing, emit an actionable failure.
4. If `pac` is missing:
   - install `Microsoft.PowerApps.CLI.Tool`
   - refresh PATH
   - verify installation
5. Determine installed version.
6. Determine latest version from NuGet JSON.
7. If latest lookup fails, emit degraded status and avoid false “up to date” claims.
8. If outdated, run:

```powershell
dotnet tool update --global Microsoft.PowerApps.CLI.Tool
```

9. Print final status markers.

### Step 7 — Define the output contract for self-healing agents

The scripts should produce both readable diagnostics and machine-friendly markers.

Minimum contract:

```text
STATUS: OK
STATUS: DEGRADED (latest-version-unavailable)
STATUS: ACTION_REQUIRED (pwsh-missing)
STATUS: ACTION_REQUIRED (dotnet-missing)
STATUS: ACTION_REQUIRED (admin-required)
STATUS: ERROR (pac-install-failed)
REMEDIATION: <single actionable sentence>
NEXT_COMMAND: <exact command to run>
DETAIL: <specific reason, version, path, or URL>
```

**Behavior requirements**

- Never return success-shaped text after a failed install step.
- Do not say “up to date” unless both installed and latest versions are known and equal.
- When automatic recovery stops, print the exact bootstrap command the agent should run next.
- Include enough detail that another agent can continue from the output without re-diagnosing the entire environment.

### Step 8 — Update skill and agent instructions

Planned documentation changes:

| File | Required change |
|---|---|
| `skills/power-platform-connect/SKILL.md` | switch the prerequisite command from `check-pac.sh` to the bootstrap entrypoint |
| `skills/power-platform-connect/README.md` | describe the modular layout and self-healing behavior |
| `.github/agents/power-platform-developer.agent.md` | replace direct `check-pac.sh` references |
| `docs/setup.md` | update prerequisites and file tree |
| `docs/skills.md` | update script listing and behavior summary |
| `docs/agents.md` | update example commands and boundaries |
| `README.md` | update top-level skill description if needed |
| `CHANGELOG.md` | record the migration and bootstrap behavior |

### Step 9 — Remove legacy shell checker

Delete:

- `skills/power-platform-connect/scripts/check-pac.sh`
- `.agents/skills/power-platform-connect/scripts/check-pac.sh`
- `.pi/skills/power-platform-connect/scripts/check-pac.sh`

## Testing Strategy

### Bootstrap smoke tests

| Platform | Command | Expected result |
|---|---|---|
| Linux / macOS / WSL | `bash skills/power-platform-connect/scripts/ensure-pwsh.sh` | ensures `pwsh`, then `dotnet`, then installs or updates `pac` |
| Windows | `skills\\power-platform-connect\\scripts\\ensure-pwsh.cmd` | ensures `pwsh`, then `dotnet`, then installs or updates `pac` |
| Any host with pwsh already present | `pwsh skills/power-platform-connect/scripts/check-pac.ps1` | validates or repairs `pac`; if `dotnet` is missing and no bootstrap flag is used, prints an actionable remediation marker |

### Functional assertions

1. Exit code is `0` for success and warning-only degraded states.
2. `pwsh`, `dotnet`, and `pac` resolve after bootstrap.
3. Installed `pac` version is parseable.
4. Final status marker matches the actual outcome.
5. Second run is idempotent and performs no redundant install work.

### Failure-mode assertions

| Scenario | Expected behavior |
|---|---|
| No internet during prerequisite bootstrap | explicit failure with remediation; no false success |
| No internet during latest-version lookup only | `STATUS: DEGRADED (latest-version-unavailable)` |
| Missing admin/sudo rights for system install | `STATUS: ACTION_REQUIRED (admin-required)` plus exact rerun command |
| `pac` install fails | `STATUS: ERROR (pac-install-failed)` with the command that failed |
| Installed version cannot be determined | explicit failure or degraded marker; never claim “up to date” |

## Version Source Contract

1. Primary latest-version source: NuGet machine-readable JSON.
2. Secondary fallback: `dotnet tool search Microsoft.PowerApps.CLI.Tool --take 1`.
3. Final status markers must remain deterministic and stable for automation.

## Version Bump

**v1.0.4 -> v1.1.0**

Reason: non-breaking skill enhancement that changes bootstrap behavior, adds modular PowerShell implementation, updates install methods, and improves agent-facing recovery diagnostics without changing the skill’s overall purpose.

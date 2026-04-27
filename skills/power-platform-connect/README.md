# power-platform-connect

Check and validate the Power Platform CLI (`pac`) installation. Use when working with Power Platform, Dataverse, Power Apps, Power Automate, or Dynamics 365. Activates on prompts about pac CLI, Power Platform deployment, environment management, solution packaging, or any Power Platform CLI task.

## What It Does

When an agent encounters a Power Platform-related task, this skill activates and:

1. Runs the bootstrap entrypoint (`ensure-pwsh.sh` on Unix, `ensure-pwsh.cmd` on Windows)
2. Ensures PowerShell 7 (`pwsh`) is installed, installing it if missing
3. Delegates to `check-pac.ps1` with the `-Bootstrap` flag
4. Ensures `.NET SDK 10.x` is installed, installing it if missing
5. Discovers whether `pac` is on PATH; installs it if missing
6. Compares the installed version to the latest from NuGet; upgrades if outdated
7. Emits a machine-readable `STATUS:` marker and optional `REMEDIATION:` / `NEXT_COMMAND:` / `DETAIL:` lines

## Files

```
skills/power-platform-connect/
├── SKILL.md                      # Skill definition and instructions
├── README.md                     # This file
└── scripts/
    ├── ensure-pwsh.sh            # Unix bootstrapper (Linux, macOS, WSL)
    ├── ensure-pwsh.cmd           # Windows thin launcher
    ├── ensure-pwsh.ps1           # Windows PowerShell 5.1 bootstrapper for pwsh + handoff
    ├── check-pac.ps1             # PowerShell 7 entrypoint: ensure dotnet + ensure/update pac
    └── modules/
        ├── Common.ps1            # Logging, status markers, retry, version helpers, PATH refresh
        ├── PrereqTools.ps1       # OS/arch detection, download + hash verify, Ensure-DotNetSdk
        └── PacTools.ps1          # pac discovery, install/update, latest-version lookup
```

## Usage

### Linux / macOS / WSL

```bash
bash skills/power-platform-connect/scripts/ensure-pwsh.sh
```

### Windows

```cmd
skills\power-platform-connect\scripts\ensure-pwsh.cmd
```

### When pwsh is already present (any platform)

```bash
pwsh skills/power-platform-connect/scripts/check-pac.ps1
```

Add `-Bootstrap` to also auto-install a missing `.NET SDK`:

```bash
pwsh skills/power-platform-connect/scripts/check-pac.ps1 -Bootstrap
```

## Output Contract

All scripts emit structured output for self-healing agents:

```
STATUS: OK
STATUS: DEGRADED (latest-version-unavailable)
STATUS: ACTION_REQUIRED (pwsh-missing)
STATUS: ACTION_REQUIRED (dotnet-missing)
STATUS: ACTION_REQUIRED (admin-required)
STATUS: ERROR (pac-install-failed)
REMEDIATION: <single actionable sentence>
NEXT_COMMAND: <exact command to run>
DETAIL: <version, path, or specific failure reason>
```

**Behavior guarantees:**
- Exit code `0` for `OK` and `DEGRADED`; non-zero for `ACTION_REQUIRED` and `ERROR`
- Never claims "up to date" unless both installed and latest versions are known and equal
- Prints the exact next command when automatic recovery stops
- Second run is idempotent — no redundant installs when prerequisites are already satisfied

## Pinned Versions

| Component | Pinned version |
|-----------|---------------|
| PowerShell | `7.6.1` |
| .NET SDK | `10.0.203` |
| PAC CLI | latest from NuGet at runtime |

Pins are maintained in one place per script:
- `ensure-pwsh.sh` → `PWSH_VERSION`
- `ensure-pwsh.ps1` → `$PwshVersion`
- `modules/PrereqTools.ps1` → `$script:DotNetSdkVersion`

## Activation Triggers

The skill activates when the user prompt contains keywords related to:

- Power Platform
- Dataverse
- Power Apps
- Power Automate
- Dynamics 365
- `pac` CLI
- Solution packaging or deployment
- Environment management

## Direct Invocation

From an agent prompt:

```
Use the /power-platform-connect skill
```

From the CLI:

```bash
gh skill install JohannesBertens/power-platform-skills power-platform-connect
```

## Dependencies

- **Bash** 3+ (for `ensure-pwsh.sh`)
- **Windows PowerShell 5.1** (built into Windows; for `ensure-pwsh.cmd` / `ensure-pwsh.ps1`)
- **PowerShell 7** (`pwsh`) — installed automatically if missing
- **.NET SDK 10.x** — installed automatically if missing
- **`pac` CLI** (`Microsoft.PowerApps.CLI.Tool`) — installed automatically if missing

Reference: https://learn.microsoft.com/en-us/power-platform/developer/cli/introduction

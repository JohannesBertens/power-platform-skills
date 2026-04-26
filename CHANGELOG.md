# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-04-26

### Added

- **power-platform-connect skill** — modular PowerShell bootstrap and self-healing validation ([plan 004](./plans/004-powershell-migration.md))
  - `scripts/ensure-pwsh.sh` — Unix bootstrapper (Linux, macOS, WSL): detects OS, installs PowerShell 7 via the correct platform method, delegates to `check-pac.ps1 -Bootstrap`
  - `scripts/ensure-pwsh.cmd` — Windows thin launcher: invokes Windows PowerShell 5.1 to run `ensure-pwsh.ps1`
  - `scripts/ensure-pwsh.ps1` — Windows PowerShell 5.1 bootstrapper: installs PowerShell 7 via pinned MSI (SHA256 + Authenticode verified) with `winget` fallback, then delegates to `check-pac.ps1`
  - `scripts/check-pac.ps1` — PowerShell 7 entrypoint: ensures .NET SDK 10.x, installs or upgrades `pac`, emits final status markers
  - `scripts/modules/Common.ps1` — shared helpers: consistent log prefixes, `STATUS:` / `REMEDIATION:` / `NEXT_COMMAND:` / `DETAIL:` output contract, retry with exponential backoff, semver parsing/comparison, cross-platform PATH refresh
  - `scripts/modules/PrereqTools.ps1` — OS and architecture detection, download + SHA256 verification, Authenticode verification (Windows), `Ensure-DotNetSdk` with platform-specific install paths (.NET SDK 10.0.203)
  - `scripts/modules/PacTools.ps1` — pac discovery, version parsing, NuGet JSON latest-version lookup with `dotnet tool search` fallback, idempotent install and upgrade

### Changed

- **power-platform-connect skill** — updated documentation throughout
  - `SKILL.md`: switched prerequisite command from `check-pac.sh` to the bootstrap entrypoint; documented status markers and remediation pattern
  - `README.md`: describes the modular layout, all scripts, self-healing behavior, output contract, and pinned versions
  - `docs/setup.md`: updated directory tree and prerequisites table to reflect PowerShell and .NET SDK requirements
  - `docs/skills.md`: updated skill catalog row (version → v1.1.0, scripts list)
  - `docs/agents.md`: replaced `check-pac.sh` references with `ensure-pwsh.sh` in commands and boundaries sections
  - `README.md`: updated top-level skill description

### Removed

- `scripts/check-pac.sh` — replaced by the PowerShell-based bootstrap system



### Fixed

- **power-platform-connect skill** — documentation updates
  - SKILL.md now covers the "version could not be determined" error case
  - Fixed typo `JohannesBohannes` → `JohannesBertens` in docs/setup.md
  - docs/skills.md "What It Does" updated to include version detection failure path

## [1.0.3] - 2026-04-26

### Fixed

- **power-platform-connect skill** — fixed false "up to date" when installed version could not be parsed
  - Search full `pac` output for semver pattern instead of only the first line
  - Exit with error when installed version is unknown instead of claiming "up to date"

## [1.0.2] - 2026-04-26

### Changed

- **power-platform-connect skill** — improved version detection in `check-pac.sh`
  - Parse installed version from `pac` output (e.g. `2.2.1+g666525f`) with fallback to `dotnet tool list --global`
  - Use `dotnet tool search Microsoft.PowerApps.CLI.Tool --take 1` instead of curl-based NuGet API call
  - Always display both installed and latest version for transparency

## [1.0.1] - 2026-04-26

### Changed

- **power-platform-connect skill** — improved `check-pac.sh` and documentation
  - Replaced `pac --version` (non-existent flag) with bare `pac` invocation
  - Added installed version detection via `dotnet tool list --global`
  - Added latest version check against the NuGet API (`api.nuget.org`)
  - Added upgrade suggestion (`dotnet tool update --global Microsoft.PowerApps.CLI.Tool`) when installed version is outdated
  - Updated `SKILL.md` with three-case flow: not installed, outdated, and up to date
  - Removed incorrect `pac install latest` from all documentation
  - Updated `docs/skills.md`, `docs/publishing.md`, and `README.md` to reflect new behavior

## [1.0.0] - 2026-04-26

### Added

- **power-platform-connect skill** — validates `pac` CLI installation and guides users through setup ([plan 001](./archive/001-power-platform-connect-skill.md))
  - `skills/power-platform-connect/SKILL.md` with frontmatter (`name`, `description`, `allowed-tools: shell`, `license: MIT`)
  - `skills/power-platform-connect/scripts/check-pac.sh` — executable script that checks for `pac` on PATH and reports version
- **Tag protection ruleset** (`protect-skill-tags`, ID `15567080`) — blocks update and deletion of tags matching `refs/tags/v*` with admin bypass ([plan 002](./archive/002-tag-protection.md))
- **Documentation**
  - `docs/setup.md` — repository structure, prerequisites, installation, agentskills.io spec reference, `gh` install link
  - `docs/skills.md` — catalog of all skills with frontmatter, activation triggers, bundled scripts, dependencies
  - `docs/publishing.md` — full lifecycle: validate, commit, publish, consume, update, versioning, provenance metadata, troubleshooting
  - `docs/agents.md` — agent definitions guide covering `.agent.md` format, frontmatter reference, tool aliases, best practices from GitHub's analysis of 2,500+ repos, Power Platform example agent, MCP server integration
- **README.md** — updated with skill table, agents summary, install commands, and documentation links
- **`agent-skills` topic** added to repository for `gh skill search` discoverability
- **GitHub Release v1.0.0** published via `gh skill publish`

### Changed

- Tag protection ruleset updated to remove `creation` restriction (initially blocked tag creation, fixed to only block update/deletion)

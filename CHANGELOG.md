# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

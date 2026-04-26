# power-platform-skills

Agent Skills for Power Platform and Dynamics 365, compatible with GitHub Copilot, Claude Code, Cursor, Codex, Gemini CLI, and other agents following the [agentskills.io](https://agentskills.io) open standard.

## Skills

| Skill | Description |
|-------|-------------|
| [power-platform-connect](./skills/power-platform-connect/) | Validates `pac` CLI installation, checks for updates, and guides setup |

## Agents

| Agent | Description |
|-------|-------------|
| [power-platform-developer](./.github/agents/power-platform-developer.agent.md) | Power Platform and Dynamics 365 specialist for solution ALM, Dataverse, pac CLI operations |

Custom agent personas for Copilot can be defined as `.agent.md` files in `.github/agents/`. Unlike skills (procedural knowledge), agents define a specialist persona with specific tools, boundaries, and MCP server access.

See [Agent Definitions Guide](./docs/agents.md) for how to create agents covering the six core areas: commands, testing, project structure, code style, git workflow, and boundaries.

## Install

### Skill

```bash
gh skill install JohannesBertens/power-platform-skills power-platform-connect
```

### Agent definition

```bash
# Project-level (current repo)
mkdir -p .github/agents
gh api repos/JohannesBertens/power-platform-skills/contents/.github/agents/power-platform-developer.agent.md \
  --jq '.content' | base64 -d > .github/agents/power-platform-developer.agent.md

# User-level (all repos)
mkdir -p ~/.copilot/agents
gh api repos/JohannesBertens/power-platform-skills/contents/.github/agents/power-platform-developer.agent.md \
  --jq '.content' | base64 -d > ~/.copilot/agents/power-platform-developer.agent.md
```

Requires GitHub CLI v2.90.0+.

## Documentation

- [Setup Guide](./docs/setup.md) — repository structure, prerequisites, installation
- [Skills Catalog](./docs/skills.md) — detailed documentation for each skill
- [Agent Definitions](./docs/agents.md) — how to create custom agent personas
- [Publishing Guide](./docs/publishing.md) — validating, publishing, and updating skills

## License

MIT

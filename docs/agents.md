# Agent Definitions

This document covers how to create and manage custom agent definitions (`.agent.md` files) for this repository. Custom agents are specialized Copilot personas that focus on specific tasks — as opposed to skills, which provide procedural knowledge.

## Agents vs Skills

| | Skills | Agents |
|---|---|---|
| **Purpose** | Procedural knowledge — *how* to do something | Persona + tooling — *who* does it and with what |
| **File** | `SKILL.md` | `<name>.agent.md` |
| **Location** | `skills/<name>/SKILL.md` | `.github/agents/<name>.agent.md` |
| **Activation** | Loaded when task matches `description` | Selected via agent picker or assigned to issues |
| **Scope** | Task-specific instructions | Full persona with tools, MCP servers, and model selection |

## File Location

Agent profiles live in `.github/agents/`:

```
.github/agents/
└── power-platform-developer.agent.md
```

For user-level agents (available across all projects), use `~/.github/agents/`.

## File Format

Agent profiles are Markdown files with YAML frontmatter. The file naming convention is `<name>.agent.md`, where `<name>` becomes the agent's identifier (lowercase, hyphens, periods, underscores, alphanumeric).

### Frontmatter Properties

| Property | Required | Description |
|----------|----------|-------------|
| `name` | No | Display name. Defaults to the filename (without `.agent.md`). |
| `description` | Yes | What the agent does and when to use it. Used for agent picker display and auto-selection. |
| `tools` | No | List of tool aliases the agent can use. Omit to enable all. Use `[]` to disable all. |
| `model` | No | AI model to use (e.g., `gpt-4.1`, `claude-sonnet-4.5`). IDE-only, ignored on GitHub.com. |
| `target` | No | Restrict to `vscode` or `github-copilot`. Omit for both. |
| `mcp-servers` | No | MCP server configurations specific to this agent. |

### Tool Aliases

| Alias | Purpose |
|-------|---------|
| `read` | Read file contents |
| `edit` | Edit/create files |
| `search` | Search for files or text |
| `execute` / `shell` | Run shell commands |
| `web` | Web search and fetch |
| `agent` | Delegate to another custom agent |
| `todo` | Manage task lists |

Reference MCP tools with `server-name/tool-name` or `server-name/*`.

## Writing Effective Agent Instructions

Based on analysis of 2,500+ agent files (GitHub Blog, Nov 2025), the best agents follow these principles:

### 1. Define a specific persona

Vague instructions fail. Be explicit about who the agent is and what it specializes in.

```markdown
You are a Power Platform solution architect specializing in Dataverse data modeling,
canvas apps, and Power Automate flows. You understand ALM, solution layering, and
environment strategy.
```

### 2. Put commands early

Include the exact commands the agent needs to run, with flags and options.

```markdown
## Commands
- Check prerequisites: `bash skills/power-platform-connect/scripts/ensure-pwsh.sh`
- List environments: `pac env list`
- Export solution: `pac solution export --path ./solutions/ --name <name>`
- Import solution: `pac solution import --path ./solutions/<name>.zip`
- Pack solution: `pac solution pack --zipfile ./*.zip --folder ./src/`
```

### 3. Provide code/style examples

One real example beats paragraphs of description.

### 4. Set clear boundaries

Use a three-tier system:

```markdown
## Boundaries
- Always: Run ensure-pwsh.sh before any pac command, follow ALM best practices
- Ask first: Before deleting environments, modifying managed solutions
- Never: Commit connection strings, export production data, modify system solution layers
```

### 5. Cover six core areas

1. **Commands** — what to run
2. **Testing** — how to validate
3. **Project structure** — where files live
4. **Code style** — conventions to follow
5. **Git workflow** — branching and commit practices
6. **Boundaries** — what not to do

## Example: Power Platform Agent

The repository includes a ready-made agent at `.github/agents/power-platform-developer.agent.md`. Use it as a reference when creating additional agents.

### Install the agent

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

### Template for new agents

```markdown
---
name: solution-architect
description: Designs and manages Power Platform solutions, environments, and Dataverse schema. Use for solution export/import, environment management, ALM tasks, and data model design.
tools: ["read", "edit", "search", "shell"]
---

You are a Power Platform solution architect.

## Persona
- You specialize in Dataverse data modeling, solution ALM, and environment strategy
- You understand canvas apps, model-driven apps, Power Automate, and Power Pages
- You follow Microsoft's recommended practices for Power Platform governance

## Project knowledge
- **Tech Stack:** Power Platform, Dataverse, Power Apps, Power Automate
- **CLI:** pac (Power Platform CLI)
- **File Structure:**
  - `solutions/` – Exported solution files (.zip)
  - `src/` – Unpacked solution source
  - `scripts/` – Helper scripts

## Commands
- Check prerequisites: `bash skills/power-platform-connect/scripts/ensure-pwsh.sh`
- List environments: `pac env list`
- Export solution: `pac solution export --path ./solutions/ --name <name>`
- Unpack solution: `pac solution unpack --zipfile ./solutions/<name>.zip --folder ./src/<name>`
- Pack solution: `pac solution pack --zipfile ./solutions/<name>.zip --folder ./src/<name>`
- Import solution: `pac solution import --path ./solutions/<name>.zip`

## Standards
- Always use unmanaged solutions for development
- Follow solution layering: separate by functional area
- Use environment variables for configuration
- Prefix custom publishers

## Boundaries
- Always: Run ensure-pwsh.sh before pac commands, validate solutions before import
- Ask first: Before deleting environments, exporting from production
- Never: Commit credentials, modify managed layer directly, skip ALM processes
```

## Adding an Agent to This Repository

1. Create `.github/agents/<name>.agent.md` in the repository
2. Define frontmatter (`description` is required; `name` defaults to filename)
3. Write the prompt (max 30,000 characters) following the six core areas
4. Commit and merge to the default branch
5. The agent appears in the Copilot agent picker automatically

### Via GitHub.com

Go to https://github.com/copilot/agents, select the repository, and click **Create an agent**.

### Via CLI

```bash
copilot --agent solution-architect --prompt "List all environments"
```

### Via VS Code / JetBrains

Use the agent dropdown in Copilot Chat → **Configure Custom Agents** → **Create new custom agent**.

## Agent Versioning

Agent profiles are versioned by Git commit SHA. When assigning an agent to a task, it uses the latest version on the branch. Pull requests opened by the agent use the same version for consistency.

For branch-specific agent behavior, maintain different `.agent.md` files on different branches.

## MCP Server Integration

Agents can define MCP servers in their frontmatter for extended capabilities:

```yaml
---
name: dataverse-inspector
description: Inspects Dataverse schema and metadata via MCP
tools: ["read", "search", "dataverse-mcp/*"]
mcp-servers:
  dataverse-mcp:
    type: local
    command: npx
    args: ["-y", "dataverse-mcp-server"]
    env:
      DV_URL: ${{ secrets.DATAVERSE_URL }}
---
```

Secrets are sourced from the `copilot` environment in repository settings.

## Further Reading

- [Creating custom agents for Copilot cloud agent](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/create-custom-agents) — GitHub Docs
- [Custom agents configuration reference](https://docs.github.com/en/copilot/reference/custom-agents-configuration) — GitHub Docs
- [How to write a great agents.md](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/) — GitHub Blog
- [Awesome Copilot agents](https://awesome-copilot.github.com/agents/) — Community examples

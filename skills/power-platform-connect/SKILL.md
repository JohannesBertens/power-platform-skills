---
name: power-platform-connect
description: Check and validate the Power Platform CLI (pac) installation. Use when working with Power Platform, Dataverse, Power Apps, Power Automate, or Dynamics 365. Activates on prompts about pac CLI, Power Platform deployment, environment management, solution packaging, or any Power Platform CLI task.
allowed-tools: shell
license: MIT
---

# Power Platform Connect

## Prerequisites Check

Before performing any Power Platform task, verify the `pac` CLI is installed and up to date by running:

```bash
bash skills/power-platform-connect/scripts/check-pac.sh
```

### If pac is not installed or version cannot be determined

1. Inform the user that the Power Platform CLI is required
2. Provide the install command: `dotnet tool install --global Microsoft.PowerApps.CLI.Tool`
3. Alternatively point to: https://learn.microsoft.com/en-us/power-platform/developer/cli/introduction
4. After installation, re-run the check script to confirm

### If pac is installed but outdated

1. Inform the user of the installed and latest versions
2. Suggest upgrading with: `dotnet tool update --global Microsoft.PowerApps.CLI.Tool`
3. After upgrading, re-run the check script to confirm

### If pac is installed and up to date

Report the installed version and confirm readiness for Power Platform tasks.

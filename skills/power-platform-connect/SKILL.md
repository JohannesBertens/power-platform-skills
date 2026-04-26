---
name: power-platform-connect
description: Check and validate the Power Platform CLI (pac) installation. Use when working with Power Platform, Dataverse, Power Apps, Power Automate, or Dynamics 365. Activates on prompts about pac CLI, Power Platform deployment, environment management, solution packaging, or any Power Platform CLI task.
allowed-tools: shell
license: MIT
---

# Power Platform Connect

## Prerequisites Check

Before performing any Power Platform task, verify the `pac` CLI is installed by running:

```bash
bash skills/power-platform-connect/scripts/check-pac.sh
```

If the check fails (pac not found):

1. Inform the user that the Power Platform CLI is required
2. Provide the install command: `dotnet tool install --global Microsoft.PowerApps.CLI.Tool`
3. Alternatively point to: https://learn.microsoft.com/en-us/power-platform/developer/cli/introduction
4. After installation, run `pac install latest` to ensure the latest version
5. Re-run the check script to confirm

## If pac is installed

Report the installed version and confirm readiness for Power Platform tasks.

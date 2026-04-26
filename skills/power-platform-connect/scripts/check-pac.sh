#!/usr/bin/env bash
set -euo pipefail

if ! command -v pac &>/dev/null; then
  echo "ERROR: pac CLI is not installed."
  echo "Install with: dotnet tool install --global Microsoft.PowerApps.CLI.Tool"
  echo "Docs: https://learn.microsoft.com/en-us/power-platform/developer/cli/introduction"
  exit 1
fi

INSTALLED_VERSION=$(pac 2>&1 | head -1 | grep -oP '\d+\.\d+\.\d+' || true)

if [ -z "$INSTALLED_VERSION" ]; then
  INSTALLED_VERSION=$(dotnet tool list --global 2>/dev/null | grep "Microsoft.PowerApps.CLI.Tool" | awk '{print $2}' || true)
fi

echo "Installed version: ${INSTALLED_VERSION:-unknown}"

LATEST_VERSION=$(dotnet tool search Microsoft.PowerApps.CLI.Tool --take 1 2>/dev/null | grep -i "microsoft.powerapps.cli.tool" | awk '{print $2}')

if [ -z "$LATEST_VERSION" ]; then
  echo "WARNING: Could not fetch latest version from NuGet. Skipping version check."
  exit 0
fi

echo "Latest version:    $LATEST_VERSION"

if [ -n "$INSTALLED_VERSION" ] && [ "$INSTALLED_VERSION" != "$LATEST_VERSION" ]; then
  echo ""
  echo "WARNING: pac CLI is outdated ($INSTALLED_VERSION != $LATEST_VERSION)."
  echo "Upgrade with: dotnet tool update --global Microsoft.PowerApps.CLI.Tool"
  exit 0
fi

echo ""
echo "pac CLI is up to date."

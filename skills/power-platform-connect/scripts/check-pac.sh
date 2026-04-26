#!/usr/bin/env bash
set -euo pipefail

if ! command -v pac &>/dev/null; then
  echo "ERROR: pac CLI is not installed."
  echo "Install with: dotnet tool install --global Microsoft.PowerApps.CLI.Tool"
  echo "Docs: https://learn.microsoft.com/en-us/power-platform/developer/cli/introduction"
  exit 1
fi

echo "pac CLI found:"
pac || true

INSTALLED_VERSION=$(dotnet tool list --global 2>/dev/null | grep "Microsoft.PowerApps.CLI.Tool" | awk '{print $2}')

if [ -z "$INSTALLED_VERSION" ]; then
  echo ""
  echo "WARNING: Could not determine installed pac version via dotnet tool list."
  echo "It may have been installed via MSI or another method."
  exit 0
fi

echo ""
echo "Installed version: $INSTALLED_VERSION"

LATEST_VERSION=$(curl -sf "https://api.nuget.org/v3-flatcontainer/Microsoft.PowerApps.CLI.Tool/index.json" 2>/dev/null | grep -oP '"\K[0-9]+\.[0-9]+\.[0-9]+(?=")' | tail -1)

if [ -z "$LATEST_VERSION" ]; then
  echo "WARNING: Could not fetch latest version from NuGet. Skipping version check."
  exit 0
fi

echo "Latest version:    $LATEST_VERSION"

if [ "$INSTALLED_VERSION" != "$LATEST_VERSION" ]; then
  echo ""
  echo "WARNING: pac CLI is outdated ($INSTALLED_VERSION != $LATEST_VERSION)."
  echo "Upgrade with: dotnet tool update --global Microsoft.PowerApps.CLI.Tool"
  exit 0
fi

echo ""
echo "pac CLI is up to date."

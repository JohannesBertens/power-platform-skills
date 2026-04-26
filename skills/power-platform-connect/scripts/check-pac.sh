#!/usr/bin/env bash
set -euo pipefail

if ! command -v pac &>/dev/null; then
  echo "ERROR: pac CLI is not installed."
  echo "Install with: dotnet tool install --global Microsoft.PowerApps.CLI.Tool"
  echo "Docs: https://learn.microsoft.com/en-us/power-platform/developer/cli/introduction"
  exit 1
fi

echo "pac CLI found:"
pac --version

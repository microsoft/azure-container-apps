# ACA Sandboxes CLI (Early Access)

Command-line interface for Azure Container Apps Sandboxes (Early Access).

## Prerequisites

- **Azure CLI** (`az`) must be installed — [Install Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli)
- Run `az login` at least once before using `aca`. The CLI uses Azure CLI authentication.

## Installation

### Linux / macOS

```sh
curl -fsSL https://raw.githubusercontent.com/microsoft/azure-container-apps/main/docs/early/aca-cli/install.sh | sh
```

To install a specific version:

```sh
curl -fsSL https://raw.githubusercontent.com/microsoft/azure-container-apps/main/docs/early/aca-cli/install.sh | ACA_VERSION=aca-cli-v0.1.0-early-access sh
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/microsoft/azure-container-apps/main/docs/early/aca-cli/install.ps1 | iex
```

To install a specific version:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/microsoft/azure-container-apps/main/docs/early/aca-cli/install.ps1))) -Version aca-cli-v0.1.0-early-access
```

## Uninstall

### Linux / macOS

```sh
curl -fsSL https://raw.githubusercontent.com/microsoft/azure-container-apps/main/docs/early/aca-cli/install.sh | sh -s -- --uninstall
```

### Windows (PowerShell)

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/microsoft/azure-container-apps/main/docs/early/aca-cli/install.ps1))) -Uninstall
```

## Supported Platforms

| Platform | Architecture |
|----------|-------------|
| Linux    | x64, ARM64  |
| macOS    | ARM64       |
| Windows  | x64         |

## Commands

<!-- TODO: Add complete command tree -->

Run `aca --help` to see all available commands.

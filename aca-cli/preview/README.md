# Azure Container Apps Sandboxes CLI (Preview)

The `aca` CLI is the command-line client for Azure Container Apps Sandboxes, now in public preview. These installers fetch the latest release from [GitHub Releases](https://github.com/microsoft/azure-container-apps/releases) and place the `aca` binary on your `PATH`.

## Prerequisites

- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) installed and logged in (`az login`)
- An Azure subscription with a resource group

## Install

### Linux / macOS

```bash
curl -fsSL https://aka.ms/aca-cli-install | sh
```

Pin a specific version:

```bash
curl -fsSL https://aka.ms/aca-cli-install | ACA_VERSION=aca-cli-v0.1.0-preview sh
```

### Windows (PowerShell)

```powershell
irm https://aka.ms/aca-cli-install-windows | iex
```

Pin a specific version:

```powershell
& ([scriptblock]::Create((irm https://aka.ms/aca-cli-install-windows))) -Version aca-cli-v0.1.0-preview
```

## Uninstall

**Linux / macOS:**

```bash
curl -fsSL https://aka.ms/aca-cli-install | sh -s -- --uninstall
```

**Windows (PowerShell):**

```powershell
& ([scriptblock]::Create((irm https://aka.ms/aca-cli-install-windows))) -Uninstall
```

## Supported platforms

| Platform | Architecture |
|----------|--------------|
| Linux    | x64          |
| macOS    | ARM64        |
| Windows  | x64          |

## Current preview release

The installers default to the tag pinned in [`latest-version.txt`](./latest-version.txt) — currently **`aca-cli-v0.1.0-preview`**. See the [release page](https://github.com/microsoft/azure-container-apps/releases/tag/aca-cli-v0.1.0-preview) for archive downloads and release notes.

## Feedback

This is a public preview. File issues and feedback at <https://github.com/microsoft/azure-container-apps/issues>.

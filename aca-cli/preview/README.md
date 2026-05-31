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
irm https://aka.ms/aca-cli-install-ps | iex
```

Pin a specific version:

```powershell
& ([scriptblock]::Create((irm https://aka.ms/aca-cli-install-ps))) -Version aca-cli-v0.1.0-preview
```

## Uninstall

**Linux / macOS:**

```bash
curl -fsSL https://aka.ms/aca-cli-install | sh -s -- --uninstall
```

**Windows (PowerShell):**

```powershell
& ([scriptblock]::Create((irm https://aka.ms/aca-cli-install-ps))) -Uninstall
```

## Supported platforms

| Platform | Architecture |
|----------|--------------|
| Linux    | x64          |
| macOS    | ARM64        |
| Windows  | x64          |

## Current preview release

The installers default to the tag pinned in [`latest-version.txt`](./latest-version.txt) — currently **`aca-cli-v0.1.0-preview`**. See the [release page](https://github.com/microsoft/azure-container-apps/releases/tag/aca-cli-v0.1.0-preview) for archive downloads and release notes.

## Integrity verification

The installers verify the downloaded archive against a SHA-256 hash pinned in [`latest-version.txt`](./latest-version.txt) before extracting it. A mismatch aborts the install. On a successful install you will see a line like:

```
Verified SHA-256: aa16b020f28288efc78d97cdebcbfd74ea6602e32b63f9984775b815c722d741
```

Updating a hash requires a pull request, so the integrity reference lives in git history.

### Verifying a manual download

If you download an archive from the [release page](https://github.com/microsoft/azure-container-apps/releases/tag/aca-cli-v0.1.0-preview), you can verify it yourself against the same pinned value:

**Linux / macOS**

```bash
sha256sum aca-cli-v0.1.0-preview-linux-x64.tar.gz
# or, on macOS without coreutils:
shasum -a 256 aca-cli-v0.1.0-preview-osx-arm64.tar.gz
```

**Windows (PowerShell)**

```powershell
Get-FileHash -Algorithm SHA256 aca-cli-v0.1.0-preview-win-x64.zip
```

Compare the output against the matching line in [`latest-version.txt`](./latest-version.txt).

### Installing an older version

If you pin a version that differs from the one in `latest-version.txt` (via `ACA_VERSION=...` on Linux/macOS or `-Version ...` on Windows), the installer prints a warning and skips the SHA-256 check, since this file only carries the hashes for the currently pinned version.

## Feedback

This is a public preview. File issues and feedback at <https://github.com/microsoft/azure-container-apps/issues>.

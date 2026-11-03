# Azure Container Apps Sandboxes CLI (Preview)

The `aca` CLI is the command-line client for Azure Container Apps Sandboxes, now in public preview. These installers fetch the pinned release from [GitHub Releases](https://github.com/microsoft/azure-container-apps/releases) and install it for the current user by default.

## Prerequisites

- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) installed and logged in (`az login`)
- An Azure subscription with a resource group

## Install

### Linux / macOS

```bash
curl -fsSL https://aka.ms/aca-cli-install | sh
```

The default location is `$HOME/.local/bin`; no sudo is needed for a normal
user-owned home directory. This avoids elevation prompts for developers and
allows installation from noninteractive tools such as canvases.

If that directory is not already on your `PATH`, add this line to your shell
profile (for example, `~/.bashrc` or `~/.zshrc`) and run it in the current terminal:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

#### System-wide or custom installation

Set `INSTALL_DIR` to override the destination. For a system-wide installation:

```bash
curl -fsSL https://aka.ms/aca-cli-install | INSTALL_DIR=/usr/local/bin sh
```

The override applies to the installer (`sh`), not to `curl`. System-wide
installation can require sudo; run it in an interactive terminal with the
necessary administrator permissions. A writable custom directory needs no sudo.
Installing per-user does not replace an older `/usr/local/bin/aca`; check
`command -v aca` to see which installation your shell uses.

### Windows (PowerShell)

```powershell
irm https://aka.ms/aca-cli-install-ps | iex
```

Windows continues to default to the per-user `$env:USERPROFILE\.aca\bin`
directory and adds it to the user's `PATH`.

## Uninstall

**Linux / macOS:**

```bash
curl -fsSL https://aka.ms/aca-cli-install | sh -s -- --uninstall
```

For a system-wide or custom installation, use the same `INSTALL_DIR` used when
installing. This also applies to system-wide installs made before the default
changed:

```bash
curl -fsSL https://aka.ms/aca-cli-install | INSTALL_DIR=/usr/local/bin sh -s -- --uninstall
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

## Feedback

This is a public preview. File issues and feedback at <https://github.com/microsoft/azure-container-apps/issues>.

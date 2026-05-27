# Install the `aca` CLI

The `aca` CLI is the primary surface for sandboxes. It delegates
authentication to the Azure CLI (`az login`).

## Linux / macOS

```bash
curl -fsSL https://raw.githubusercontent.com/microsoft/azure-container-apps/main/docs/early/aca-cli/install.sh | sh
```

Pin a specific version:

```bash
curl -fsSL https://raw.githubusercontent.com/microsoft/azure-container-apps/main/docs/early/aca-cli/install.sh \
  | ACA_VERSION=aca-cli-v0.1.0-early-access sh
```

## Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/microsoft/azure-container-apps/main/docs/early/aca-cli/install.ps1 | iex
```

Pin a specific version:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/microsoft/azure-container-apps/main/docs/early/aca-cli/install.ps1))) -Version aca-cli-v0.1.0-early-access
```

## Verify

```bash
aca --version
# aca 1.0.0-beta.1
```

Then log in and run the doctor:

```bash
az login
aca doctor
```

## Uninstall

```bash
# Linux / macOS
curl -fsSL https://raw.githubusercontent.com/microsoft/azure-container-apps/main/docs/early/aca-cli/install.sh | sh -s -- --uninstall
```

```powershell
# Windows
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/microsoft/azure-container-apps/main/docs/early/aca-cli/install.ps1))) -Uninstall
```

## Supported platforms

| Platform | Architecture |
|---|---|
| Linux   | x64    |
| macOS   | ARM64  |
| Windows | x64    |

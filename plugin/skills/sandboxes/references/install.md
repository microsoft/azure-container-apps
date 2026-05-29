# Install the `aca` CLI

The `aca` CLI is the primary surface for sandboxes. It delegates
authentication to the Azure CLI (`az login`).

## Linux / macOS

```bash
# This same one-liner is also the install path used INSIDE a sandbox or
# container for agent-driven self-installs — no package manager needed.
curl -fsSL https://raw.githubusercontent.com/microsoft/azure-container-apps/main/docs/early/aca-cli/install.sh | sh
```

Pin a specific version:

```bash
curl -fsSL https://raw.githubusercontent.com/microsoft/azure-container-apps/main/docs/early/aca-cli/install.sh \
  | ACA_VERSION=aca-cli-v0.1.0-early-access sh
```

## Windows (PowerShell)

```powershell
# This same one-liner is also the install path used INSIDE a Windows
# sandbox or container for agent-driven self-installs.
irm https://raw.githubusercontent.com/microsoft/azure-container-apps/main/docs/early/aca-cli/install.ps1 | iex
```

Pin a specific version:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/microsoft/azure-container-apps/main/docs/early/aca-cli/install.ps1))) -Version aca-cli-v0.1.0-early-access
```

## Verify

```bash
aca version
# aca 1.0.0-beta.1
```

Then log in and run the doctor (the verb is `aca auth login`, **not**
top-level `aca login`):

```bash
aca auth login   # delegates to `az login` — same Entra identity, same MFA
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

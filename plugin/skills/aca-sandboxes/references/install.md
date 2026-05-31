# Install the `aca` CLI

The `aca` CLI is the primary surface for sandboxes. It delegates
authentication to the Azure CLI — sign in once with `az login` and the
same Entra identity is used by `aca`.

## Linux / macOS

```bash
# This same one-liner is also the install path used INSIDE a sandbox or
# container for agent-driven self-installs — no package manager needed.
curl -fsSL https://aka.ms/aca-cli-install | sh
```

Pin a specific version:

```bash
curl -fsSL https://aka.ms/aca-cli-install \
  | ACA_VERSION=aca-cli-v0.1.0-early-access sh
```

## Windows (PowerShell)

```powershell
# This same one-liner is also the install path used INSIDE a Windows
# sandbox or container for agent-driven self-installs.
irm https://aka.ms/aca-cli-install-ps | iex
```

Pin a specific version:

```powershell
& ([scriptblock]::Create((irm https://aka.ms/aca-cli-install-ps))) -Version aca-cli-v0.1.0-early-access
```

## Verify

```bash
aca --version
```

Then sign in and run the doctor. Both `az login` and `aca auth login`
should be **gated on a status check** — calling either one
unconditionally opens a browser / device-code flow even when a valid
session is already cached, which is bad UX (and breaks in environments
with no interactive browser):

```bash
# bash / zsh
az account show -o none 2>/dev/null || az login
aca auth status >/dev/null 2>&1 || aca auth login
aca doctor
```

```powershell
# PowerShell
az account show -o none 2>$null
if ($LASTEXITCODE -ne 0) { az login }
aca auth status *> $null
if ($LASTEXITCODE -ne 0) { aca auth login }
aca doctor
```

> The CLI verb for `aca` sign-in is **`aca auth login`**. The top-level
> `aca` binary does not have a bare `login` subcommand — always use the
> `auth` namespace. `aca` delegates the underlying Entra flow to
> `az login`, so the same identity / MFA apply.

## Uninstall

```bash
# Linux / macOS
curl -fsSL https://aka.ms/aca-cli-install | sh -s -- --uninstall
```

```powershell
# Windows
& ([scriptblock]::Create((irm https://aka.ms/aca-cli-install-ps))) -Uninstall
```

## Supported platforms

| Platform | Architecture |
|---|---|
| Linux   | x64    |
| macOS   | ARM64  |
| Windows | x64    |

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

Then log in (`aca` delegates auth to `az login`) and run the doctor:

```bash
az login
aca doctor
```

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

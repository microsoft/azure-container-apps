# Install the `aca` CLI

The `aca` CLI is the primary surface for sandboxes. It owns the auth verb
(`aca auth login`), which delegates to Azure CLI (`az login`) under the hood.

## Linux / macOS

```bash
curl -fsSL https://aka.ms/aca-cli-install | sh
```

Pin a specific version:

```bash
curl -fsSL https://aka.ms/aca-cli-install \
  | ACA_VERSION=aca-cli-v0.1.0-early-access sh
```

## Windows (PowerShell)

```powershell
irm https://aka.ms/aca-cli-install-ps | iex
```

Pin a specific version:

```powershell
& ([scriptblock]::Create((irm https://aka.ms/aca-cli-install-ps))) -Version aca-cli-v0.1.0-early-access
```

## Verify

```bash
aca --version
# aca 1.0.0-beta.1
```

Then log in and run the doctor:

```bash
aca auth login
aca doctor
```

> `aca auth login` is the canonical CLI entry point. It delegates to
> `az login` under the hood, so if `az` is already authenticated you can
> skip the login step. Use `aca auth status` to check.

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

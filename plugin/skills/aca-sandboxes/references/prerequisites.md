# CLI prerequisites

## Accounts and access

- **Azure subscription** — one you can create resource groups in.
  [Create one for free](https://azure.microsoft.com/pricing/purchase-options/azure-account).
- **Microsoft Entra ID account** — personal Microsoft accounts are **not** supported.
- **Role** — to create sandboxes inside a group you need the
  `Container Apps SandboxGroup Data Owner` role on the group. The
  [quickstart](quickstart.md) shows how to grant it to yourself.

## Tools

- **[Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli)** installed and logged in (`az login`).
  The `aca` CLI delegates auth to `az login` — same identity, same MFA,
  same conditional-access policies.
- **An Azure subscription with a resource group.**
- **`aca` CLI** — installed in one line; see [install.md](install.md).
- **A shell** — Bash on Linux/macOS; PowerShell or Bash (Git Bash / WSL) on Windows.

## Supported platforms

| Platform | Architecture |
|---|---|
| Linux   | x64    |
| macOS   | ARM64  |
| Windows | x64    |

## Region

Sandboxes are a preview resource type. Start with a well-supported
region such as `eastus2` or `westus2`. If a region rejects the group
create, try another — `aca` will tell you which region the API rejected.

## Doctor checklist

`aca doctor` runs all of the following — green across the board means
you are ready to create sandboxes:

1. Azure CLI found on `PATH`.
2. Azure CLI is logged in (`az account show` succeeds).
3. A default subscription is resolved (flag, env, or config).
4. A default resource group is resolved.
5. A default sandbox group is resolved.
6. A default region is resolved.
7. The sandbox group exists in Azure.
8. The caller has the `Container Apps SandboxGroup Data Owner` role on the group.

Each line in `aca doctor` output also tells you **where** the value came
from — `(flag)`, `(env)`, `(config: sandbox)`, or `(config)` — which is
invaluable when debugging precedence. See
[reference.md](reference.md#config) for the precedence model.

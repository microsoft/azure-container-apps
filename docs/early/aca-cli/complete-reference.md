# `aca` CLI complete reference

Reference documentation for the `aca` CLI. Covers installation, configuration, and the capabilities that aren't already demonstrated by the functional guides. Each section is independent — jump to whichever topic you need.

> Verified against `aca 1.0.0-beta.1`. Every command and output block was executed before being pasted.

## Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Auth](#auth)
- [Help commands](#help-commands)
- [Global flags and short forms](#global-flags-and-short-forms)
- [Environment variables](#environment-variables)
- [Config](#config)
- [`doctor`](#doctor)
- [YAML spec workflow](#yaml-spec-workflow)
- [Selectors](#selectors)
- [Output formats](#output-formats)
- [Verbose and debug](#verbose-and-debug)

---

## Prerequisites

- An **Azure subscription** with a resource group you can create resources in
- The **Azure CLI** (`az`) — installed and logged in. `aca` delegates auth to `az login`.
  - <https://learn.microsoft.com/cli/azure/install-azure-cli>
- A shell — Bash on Linux/macOS, PowerShell or Bash (Git Bash / WSL) on Windows

The `aca` CLI itself is installed in the next section.

[↑ Back to top](#contents)

---

## Installation

### Linux / macOS

```bash
curl -fsSL https://raw.githubusercontent.com/microsoft/azure-container-apps/main/docs/early/aca-cli/install.sh | sh
```

Pin a specific version:

```bash
curl -fsSL https://raw.githubusercontent.com/microsoft/azure-container-apps/main/docs/early/aca-cli/install.sh \
  | ACA_VERSION=aca-cli-v0.1.0-early-access sh
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/microsoft/azure-container-apps/main/docs/early/aca-cli/install.ps1 | iex
```

Pin a specific version:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/microsoft/azure-container-apps/main/docs/early/aca-cli/install.ps1))) -Version aca-cli-v0.1.0-early-access
```

### Uninstall

```bash
# Linux / macOS
curl -fsSL https://raw.githubusercontent.com/microsoft/azure-container-apps/main/docs/early/aca-cli/install.sh | sh -s -- --uninstall
```

```powershell
# Windows
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/microsoft/azure-container-apps/main/docs/early/aca-cli/install.ps1))) -Uninstall
```

### Supported platforms

| Platform | Architecture |
|---|---|
| Linux | x64 |
| macOS | ARM64 |
| Windows | x64 |

### Verify the install

```bash
aca --version
# aca 1.0.0-beta.1
```

[↑ Back to top](#contents)

---

## Quick start

```bash
# 0. Log in to Azure
az login

# 1. Create a resource group (skip if you have one)
az group create --name my-rg --location eastus2

# 2. Create a sandbox group (saves config automatically with --set-config)
aca sandboxgroup create --name my-sandbox-group --location eastus2 --set-config

# 3. Grant yourself data-plane access
aca sandboxgroup role create \
  --role "Container Apps SandboxGroup Data Owner" \
  --principal-id $(az ad signed-in-user show --query id -o tsv)

# 4. Verify setup
aca doctor

# 5. Create a sandbox
aca sandbox create --disk ubuntu
# Created sandbox: a1b2c3d4-…

# 6. Run a command
aca sandbox exec --id <sandbox-id> -c "echo hello world"

# 7. Clean up
aca sandbox delete --id <sandbox-id> --yes
```

[↑ Back to top](#contents)

---

## Auth

`aca` does not maintain its own credential store. Auth is delegated to the Azure CLI — same identity, same MFA, same conditional-access policies.

```bash
aca auth login    # delegates to `az login`
aca auth status   # shows current ARM + data-plane auth
```

`aca auth status` output:

```
✓ ARM authenticated via Azure CLI
✓ Data plane authenticated (https://dynamicsessions.io/.default)
```

### Switching subscriptions

`aca` reads the active Azure CLI account by default. Switch it with `az`:

```bash
az account set --subscription <SUB_ID>
```

Or override per-command:

```bash
aca sandbox list -s <SUB_ID>
```

Or set a default in CLI config:

```bash
aca config set -s <SUB_ID>
```

### Managed identity (Azure-hosted)

When running inside Azure (App Service, Container Apps, VM, Functions), use a managed identity:

```bash
aca sandbox list --managed-identity system            # system-assigned
aca sandbox list --managed-identity <CLIENT_ID_UUID>  # user-assigned
```

Available on every command. Also settable via `ACA_SANDBOX_MANAGED_IDENTITY` or `aca config sandbox set --managed-identity …`.

[↑ Back to top](#contents)

---

## Help commands

Every command, group, and sub-group responds to `--help` (or `-h`). The help text is the source of truth — examples, flags, env-var names, and defaults are all there.

```bash
aca --help                          # top-level: commands + global flags + quick start + scenarios
aca <group> --help                  # group: list of sub-commands
aca <group> <command> --help        # command: arguments, env vars, defaults, examples
aca <group> <command> -h            # short summary
```

Top-level commands:

| Command | Purpose |
|---|---|
| `aca auth`         | Log in and check authentication status |
| `aca config`       | Manage CLI configuration |
| `aca sandboxgroup` | Manage sandbox groups, disks, volumes, secrets, roles, regions |
| `aca sandbox`      | Create and manage sandboxes (exec, shell, files, ports, egress, snapshots) |
| `aca version`      | Show CLI version |
| `aca doctor`       | Check prerequisites, config, and RBAC (8 checks) |
| `aca help`         | Print help for any sub-command |

`aca --help` also prints a **Quick start** block and a **Scenarios** table with copy-pasteable commands for common workflows.

[↑ Back to top](#contents)

---

## Global flags and short forms

Every command accepts these flags. Short forms are listed where they exist.

| Flag | Short | Env var | Description |
|---|---|---|---|
| `--subscription`      | `-s` | `ACA_SUBSCRIPTION`               | Azure subscription ID |
| `--resource-group`    | `-g` | `ACA_RESOURCE_GROUP`             | Resource group |
| `--sandbox-group`     |      | `ACA_SANDBOX_GROUP`              | Default sandbox group (top-level commands) |
| `--group`             |      |                                  | Sandbox group (on `sandbox`/`sandboxgroup` sub-commands) |
| `--region`            |      | `ACA_REGION`                     | Data plane region |
| `--output`            | `-o` |                                  | Output format: `table` (default) or `json` |
| `--managed-identity`  |      | `ACA_SANDBOX_MANAGED_IDENTITY`   | `system` or a client-id UUID |
| `--verbose`           |      |                                  | HTTP traces and resolved config |
| `--debug`             |      |                                  | Verbose + transport details (⚠ may log secrets) |
| `--help`              | `-h` |                                  | Show help |
| `--version`           | `-V` |                                  | Print version (top-level only) |

Sandbox lookup flags (on commands that target a sandbox):

| Flag | Short | Description |
|---|---|---|
| `--id`       |      | Target by UUID |
| `--selector` | `-l` | Target by label selector `"k=v,k2=v2"` |

Other command-specific short forms:

| Flag | Short | Used by |
|---|---|---|
| `--command` | `-c` | `aca sandbox exec`, `aca sandbox shell` |

> The CLI also recognizes `-h` as a short-form of `--help` on every command — useful for a quick summary without the long-form descriptions.

[↑ Back to top](#contents)

---

## Environment variables

Every global flag has an env-var equivalent. Set them once in your shell and skip the flags.

| Env var | Equivalent flag |
|---|---|
| `ACA_SUBSCRIPTION`              | `-s`, `--subscription` |
| `ACA_RESOURCE_GROUP`            | `-g`, `--resource-group` |
| `ACA_SANDBOX_GROUP`             | `--sandbox-group` |
| `ACA_REGION`                    | `--region` |
| `ACA_SANDBOX_MANAGED_IDENTITY`  | `--managed-identity` |

Env wins over CLI config but loses to an explicit flag. See [Config → Precedence](#config) below.

[↑ Back to top](#contents)

---

## Config

`aca` config lives at `~/.aca/config.json` and has two user-facing sections.

### Why customers care

Stop typing `-s … -g … --sandbox-group …` on every command. Set once, work for the rest of the session — with a precedence model that lets CI override anything via env vars without editing files.

### Sections

| Section | What goes there |
|---|---|
| **Shared Defaults** | Subscription, resource group, region — used by every command that doesn't override them. |
| **Sandbox** | Sandbox-specific keys: sandbox group, auto-resume behavior, current sandbox, managed identity, audience, allowed regions, and per-section overrides for sub/RG/region. |

### See your current config

```bash
aca config show
```

Sample output:

```
Configuration:
  Shared Defaults:
    subscription     a59d7183-…
    resource_group   ai-apps-samples-rg
    region           westus2

  Sandbox:
    subscription     (inherited)
    resource_group   (inherited)
    region           westus2
    group            ai-apps-samples-group
    auto_resume      true
    current_sandbox  (not set)
    managed_identity (not set)
    audience         (not set)

Config file: C:\Users\<you>\.aca\config.json
```

`(inherited)` means the Sandbox section inherits from Shared Defaults for that key.

### Set Shared Defaults

```bash
aca config set \
  -s <SUB_ID> \
  -g <RG> \
  --sandbox-group <GROUP> \
  --region westus2
```

| Flag | Effect |
|---|---|
| `-s`, `--subscription` | Default subscription for all commands |
| `-g`, `--resource-group` | Default resource group |
| `--region` | Default data-plane region |
| `--sandbox-group` | Default sandbox group name |

### Set Sandbox-specific config

```bash
aca config sandbox set \
  --group ai-apps-samples-group \
  --auto-resume true \
  --sandbox <UUID>
```

| Flag | Effect |
|---|---|
| `-s`, `--subscription` | Override Shared subscription for sandbox commands only |
| `-g`, `--resource-group` | Override Shared resource group for sandbox commands only |
| `--region` | Override Shared region for sandbox commands only |
| `--group` | Default sandbox group name |
| `--auto-resume true\|false` | Auto-resume a suspended sandbox before operations |
| `--managed-identity system\|<CLIENT_ID>` | Use a managed identity for auth |
| `--audience <URL>` | Override OAuth audience/scope (e.g. `https://dynamicsessions.io/.default`) |
| `--sandbox <UUID>` | "Current" sandbox ID. Pass `""` to clear |
| `--add-region <REGION>` / `--remove-region <REGION>` | Add/remove a region from the allowed list (repeatable) |

When `auto_resume` is `true`, suspended sandboxes resume automatically when you `exec` into them.

### Precedence

For any setting, the CLI resolves in this order (highest wins):

1. **Command-line flag** (e.g. `-s <X>`)
2. **Environment variable** (e.g. `ACA_SUBSCRIPTION=<X>`)
3. **Sandbox-specific config**
4. **Shared Defaults config**

[↑ Back to top](#contents)

---

## `doctor`

`aca doctor` runs 8 prerequisite/config/RBAC checks and tells you what's wrong.

```bash
aca doctor
```

Sample output (all green):

```
✓ Azure CLI found
✓ Azure CLI logged in
✓ Subscription: a59d7183-… (config)
✓ Resource group: ai-apps-samples-rg (config)
✓ Sandbox group: ai-apps-samples-group (config: sandbox)
✓ Region: westus2 (config: sandbox)
✓ Sandbox group 'ai-apps-samples-group' exists in Azure
✓ Container Apps SandboxGroup Data Owner role assigned

aca 1.0.0-beta.1 — all checks passed
```

Each line also shows **where the value came from** — `(config)`, `(config: sandbox)`, `(env)`, `(flag)` — gold when debugging precedence.

### What each check verifies, and how to fix it

| Check | Means | Fix |
|---|---|---|
| Azure CLI found | `az` is on PATH | Install Azure CLI |
| Azure CLI logged in | `az account show` succeeds | `az login` |
| Subscription | Resolves a default subscription | `aca config set -s <ID>` or `az account set` |
| Resource group | Resolves a default RG | `aca config set -g <RG>` |
| Sandbox group | Resolves a default sandbox group | `aca config sandbox set --group <NAME>` |
| Region | Resolves a default region | `aca config sandbox set --region <REGION>` |
| Sandbox group exists | The group resource is found in Azure | `aca sandboxgroup create --name <NAME> --location <REGION> --set-config` |
| Data Owner role | Caller has `Container Apps SandboxGroup Data Owner` on the group | `aca sandboxgroup role create --role "Container Apps SandboxGroup Data Owner" --principal-id $(az ad signed-in-user show --query id -o tsv)` |

[↑ Back to top](#contents)

---

## YAML spec workflow

Define a sandbox in YAML, validate, then apply. CLI-only — the SDK has no equivalent.

This is the infra-as-code story for sandboxes: check specs into git, code-review them, validate in CI before apply, and get editor autocomplete from the published JSON Schema.

### The four commands

| Command | Does |
|---|---|
| `aca sandbox init` | Print a starter spec to stdout |
| `aca sandbox schema` | Print the JSON Schema for sandbox specs (for editor integration) |
| `aca sandbox validate --file <FILE>` | Validate a spec file without creating anything |
| `aca sandbox apply --file <FILE> [--no-wait]` | Create the sandbox from the spec |

### End-to-end

```bash
aca sandbox init > sandbox.yaml
```

Generates:

```yaml
# ACA Sandbox manifest
# Apply with: aca sandbox apply --file sandbox.yaml

disk: ubuntu
resources:
  cpu: 1000m
  memory: 2048Mi
lifecycle:
  autoSuspendPolicy:
    enabled: true
    interval: 300
    mode: Memory
egressPolicy:
  defaultAction: Deny
```

Edit it (set labels, change `cpu`/`memory`, tighten egress), then:

```bash
aca sandbox validate --file sandbox.yaml
aca sandbox apply --file sandbox.yaml
```

Add `--no-wait` to return as soon as the create is accepted (don't wait for Running).

### Editor integration via `schema`

```bash
aca sandbox schema > sandbox.schema.json
```

Point your editor at it (`yaml.schemas` in VS Code, `yaml-language-server` in Neovim) for autocomplete and inline validation.

### Validate in CI

```bash
aca sandbox validate --file sandbox.yaml
```

Exit code is non-zero on failure — drop this into a pre-merge check to catch spec drift before it hits Azure.

[↑ Back to top](#contents)

---

## Selectors

Every command that operates on a sandbox accepts either a UUID or a label selector.

### Why customers care

UUIDs are unmemorable and ephemeral. Selectors let you script against labels you control. `-l "env=ci,role=worker"` works the same in your dev shell, your cleanup cron, your dashboard, and your alerting.

### The two forms

```bash
# By ID (UUID)
aca sandbox exec --id 0d9b1c4e-… -c "echo hello"

# By label selector
aca sandbox exec -l "name=dev" -c "echo hello"
```

### Selector grammar

- `key=value` — match exactly
- `key1=v1,key2=v2` — AND (all pairs must match)
- Spaces around `=` and `,` are **not** allowed
- For `get` and `delete`, the CLI matches the **first** sandbox satisfying the selector

### Set labels at create-time

The flag is `--label key=value`, repeatable:

```bash
aca sandbox create --disk ubuntu \
  --label env=ci \
  --label role=worker \
  --label owner=alice
```

Then operate on it without quoting the UUID:

```bash
aca sandbox exec   -l "env=ci,role=worker" -c "./run.sh"
aca sandbox stop   -l "env=ci,role=worker"
aca sandbox delete -l "env=ci,role=worker"
```

### When to pick which

| Use | Form |
|---|---|
| Long-lived dev sandbox | Selector — friendlier in shell history |
| Output of a previous command | UUID — already in your shell variable |
| Batch over many | `list -o json` + `jq` + UUID loop |
| Cleanup by ownership tag | Selector — labels are your contract |

[↑ Back to top](#contents)

---

## Output formats

Every command supports `-o table|json`. Default is `table`.

| Format | Use |
|---|---|
| `table` | Humans, interactive shells |
| `json`  | Scripts, CI, pipelines |

### Pipe JSON to `jq`

Pull just the IDs:

```bash
aca sandbox list -o json | jq -r '.[].id'
```

Find Running sandboxes labeled `env=ci`:

```bash
aca sandbox list -o json | jq -r '.[] | select(.state=="Running" and .labels.env=="ci") | .id'
```

Bulk delete by tag:

```bash
aca sandbox list -o json \
  | jq -r '.[] | select(.labels.env=="ci") | .id' \
  | xargs -I{} aca sandbox delete --id {} --yes
```

### Diffing snapshots of the same resource

```bash
aca sandbox get --id $ID -o json | jq -S . > before.json
# ... do something ...
aca sandbox get --id $ID -o json | jq -S . > after.json
diff before.json after.json
```

[↑ Back to top](#contents)

---

## Verbose and debug

When a command does the wrong thing, `--verbose` shows exactly what.

### `--verbose`

```bash
aca sandbox list --verbose
```

Outputs:

- The **resolved config** dump (where each value came from: flag, env, sandbox-config, shared-config)
- HTTP **request line**, headers, and status for each call
- Response headers (bodies elided)

### `--debug`

```bash
aca sandbox list --debug
```

Includes everything `--verbose` does **plus** transport-level details (TLS, retries, raw response bodies).

> ⚠ `--debug` may log sensitive data (secret values, tokens in error bodies). Don't share the output of a `--debug` run without reviewing it first.

### Capture to a file

```bash
aca sandbox apply --file sandbox.yaml --verbose 2> aca.log
```

Stdout stays clean for piping; verbose / debug traces go to stderr so you can capture them separately.

[↑ Back to top](#contents)

---

## See also

- [CLI README](./README.md) — overview, install, and capability-by-capability walkthrough
- [Python SDK complete reference](../python-sdk/complete-reference.md) — equivalent reference doc for the Python SDK

# Quick Start

## Install the `aca` CLI

```bash
# macOS (Apple Silicon) / Linux x64
curl -sSL https://raw.githubusercontent.com/microsoft/azure-container-apps/main/docs/early/aca-cli/install.sh | bash

# Windows x64 (PowerShell)
iwr -useb https://raw.githubusercontent.com/microsoft/azure-container-apps/main/docs/early/aca-cli/install.ps1 | iex

# Verify
aca version && aca doctor

# Auth (delegates to az login)
aca auth login
aca auth status
```

> **Note:** The same `curl … install.sh | bash` one-liner is also the path used **inside sandboxes and containers** for agent-driven installs (e.g., when an agent provisions the `aca` CLI inside a fresh `ubuntu` sandbox to manage sibling sandboxes from within).

## Imperative path — create a sandbox group, then a sandbox

```bash
# Sandbox group (one-time per region)
aca sandboxgroup list
aca sandboxgroup create --name mygroup-$USER --location eastus2 --set-config
aca sandboxgroup disk list-public

# Sandbox (with a friendly label so you can target it without remembering the UUID)
aca sandbox create --group mygroup-$USER --disk ubuntu --label name=my-sb

# Use it — label selectors work alongside --id <UUID>
aca sandbox exec     -l name=my-sb -c "uname -a"
aca sandbox port add -l name=my-sb --port 80 --anonymous

# Lifecycle
aca sandbox stop     -l name=my-sb        # suspend (state preserved)
aca sandbox resume   -l name=my-sb        # resume (sub-second)
aca sandbox delete   -l name=my-sb
```

> **Disk catalog (verified):** `ubuntu, copilot, claude, node-22, node-24, php-8.3, php-8.4, dotnet-8, dotnet-9, dotnet-10, python-3.11, python-3.12, python-3.13, python-3.14, nginx, openclaw, ubuntu-systemd` (17 total). Run `aca sandboxgroup disk list-public` to confirm what's available in your region.

## YAML manifest pattern

`aca` 1.0.0-beta.1 supports a declarative workflow: write a sandbox spec in YAML, apply it.

```bash
aca sandbox init > sandbox.yaml       # prints a template
$EDITOR sandbox.yaml
aca sandbox schema                    # (optional) dump full JSON Schema for editor autocomplete
aca sandbox validate --file sandbox.yaml
aca sandbox apply --file sandbox.yaml
```

The generated `sandbox.yaml` covers `group`, `disk` (or `diskId`), `resources` (cpu/memory), `ports`, `env`, `labels`, `lifecycle.autoSuspendPolicy`, and `egressPolicy`. There is **no `-f` short flag** on `validate` or `apply` — use `--file`.

Example `sandbox.yaml` (template output):

```yaml
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

Use the YAML pattern when you want sandbox specs in source control, want repeatable provisioning, or want to manage egress rules / lifecycle policy as code.

## After successful deployment

**Always** ask the user to take a snapshot once an app or template is deployed and verified:

> *"Everything looks good — want me to take a snapshot so you can restore to this state instantly?"*

```bash
aca sandbox snapshot -l name=my-sb --name post-install
```

## Deployment output (mandatory)

After every deployment, the agent **must** output a structured summary:

```
✅ Server deployed and running in sandbox

Sandbox:  <sandbox-id>
Port:     <port-number>
Access:   Anonymous / Entra ID
URL:      https://<sandbox-id>--<port>.proxy.azuredevcompute.io

Test:
  curl https://<sandbox-id>--<port>.proxy.azuredevcompute.io
```

If the URL doesn't respond, check the [ACA portal](https://containerapps.azure.com/sandbox-groups) → Sandbox → Ports.

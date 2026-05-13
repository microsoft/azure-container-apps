# Azure Container Apps Sandboxes CLI (Early Access)

## Prerequisites

- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) installed and logged in (`az login`)
- An Azure subscription with a resource group

## Installation

### Linux / macOS

```bash
curl -fsSL https://raw.githubusercontent.com/microsoft/azure-container-apps/main/docs/early/aca-cli/install.sh | sh
```

To install a specific version:

```bash
curl -fsSL https://raw.githubusercontent.com/microsoft/azure-container-apps/main/docs/early/aca-cli/install.sh | ACA_VERSION=aca-cli-v0.1.0-early-access sh
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/microsoft/azure-container-apps/main/docs/early/aca-cli/install.ps1 | iex
```

To install a specific version:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/microsoft/azure-container-apps/main/docs/early/aca-cli/install.ps1))) -Version aca-cli-v0.1.0-early-access
```

### Uninstall

**Linux / macOS:**

```bash
curl -fsSL https://raw.githubusercontent.com/microsoft/azure-container-apps/main/docs/early/aca-cli/install.sh | sh -s -- --uninstall
```

**Windows (PowerShell):**

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/microsoft/azure-container-apps/main/docs/early/aca-cli/install.ps1))) -Uninstall
```

### Supported Platforms

| Platform | Architecture |
|----------|-------------|
| Linux    | x64, ARM64  |
| macOS    | ARM64       |
| Windows  | x64         |

---

## Quick Start

```bash
# 0. Login to Azure
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
# Created sandbox: a1b2c3d4-...
# Run 'aca sandboxgroup disk list-public' for more options

# 6. Run a command
aca sandbox exec --id <sandbox-id> -c "echo hello world && uname -a"

# 7. Clean up
aca sandbox delete --id <sandbox-id> --yes
```

That's it — zero to sandbox in 5 minutes. Read on for everything else the CLI can do.

---

## Deep Dive

- [Sandbox Lifecycle](#sandbox-lifecycle)
- [Running Commands](#running-commands)
- [File Operations](#file-operations)
- [Port Management](#port-management)
- [Environment Variables & Labels](#environment-variables--labels)
- [YAML Specs](#yaml-specs)
- [Snapshots & Disk Images](#snapshots--disk-images)
- [Custom Resources](#custom-resources)
- [Egress Policies](#egress-policies)
- [Managed Identity](#managed-identity)
- [Sandbox Inception — ACA CLI Inside a Sandbox](#sandbox-inception--aca-cli-inside-a-sandbox)
- [Cross-Group Orchestration](#cross-group-orchestration)
- [Volumes & Secrets](#volumes--secrets)
- [Lifecycle Policies](#lifecycle-policies)
- [Concurrent Operations](#concurrent-operations)
- [Reference](#reference)

---

### Sandbox Lifecycle

```bash
# Create
aca sandbox create --disk ubuntu
# Created sandbox: <id>

# List
aca sandbox list

# Get details
aca sandbox get --id <id>
aca sandbox get --id <id> -o json    # JSON output

# Stop (preserves state)
aca sandbox stop --id <id>

# Resume
aca sandbox resume --id <id>

# Delete
aca sandbox delete --id <id> --yes
```

Use `--no-wait` with stop/resume to return immediately:

```bash
aca sandbox stop --id <id> --no-wait
aca sandbox resume --id <id> --no-wait
```

### Running Commands

```bash
# Simple command
aca sandbox exec --id <id> -c "echo hello"

# Chained commands
aca sandbox exec --id <id> -c "apt update && apt install -y curl"

# Set working directory
aca sandbox exec --id <id> -c "ls -la" --working-directory /tmp

# Pipes work
aca sandbox exec --id <id> -c "echo hello | tr a-z A-Z"
# HELLO

# Exit codes propagate
aca sandbox exec --id <id> -c "exit 42"
# (exits with code 42)
```

For an interactive shell:

```bash
aca sandbox shell --id <id>
# Default: /bin/bash. Override with --command /bin/sh
```

### File Operations

```bash
# List files
aca sandbox fs ls --id <id> --path /

# Read a file
aca sandbox fs cat --id <id> --path /etc/os-release

# Upload a local file
aca sandbox fs write --id <id> --path /tmp/myfile.txt --file ./local-file.txt
```

### Port Management

Expose ports from a sandbox to get a public URL:

```bash
# Add a port
aca sandbox port add --id <id> --port 8080

# Add with anonymous access (no auth required)
aca sandbox port add --id <id> --port 3000 --anonymous

# List exposed ports
aca sandbox port list --id <id>

# Remove a port
aca sandbox port remove --id <id> --port 3000
```

### Environment Variables & Labels

Set env vars and labels at creation time:

```bash
aca sandbox create --disk ubuntu \
  --env API_KEY=sk-xxx \
  --env DATABASE_URL=postgres://... \
  --label app=my-agent \
  --label team=platform \
  --label version=1.0
```

Env vars are available immediately inside the sandbox:

```bash
aca sandbox exec --id <id> -c 'echo $API_KEY'
# sk-xxx
```

Labels are visible in `sandbox get -o json`.

### YAML Specs

Define sandboxes declaratively:

```bash
# Generate a template
aca sandbox init > sandbox.yaml
```

This produces:

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

Then apply it:

```bash
# Validate first
aca sandbox validate --file sandbox.yaml

# Create
aca sandbox apply --file sandbox.yaml
```

View the full JSON Schema:

```bash
aca sandbox schema
```

### Snapshots & Disk Images

**Snapshots** capture sandbox state for quick restore:

```bash
# Create snapshot (sandbox must be running)
aca sandbox snapshot --id <id> --name my-checkpoint

# List snapshots
aca sandboxgroup snapshot list

# Restore — create a new sandbox from the snapshot
aca sandbox create --snapshot my-checkpoint

# Delete snapshot
aca sandboxgroup snapshot delete --name my-checkpoint
```

> **Note:** You cannot snapshot a stopped sandbox — resume it first.

**Commit** saves sandbox state as a reusable disk image:

```bash
# Save as disk image
aca sandbox commit --id <id> --name my-custom-disk

# Create sandbox from committed disk
aca sandbox create --disk my-custom-disk

# List disk images
aca sandboxgroup disk list

# Delete
aca sandboxgroup disk delete --name my-custom-disk
```

You can also create disk images from container images:

```bash
aca sandboxgroup disk create --image docker.io/library/ubuntu:22.04 --name ubuntu-22
```

### Custom Resources

```bash
aca sandbox create --disk ubuntu --cpu 2000m --memory 4096Mi
```

Check resource usage:

```bash
aca sandbox stats --id <id>
```

### Egress Policies

Control outbound network access from sandboxes.

**Quick setup — deny all except specific hosts:**

```bash
aca sandbox egress set --id <id> \
  --default Deny \
  --host-allow "*.github.com"
```

**View current policy:**

```bash
aca sandbox egress show --id <id>
```

**YAML-based policies** for advanced rules (transforms, rewrites):

```bash
# Generate a template
aca sandbox egress init > egress-policy.yaml
```

This produces:

```yaml
defaultAction: Deny

hostRules:
  - pattern: "*.github.com"
    action: Allow
  - pattern: "*.npmjs.org"
    action: Allow

rules:
  # Inject API key — sandbox never sees the secret
  - name: inject-openai-key
    match:
      host: "api.openai.com"
      path: "/v1/*"
      methods: [POST]
    action:
      type: Transform
      headers:
        - operation: Set
          name: Authorization
          value: "Bearer sk-your-api-key"

  # Rewrite internal hostname to real endpoint
  - name: rewrite-internal
    match:
      host: "my-api.internal"
    action:
      type: Rewrite
      host: "real-api.azure.com"
      scheme: https
```

Apply it:

```bash
aca sandbox egress apply --id <id> --file egress-policy.yaml
```

**Export** the current policy as YAML:

```bash
aca sandbox egress export --id <id> > current-policy.yaml
```

**View egress decisions** (what was allowed/denied):

```bash
aca sandbox egress decisions --id <id>
```

### Managed Identity

Assign a system-assigned managed identity to a sandbox group so sandboxes can authenticate to Azure services without credentials.

**Step 1: Assign identity**

```bash
aca sandboxgroup identity assign --name my-sandbox-group --system-assigned
# ✓ Enabled SystemAssigned managed identity
#   Principal ID: <principal-id>
```

**Step 2: Grant the identity permissions**

Grant it the Data Owner role so it can manage sandboxes:

```bash
aca sandboxgroup role create \
  --role "Container Apps SandboxGroup Data Owner" \
  --principal-id <principal-id>
```

> **Tip:** Wait a few seconds after assigning the identity before granting the role — the identity needs time to propagate.

**Step 3: View identity**

```bash
aca sandboxgroup identity show --name my-sandbox-group
```

**Remove identity:**

```bash
aca sandboxgroup identity remove --name my-sandbox-group --system-assigned
```

### Sandbox Inception — ACA CLI Inside a Sandbox

A powerful pattern: run the `aca` CLI **inside** a sandbox to create and manage other sandboxes. This enables AI agents, CI pipelines, and orchestrators that run inside sandboxes to spin up their own isolated environments.

**Step 1: Create sandbox with env vars for zero-flag auth**

```bash
aca sandbox create --disk ubuntu \
  --env AZURE_SUBSCRIPTION_ID=<subscription-id> \
  --env ACA_RESOURCE_GROUP=<resource-group> \
  --env ACA_SANDBOX_GROUP=<sandbox-group> \
  --env ACA_SANDBOXGROUP_REGION=eastus2 \
  --env ACA_MANAGED_IDENTITY=true
```

**Step 2: Install aca inside the sandbox**

```bash
aca sandbox exec --id <id> -c \
  'curl -fsSL https://raw.githubusercontent.com/microsoft/azure-container-apps/main/docs/early/aca-cli/install.sh | sh'
```

**Step 3: Use aca inside with zero flags**

Because the env vars handle all the config, commands inside the sandbox are minimal:

```bash
# List sandboxes — no flags needed
aca sandbox exec --id <id> -c 'aca sandbox list'

# Create a child sandbox — just specify the disk
aca sandbox exec --id <id> -c 'aca sandbox create --disk ubuntu'

# Exec into the child from the parent (sandbox inception!)
aca sandbox exec --id <id> -c 'aca sandbox exec --id <child-id> -c "echo hello from grandchild"'
```

### Cross-Group Orchestration

A sandbox in group A can manage sandboxes in group B — useful for multi-tenant isolation.

**Step 1: Assign MI to group A**

```bash
aca sandboxgroup identity assign --name group-a --system-assigned
# Note the principal-id
```

**Step 2: Grant group A's MI the Data Owner role on group B**

```bash
aca sandboxgroup role create \
  --role "Container Apps SandboxGroup Data Owner" \
  --principal-id <group-a-mi-principal-id> \
  --name group-b
```

**Step 3: From inside a group-A sandbox, create sandboxes in group B**

```bash
aca sandbox exec --id <group-a-sandbox> -c \
  'aca sandbox create --disk ubuntu --managed-identity \
    -s <sub> -g <rg> --group group-b --region eastus2'
```

### Volumes & Secrets

**Volumes** — shared persistent storage across sandboxes:

```bash
# Create a volume
aca sandboxgroup volume create --name shared-data

# Create with specific type
aca sandboxgroup volume create --name data-disk --type DataDisk

# Mount into a sandbox
aca sandbox mount --id <id> --volume shared-data --path /mnt/data

# Mount read-only
aca sandbox mount --id <id> --volume shared-data --path /mnt/data --readonly

# List volumes
aca sandboxgroup volume list

# Delete
aca sandboxgroup volume delete --name shared-data
```

**Secrets** — inject key-value pairs:

```bash
# Create / update
aca sandboxgroup secret upsert --name my-secret --values key1=val1,key2=val2

# List
aca sandboxgroup secret list

# Delete
aca sandboxgroup secret delete --name my-secret
```

### Lifecycle Policies

Auto-suspend sandboxes after idle time to save costs:

```bash
aca sandbox lifecycle set --id <id> --auto-suspend 300
# Sandbox suspends after 5 minutes of inactivity
```

Define in YAML specs:

```yaml
lifecycle:
  autoSuspendPolicy:
    enabled: true
    interval: 300
    mode: Memory
  autoDeletePolicy:
    enabled: true
    deleteIntervalInSeconds: 86400  # 24 hours
```

When `auto_resume` is enabled in config (`aca config set --auto-resume true`), suspended sandboxes automatically resume when you exec into them.

### Concurrent Operations

Create and manage multiple sandboxes in parallel:

```bash
# Parallel create (bash)
for i in 1 2 3; do
  aca sandbox create --disk ubuntu --label batch=$i &
done
wait

# Parallel exec
aca sandbox list -o json | jq -r '.[].id' | while read id; do
  aca sandbox exec --id $id -c "echo sandbox $id ready" &
done
wait
```

---

## Reference

### Environment Variables

| Variable | Description | Equivalent Flag |
|----------|-------------|----------------|
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID | `-s`, `--subscription` |
| `ACA_RESOURCE_GROUP` | Default resource group | `-g`, `--resource-group` |
| `ACA_SANDBOX_GROUP` | Default sandbox group | `--sandbox-group` |
| `ACA_SANDBOXGROUP_REGION` | Region for data plane | `--region` |
| `ACA_MANAGED_IDENTITY` | Use managed identity (`true`) | `--managed-identity` |
| `ACA_MANAGED_IDENTITY_CLIENT_ID` | Client ID for user-assigned MI | `--managed-identity-client-id` |

### Global Flags

Every command accepts these flags:

| Flag | Short | Description |
|------|-------|-------------|
| `--subscription` | `-s` | Azure subscription ID |
| `--resource-group` | `-g` | Resource group |
| `--sandbox-group` | | Default sandbox group (top-level) |
| `--group` | | Sandbox group (on sandbox subcommands) |
| `--region` | | Data plane region |
| `--output` | `-o` | Output format: `table` (default), `json` |
| `--verbose` | | Verbose logging |
| `--debug` | | Debug logging |
| `--managed-identity` | | Use managed identity auth |
| `--help` | `-h` | Show help |

> **Note:** Some commands use `--group` while top-level commands use `--sandbox-group`. Both refer to the sandbox group name.

### Configuration

```bash
# Show current config
aca config show

# Set defaults (saves to ~/.aca/config.json)
aca config set -s <sub> -g <rg> --sandbox-group <group> --region eastus2

# Set auto-resume behavior
aca config set --auto-resume true

# Set managed identity mode
aca config set --managed-identity true
```

### Output Formats

```bash
# Table (default) — human-readable
aca sandbox list

# JSON — for scripting
aca sandbox list -o json

# Pipe to jq for filtering
aca sandbox list -o json | jq '.[].id'
```

### Tips & Gotchas

| Scenario | Behavior |
|----------|----------|
| `sandbox create` with no `--disk` | Uses the default disk image (succeeds) |
| `sandbox delete` on nonexistent ID | Returns success (idempotent) |
| `sandbox snapshot` on stopped sandbox | Fails with 409 — **resume first** |
| Adding duplicate port | Fails with 409 Conflict |
| Removing non-existent port | Fails with 404 |
| `--sandbox-group` vs `--group` | Top-level commands use `--sandbox-group`; sandbox subcommands use `--group` |
| MI role grant immediately after identity assign | May fail with 400 — **wait a few seconds** for propagation |

### Available Roles

```bash
aca sandboxgroup role list
```

| Role | Description |
|------|-------------|
| Container Apps SandboxGroup Data Owner | Full access — create, manage, delete sandboxes |

### Public Disk Images

```bash
aca sandboxgroup disk list-public
```

### Health Check

```bash
aca doctor
# Runs checks: Azure CLI, auth, subscription, resource group, sandbox group, data plane RBAC role
```

### Full Command Tree

```
aca
├── auth
│   ├── login                         Log in to Azure (delegates to az login)
│   └── status                        Show current Azure login status
├── config
│   ├── set                           Set a configuration value
│   └── show                          Show current configuration
├── sandboxgroup
│   ├── create                        Create a sandbox group
│   ├── list                          List sandbox groups
│   ├── get                           Get sandbox group details
│   ├── delete                        Delete a sandbox group
│   ├── regions
│   │   └── list                      List supported regions
│   ├── disk
│   │   ├── create                    Create a disk image
│   │   ├── list                      List disk images
│   │   ├── list-public               List public disk images
│   │   ├── get                       Get a disk image
│   │   └── delete                    Delete a disk image
│   ├── volume
│   │   ├── create                    Create a volume
│   │   ├── list                      List volumes
│   │   ├── get                       Get a volume
│   │   └── delete                    Delete a volume
│   ├── secret
│   │   ├── upsert                    Create or update a secret
│   │   ├── list                      List secrets
│   │   └── delete                    Delete a secret
│   ├── snapshot
│   │   ├── list                      List snapshots
│   │   ├── get                       Get a snapshot
│   │   └── delete                    Delete a snapshot
│   ├── identity
│   │   ├── assign                    Assign a managed identity
│   │   ├── show                      Show current identity
│   │   └── remove                    Remove managed identity
│   └── role
│       ├── list                      List available roles
│       └── assign                    Assign a role
├── sandbox
│   ├── create                        Create a sandbox
│   ├── list                          List sandboxes
│   ├── get                           Get sandbox details
│   ├── delete                        Delete a sandbox
│   ├── exec                          Execute a command in a sandbox
│   ├── shell                         Open an interactive shell
│   ├── stop                          Stop a sandbox
│   ├── resume                        Resume a sandbox
│   ├── commit                        Commit a sandbox to a disk image
│   ├── stats                         Get sandbox stats
│   ├── apply                         Create/update from a YAML spec
│   ├── init                          Print a sandbox spec template
│   ├── schema                        Print the sandbox manifest JSON Schema
│   ├── validate                      Validate a sandbox spec file
│   ├── snapshot                      Create a snapshot from a sandbox
│   ├── mount                         Mount a volume into a sandbox
│   ├── port
│   │   ├── add                       Add an exposed port
│   │   ├── remove                    Remove an exposed port
│   │   └── list                      List exposed ports
│   ├── egress
│   │   ├── set                       Set a simple egress policy
│   │   ├── apply                     Apply egress policy from YAML
│   │   ├── show                      Show current egress policy
│   │   ├── export                    Export egress policy as YAML
│   │   ├── decisions                 Show egress decisions
│   │   ├── schema                    Print egress policy schema
│   │   └── init                      Print egress policy template
│   ├── lifecycle
│   │   └── set                       Set lifecycle policy
│   └── fs
│       ├── ls                        List files
│       ├── cat                       Read a file
│       ├── write                     Write a file into sandbox
│       ├── rm                        Delete a file or directory
│       ├── mkdir                     Create a directory
│       └── stat                      Show file metadata
├── version                           Show CLI version
└── doctor                            Check system prerequisites
```

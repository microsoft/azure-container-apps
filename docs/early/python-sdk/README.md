# Azure Container Apps Sandbox Python SDK (Early Access)

> **Beta** — This SDK is in beta preview. The API surface may change without notice.

Data plane SDK for Azure Container Apps sandboxes. Create sandboxes, run commands, manage files, ports, egress policies, snapshots, and more — all from Python.

## Prerequisites

- Python >= 3.10
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) installed and logged in (`az login`)
- [ACA CLI](https://github.com/microsoft/azure-container-apps/blob/main/docs/early/aca-cli/README.md) for sandbox group setup

## Setup (one-time, using ACA CLI)

```bash
# Create a sandbox group
aca sandboxgroup create --name my-group --location eastus2 --set-config

# Grant yourself data-plane access
aca sandboxgroup role create \
  --role "Container Apps SandboxGroup Data Owner" \
  --principal-id $(az ad signed-in-user show --query id -o tsv)

# Verify
aca doctor
```

## Install

```bash
pip install https://github.com/microsoft/azure-container-apps/releases/download/python-sdk-v0.1.0b1-early-access/azure_containerapps_sandbox-0.1.0b1-py3-none-any.whl
```

## Quick Start

```python
from azure.containerapps.sandbox import SandboxClient

# Uses DefaultAzureCredential (az login, managed identity, env vars)
client = SandboxClient(resource_group="my-rg")

# Create a sandbox
sbx = client.create_sandbox("my-group", disk="ubuntu")
print(f"Created: {sbx.id}")

# Run a command
result = client.exec(sbx.id, "my-group", "echo hello world && uname -a")
print(result.stdout)

# Clean up
client.delete_sandbox(sbx.id, "my-group")
client.close()
```

---

## Clients

### SandboxClient

Data plane operations — create and manage sandboxes.

```python
from azure.containerapps.sandbox import SandboxClient

client = SandboxClient(resource_group="my-rg")
```

### SandboxGroupClient

Management plane operations — create and manage sandbox groups.

```python
from azure.containerapps.sandbox import SandboxGroupClient

mgmt = SandboxGroupClient(resource_group="my-rg")
```

---

## Sandbox Lifecycle

```python
# Create
sbx = client.create_sandbox("my-group", disk="ubuntu")

# List
sandboxes = client.list_sandboxes("my-group")

# Get details
sbx = client.get_sandbox(sandbox_id, "my-group")

# Stop (preserves state)
client.stop_sandbox(sandbox_id, "my-group")

# Resume
client.resume_sandbox(sandbox_id, "my-group")

# Delete
client.delete_sandbox(sandbox_id, "my-group")

# Stats
stats = client.get_stats(sandbox_id, "my-group")
```

## Running Commands

```python
# Execute a command
result = client.exec(sandbox_id, "my-group", "echo hello")
print(result.exit_code, result.stdout, result.stderr)

# Interactive SSH session
client.ssh(sandbox_id, "my-group")
```

## File Operations

```python
# List files
listing = client.list_files(sandbox_id, "my-group", path="/app")

# Read a file
content = client.read_file(sandbox_id, "my-group", path="/etc/os-release")

# Write a file
client.write_file(sandbox_id, "my-group", path="/app/config.json", data=b'{"key": "value"}')

# File metadata
info = client.stat_file(sandbox_id, "my-group", path="/app/config.json")

# Create directory
client.mkdir(sandbox_id, "my-group", path="/app/data")

# Delete
client.delete_file(sandbox_id, "my-group", path="/tmp/scratch")
```

## Port Management

```python
# Expose a port
client.add_port(sandbox_id, "my-group", port=8080)

# Remove a port
client.remove_port(sandbox_id, "my-group", port=8080)

# Update ports
client.update_ports(sandbox_id, "my-group", ports=[{"port": 8080}, {"port": 3000}])
```

## Egress Policies

```python
# Set default policy
client.set_egress_default(sandbox_id, "my-group", default_action="Deny")

# Add host rule
client.add_egress_host_rule(sandbox_id, "my-group", pattern="*.github.com", action="Allow")

# Set full policy
client.set_egress_policy(sandbox_id, "my-group", policy={
    "defaultAction": "Deny",
    "hostRules": [
        {"pattern": "*.github.com", "action": "Allow"},
        {"pattern": "*.npmjs.org", "action": "Allow"},
    ]
})

# Get current policy
policy = client.get_egress_policy(sandbox_id, "my-group")

# View decisions
decisions = client.get_egress_decisions(sandbox_id, "my-group")
```

## Snapshots & Disk Images

```python
# Create snapshot
client.create_snapshot(sandbox_id, "my-group", name="checkpoint-v1")

# Create sandbox from snapshot
sbx = client.create_sandbox("my-group", snapshot="checkpoint-v1")

# Commit sandbox to disk image
client.commit_sandbox(sandbox_id, "my-group", name="my-custom-image")

# Create disk image from container image
client.create_disk_image("my-group", base_image="docker.io/library/ubuntu:22.04", name="ubuntu-22")

# List disk images
images = client.list_disk_images("my-group")

# List public disk images
public = client.list_public_disk_images("my-group")
```

## Volumes

```python
# Create
client.create_volume("my-group", name="shared-data")

# Mount into sandbox
client.add_volume_mount(sandbox_id, "my-group", volume_mount={
    "volumeName": "shared-data",
    "mountPath": "/mnt/data"
})

# List / Get / Delete
volumes = client.list_volumes("my-group")
vol = client.get_volume("shared-data", "my-group")
client.delete_volume("shared-data", "my-group")
```

## Secrets

```python
# Create or update
client.upsert_secret("my-secret", values={"API_KEY": "sk-xxx"})

# List
secrets = client.list_secrets()

# Delete
client.delete_secret("my-secret")
```

## Lifecycle Policies

```python
client.set_lifecycle_policy(sandbox_id, "my-group", policy={
    "autoSuspendPolicy": {
        "enabled": True,
        "interval": 300,
        "mode": "Memory"
    }
})
```

## Sandbox Group Management

```python
from azure.containerapps.sandbox import SandboxGroupClient

mgmt = SandboxGroupClient(resource_group="my-rg")

# Create
group = mgmt.create_group(name="my-group", location="eastus2")

# List
groups = mgmt.list_groups()

# Get
group = mgmt.get_group("my-group")

# Delete
mgmt.delete_group("my-group")

mgmt.close()
```

---

## Authentication

The SDK uses `DefaultAzureCredential` from `azure-identity`, which automatically picks up:

- `az login` (Azure CLI)
- Managed identity (Azure VMs, Container Apps, etc.)
- Environment variables (`AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_CLIENT_SECRET`)
- VS Code, Azure PowerShell, and more

You can also pass any `TokenCredential` from `azure-identity`:

```python
from azure.identity import ManagedIdentityCredential

client = SandboxClient(
    resource_group="my-rg",
    credential=ManagedIdentityCredential()
)
```

```python
from azure.identity import ClientSecretCredential

client = SandboxClient(
    resource_group="my-rg",
    credential=ClientSecretCredential(
        tenant_id="<tenant-id>",
        client_id="<client-id>",
        client_secret="<client-secret>"
    )
)
```

## Dependencies

| Package | Version |
|---------|---------|
| `httpx` | >= 0.25 |
| `websocket-client` | >= 1.6 |
| `azure-core` | >= 1.30 |
| `azure-identity` | >= 1.15 |

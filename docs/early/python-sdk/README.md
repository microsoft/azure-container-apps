# Azure Container Apps Sandbox Python SDK (Early Access)

> **Beta** — This SDK is in beta preview. The API surface may change without notice.

Python SDK for Azure Container Apps sandboxes. Create sandbox groups, sandboxes, run commands, manage files, ports, egress policies, snapshots, and more — all from Python.

## Prerequisites

- Python >= 3.10
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) — run `az login` for local development authentication. On hosted compute (Azure VMs, Container Apps, CI/CD), `DefaultAzureCredential` automatically uses managed identity — no Azure CLI needed.

## Install

```bash
pip install https://github.com/microsoft/azure-container-apps/releases/download/python-sdk-v0.1.0b1-early-access/azure_containerapps_sandbox-0.1.0b1-py3-none-any.whl
```

For management setup (resource group and role assignment):

```bash
pip install azure-mgmt-resource azure-mgmt-authorization
```

---

## Quick Start

```python
import uuid
from azure.identity import DefaultAzureCredential
from azure.mgmt.resource import ResourceManagementClient
from azure.mgmt.authorization import AuthorizationManagementClient
from azure.containerapps.sandbox import (
    SandboxGroupManagementClient,
    SandboxGroupClient,
    endpoint_for_region,
)

credential = DefaultAzureCredential()
subscription_id = "<your-subscription-id>"  # az account show --query id -o tsv
principal_id = "<your-principal-id>"        # az ad signed-in-user show --query id -o tsv
resource_group = "my-rg"
sandbox_group = "my-sandbox-group"
region = "eastus2"

# 1. Create resource group
resource_client = ResourceManagementClient(credential, subscription_id)
resource_client.resource_groups.create_or_update(resource_group, {"location": region})

# 2. Create sandbox group
mgmt = SandboxGroupManagementClient(
    credential, subscription_id=subscription_id, resource_group=resource_group,
)
mgmt.create_group(sandbox_group, location=region)

# 3. Grant data-plane access
auth_client = AuthorizationManagementClient(credential, subscription_id)
scope = f"/subscriptions/{subscription_id}/resourceGroups/{resource_group}"
role_def = next(auth_client.role_definitions.list(
    scope, filter="roleName eq 'Container Apps SandboxGroup Data Owner'"
))
auth_client.role_assignments.create(scope, uuid.uuid4(), {
    "role_definition_id": role_def.id,
    "principal_id": principal_id,
    "principal_type": "User",
})

# 4. Connect to data plane and create a sandbox
client = SandboxGroupClient(
    endpoint_for_region(region), credential,
    subscription_id=subscription_id,
    resource_group=resource_group,
    sandbox_group=sandbox_group,
)
sandbox = client.begin_create_sandbox(disk="ubuntu").result()

# 5. Run a command
result = sandbox.exec("echo hello world && uname -a")
print(result.stdout)

# 6. Clean up
sandbox.delete()
mgmt.delete_group(sandbox_group)
client.close()
mgmt.close()
```

> **Tip:** Get your subscription ID with `az account show --query id -o tsv` and your principal ID with `az ad signed-in-user show --query id -o tsv`.

That's it — zero to sandbox in pure Python. Read on for everything else the SDK can do.

---

## Deep Dive

- [Resource Group Creation](#resource-group-creation)
- [Sandbox Group Management](#sandbox-group-management)
- [Role Assignment](#role-assignment)
- [Sandbox Lifecycle](#sandbox-lifecycle)
- [Running Commands](#running-commands)
- [File Operations](#file-operations)
- [Port Management](#port-management)
- [Egress Policies](#egress-policies)
- [Snapshots & Disk Images](#snapshots--disk-images)
- [Volumes & Secrets](#volumes--secrets)
- [Lifecycle Policies](#lifecycle-policies)
- [Sandbox Inception — SDK Inside a Sandbox](#sandbox-inception--sdk-inside-a-sandbox)
- [Cross-Group Orchestration](#cross-group-orchestration)
- [Reference](#reference)

---

### Resource Group Creation

Uses `azure-mgmt-resource` (`pip install azure-mgmt-resource`):

```python
from azure.identity import DefaultAzureCredential
from azure.mgmt.resource import ResourceManagementClient

credential = DefaultAzureCredential()
subscription_id = "<your-subscription-id>"

resource_client = ResourceManagementClient(credential, subscription_id)

# Create or update a resource group
rg = resource_client.resource_groups.create_or_update(
    "my-rg",
    {"location": "eastus2"},
)
print(f"Resource group: {rg.name} ({rg.properties.provisioning_state})")

# List resource groups
for rg in resource_client.resource_groups.list():
    print(rg.name, rg.location)

# Delete (async — returns immediately, deletion runs in background)
resource_client.resource_groups.begin_delete("my-rg")
```

### Sandbox Group Management

Uses `SandboxGroupManagementClient` (ARM control plane):

```python
from azure.containerapps.sandbox import SandboxGroupManagementClient

mgmt = SandboxGroupManagementClient(
    credential, subscription_id=subscription_id, resource_group=resource_group,
)

# Create (immediate return — ARM may still provision)
group = mgmt.create_group("my-group", location="eastus2")

# Or use LRO poller (waits for provisioning to complete)
group = mgmt.begin_create_group("my-group", location="eastus2").result()

# List
for g in mgmt.list_groups():
    print(g.name, g.location)

# Get
group = mgmt.get_group("my-group")

# Manage identity
mgmt.patch_group_identity("my-group", {"type": "SystemAssigned"})

# Delete
mgmt.delete_group("my-group")

mgmt.close()
```

### Role Assignment

Uses `azure-mgmt-authorization` (`pip install azure-mgmt-authorization`):

```python
import uuid
from azure.identity import DefaultAzureCredential
from azure.mgmt.authorization import AuthorizationManagementClient

credential = DefaultAzureCredential()
subscription_id = "<your-subscription-id>"
resource_group = "my-rg"

auth_client = AuthorizationManagementClient(credential, subscription_id)

# Scope can be at resource group level (covers all sandbox groups in the RG)
scope = f"/subscriptions/{subscription_id}/resourceGroups/{resource_group}"

# Or at sandbox group level (more restrictive)
# scope = f"/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.App/sandboxGroups/my-group"

# Find the role definition
role_name = "Container Apps SandboxGroup Data Owner"
role_def = next(auth_client.role_definitions.list(
    scope, filter=f"roleName eq '{role_name}'"
))

# Assign the role
# Get your principal ID: az ad signed-in-user show --query id -o tsv
principal_id = "<your-principal-id>"

try:
    auth_client.role_assignments.create(
        scope,
        uuid.uuid4(),
        {
            "role_definition_id": role_def.id,
            "principal_id": principal_id,
            "principal_type": "User",  # or "ServicePrincipal" for CI/CD
        },
    )
    print(f"Assigned '{role_name}' — may take a few seconds to propagate")
except Exception as e:
    if "RoleAssignmentExists" in str(e) or "Conflict" in str(e):
        print("Role already assigned")
    else:
        raise
```

> **Note:** Role assignments may take 30–60 seconds to propagate. The SDK's HTTP pipeline automatically retries 403 errors during this window.

### Sandbox Lifecycle

Uses `SandboxGroupClient` to create sandboxes and `SandboxClient` for per-sandbox operations:

```python
from azure.containerapps.sandbox import SandboxGroupClient, endpoint_for_region

client = SandboxGroupClient(
    endpoint_for_region("eastus2"), credential,
    subscription_id=subscription_id,
    resource_group=resource_group,
    sandbox_group="my-group",
)

# Create — returns SandboxClient when sandbox is Running
sandbox = client.begin_create_sandbox(disk="ubuntu").result()

# Create with options
sandbox = client.begin_create_sandbox(
    disk="ubuntu",
    cpu="2000m",
    memory="4096Mi",
    labels={"app": "my-agent", "team": "platform"},
    environment={"API_KEY": "sk-xxx"},
).result()

# List sandboxes
for s in client.list_sandboxes():
    print(s.id, s.state)

# Get sandbox details
info = sandbox.get()

# Stop (preserves state)
sandbox.stop()

# Resume
sandbox.resume()

# Get an alternate SandboxClient for an existing sandbox
other = client.get_sandbox_client("<sandbox-id>")

# Stats
stats = sandbox.get_stats()

# Delete
sandbox.delete()
```

### Running Commands

```python
# Simple command
result = sandbox.exec("echo hello")
print(result.exit_code, result.stdout, result.stderr)

# Chained commands
result = sandbox.exec("apt update && apt install -y curl")

# Exit codes propagate
result = sandbox.exec("exit 42")
assert result.exit_code == 42
```

### File Operations

```python
# Write a file
sandbox.write_file("/app/config.json", '{"key": "value"}')

# Read a file
content = sandbox.read_file("/app/config.json")
print(content.decode())

# List files
listing = sandbox.list_files("/app")

# File metadata
info = sandbox.stat_file("/app/config.json")
print(info.size)

# Create directory
sandbox.mkdir("/app/data")

# Delete file or directory
sandbox.delete_file("/tmp/scratch")
```

### Port Management

Expose ports from a sandbox to get a public URL:

```python
# Add a port (with anonymous access)
port = sandbox.add_port(8080, anonymous=True)
print(port.url)  # public URL

# Remove a port
sandbox.remove_port(8080)

# Update multiple ports
sandbox.update_ports([{"port": 8080}, {"port": 3000}])
```

### Egress Policies

Control outbound network access from sandboxes:

```python
# Set default policy
sandbox.set_egress_default("Deny")

# Add host rules
sandbox.add_egress_host_rule(pattern="*.github.com", action="Allow")

# Set full policy
from azure.containerapps.sandbox import EgressPolicy, EgressHostRule
sandbox.set_egress_policy(EgressPolicy(
    default_action="Deny",
    host_rules=[
        EgressHostRule(pattern="*.github.com", action="Allow"),
        EgressHostRule(pattern="*.npmjs.org", action="Allow"),
    ],
))

# View current policy
policy = sandbox.get_egress_policy()

# View egress decisions (what was allowed/denied)
decisions = sandbox.get_egress_decisions()
```

### Snapshots & Disk Images

**Snapshots** capture sandbox state for quick restore:

```python
# Create snapshot (sandbox must be running)
snap = sandbox.create_snapshot(name="checkpoint-v1")

# Restore — create a new sandbox from the snapshot
restored = client.begin_create_sandbox(snapshot_id=snap.id).result()

# List / get / delete snapshots
snapshots = list(client.list_snapshots())
snap = client.get_snapshot(snap.id)
client.delete_snapshot(snap.id)
```

**Commit** saves sandbox state as a reusable disk image:

```python
# Save as disk image
image = sandbox.commit(name="my-custom-image")

# Create sandbox from committed disk
sbx = client.begin_create_sandbox(disk_id=image.id).result()
```

**Disk images** from container images:

```python
# Create disk image from container image
client.create_disk_image("docker.io/library/ubuntu:22.04", name="ubuntu-22")

# List disk images
images = list(client.list_disk_images())
public = list(client.list_public_disk_images())

# Get / delete
image = client.get_disk_image(image.id)
client.delete_disk_image(image.id)
```

### Volumes & Secrets

**Volumes** — shared persistent storage across sandboxes:

```python
# Create a volume
vol = client.create_volume("shared-data")

# Mount into a sandbox
sandbox.add_volume_mount({"volumeName": "shared-data", "mountPath": "/mnt/data"})

# List / get / delete
volumes = list(client.list_volumes())
vol = client.get_volume("shared-data")
client.delete_volume("shared-data")
```

**Secrets** — inject key-value pairs:

```python
# Create or update
client.upsert_secret("my-secret", {"API_KEY": "sk-xxx"})

# List / peek / delete
for s in client.list_secrets():
    print(s.id)
keys = list(client.list_secret_keys())
val = client.peek_secret("my-secret")
client.delete_secret("my-secret")
```

### Lifecycle Policies

Auto-suspend sandboxes after idle time to save costs:

```python
from azure.containerapps.sandbox import LifecyclePolicy, AutoSuspendPolicy

sandbox.set_lifecycle_policy(LifecyclePolicy(
    auto_suspend=AutoSuspendPolicy(enabled=True, interval=300, mode="Memory"),
))
```

### Sandbox Inception — SDK Inside a Sandbox

A powerful pattern: run the Python SDK **inside** a sandbox to create and manage other sandboxes. This enables AI agents, CI pipelines, and orchestrators that run inside sandboxes to spin up their own isolated environments.

**Step 1: Create a sandbox group with managed identity**

```python
mgmt = SandboxGroupManagementClient(
    credential, subscription_id=subscription_id, resource_group=resource_group,
)
group = mgmt.create_group("my-group", location="eastus2",
    identity={"type": "SystemAssigned"},
)
mi_principal_id = group.identity["principalId"]
```

**Step 2: Grant the managed identity data-plane access**

```python
scope = f"/subscriptions/{subscription_id}/resourceGroups/{resource_group}"
auth_client.role_assignments.create(scope, uuid.uuid4(), {
    "role_definition_id": role_def.id,
    "principal_id": mi_principal_id,
    "principal_type": "ServicePrincipal",
})
```

**Step 3: Create an orchestrator sandbox with env vars for zero-config auth**

```python
orchestrator = client.begin_create_sandbox(
    disk="ubuntu",
    environment={
        "AZURE_SUBSCRIPTION_ID": subscription_id,
        "ACA_RESOURCE_GROUP": resource_group,
        "ACA_SANDBOX_GROUP": "my-group",
        "ACA_SANDBOXGROUP_REGION": "eastus2",
    },
).result()
```

**Step 4: Install SDK and run from inside the sandbox**

```python
# Install SDK inside the sandbox
orchestrator.exec("pip install <sdk-wheel-url> azure-identity --quiet")

# Write a script that creates child sandboxes using managed identity
orchestrator.write_file("/tmp/spawn.py", """
from azure.identity import ManagedIdentityCredential
from azure.containerapps.sandbox import SandboxGroupClient, endpoint_for_region
import os

credential = ManagedIdentityCredential()
client = SandboxGroupClient(
    endpoint_for_region(os.environ["ACA_SANDBOXGROUP_REGION"]),
    credential,
    subscription_id=os.environ["AZURE_SUBSCRIPTION_ID"],
    resource_group=os.environ["ACA_RESOURCE_GROUP"],
    sandbox_group=os.environ["ACA_SANDBOX_GROUP"],
)

# Create a child sandbox from inside the parent
child = client.begin_create_sandbox(disk="ubuntu").result()
result = child.exec("echo hello from child sandbox")
print(result.stdout)
child.delete()
client.close()
""")

# Run it — the sandbox uses managed identity, no az login needed
result = orchestrator.exec("python3 /tmp/spawn.py")
print(result.stdout)  # "hello from child sandbox"
```

### Cross-Group Orchestration

A sandbox in Group A can manage sandboxes in Group B — useful for multi-tenant isolation where an orchestrator creates isolated workspaces for different users or tasks.

```python
import uuid

# Create two sandbox groups
mgmt = SandboxGroupManagementClient(
    credential, subscription_id=subscription_id, resource_group=resource_group,
)

# Orchestrator group — with managed identity
orch_group = mgmt.create_group("orchestrator-group", location="eastus2",
    identity={"type": "SystemAssigned"},
)
mi_principal_id = orch_group.identity["principalId"]

# Worker group — no identity needed
mgmt.create_group("worker-group", location="eastus2")

# Grant orchestrator's MI the Data Owner role on worker group
worker_scope = (
    f"/subscriptions/{subscription_id}/resourceGroups/{resource_group}"
    f"/providers/Microsoft.App/sandboxGroups/worker-group"
)
auth_client.role_assignments.create(worker_scope, uuid.uuid4(), {
    "role_definition_id": role_def.id,
    "principal_id": mi_principal_id,
    "principal_type": "ServicePrincipal",
})

# Now from inside an orchestrator sandbox, the SDK can create
# workers in worker-group using ManagedIdentityCredential
```

---

## Reference

### Three Client Classes

| Client | Scope | Purpose |
|--------|-------|---------|
| `SandboxGroupManagementClient` | ARM control plane | Create/delete sandbox groups, manage identity |
| `SandboxGroupClient` | Data plane (group) | Create sandboxes, disk images, volumes, secrets, snapshots |
| `SandboxClient` | Data plane (sandbox) | Exec, files, ports, egress, lifecycle, stop/resume |

```
SandboxGroupManagementClient  →  create_group()
        ↓
SandboxGroupClient            →  begin_create_sandbox().result()  →  returns SandboxClient
        ↓
SandboxClient                 →  exec(), files, ports, egress, stop/resume
```

### Authentication

Uses `DefaultAzureCredential` from `azure-identity`, which automatically picks up the best available credential:

- **Local development:** `az login` (Azure CLI)
- **Hosted compute:** Managed identity (Azure VMs, Container Apps, AKS, GitHub Actions with federated credentials)
- **CI/CD / Service principals:** Environment variables (`AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_CLIENT_SECRET`)

Pass any `TokenCredential`:

```python
from azure.identity import ManagedIdentityCredential

client = SandboxGroupClient(
    endpoint_for_region("eastus2"),
    ManagedIdentityCredential(),
    subscription_id="...",
    resource_group="...",
    sandbox_group="...",
)
```

```python
from azure.identity import ClientSecretCredential

client = SandboxGroupClient(
    endpoint_for_region("eastus2"),
    ClientSecretCredential(
        tenant_id="<tenant-id>",
        client_id="<client-id>",
        client_secret="<client-secret>",
    ),
    subscription_id="...",
    resource_group="...",
    sandbox_group="...",
)
```

### Dependencies

| Package | Version |
|---------|---------|
| `httpx` | >= 0.25 |
| `websocket-client` | >= 1.6 |
| `azure-core` | >= 1.30 |
| `azure-identity` | >= 1.15 |

Optional (for management setup):

| Package | Purpose |
|---------|---------|
| `azure-mgmt-resource` | Resource group creation |
| `azure-mgmt-authorization` | Role assignment |

### Async Support

The SDK supports both sync and async operations. All client classes are available under `azure.containerapps.sandbox.aio`:

**Sync (default):**

```python
from azure.identity import DefaultAzureCredential
from azure.containerapps.sandbox import SandboxGroupClient, endpoint_for_region

credential = DefaultAzureCredential()
client = SandboxGroupClient(
    endpoint_for_region("eastus2"), credential,
    subscription_id="...", resource_group="...", sandbox_group="...",
)

sandbox = client.begin_create_sandbox(disk="ubuntu").result()
result = sandbox.exec("echo hello")
print(result.stdout)

sandbox.delete()
client.close()
```

**Async:**

```python
import asyncio
from azure.identity.aio import DefaultAzureCredential
from azure.containerapps.sandbox.aio import SandboxGroupClient, endpoint_for_region

async def main():
    credential = DefaultAzureCredential()
    client = SandboxGroupClient(
        endpoint_for_region("eastus2"), credential,
        subscription_id="...", resource_group="...", sandbox_group="...",
    )

    poller = await client.begin_create_sandbox(disk="ubuntu")
    sandbox = await poller.result()
    result = await sandbox.exec("echo hello")
    print(result.stdout)

    await sandbox.delete()
    await client.close()
    await credential.close()

asyncio.run(main())
```

**Parallel sandbox creation (async):**

```python
async def create_batch(client, count=5):
    pollers = [await client.begin_create_sandbox(disk="ubuntu") for _ in range(count)]
    sandboxes = [await p.result() for p in pollers]
    return sandboxes
```

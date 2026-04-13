# Azure Container Apps Sandboxes Overview [Private Preview]

Azure Container Apps Sandboxes is a new first-class resource type (`Microsoft.App/SandboxGroups`) that provides fast, secure, ephemeral compute environments with built-in suspend and resume capabilities. Sandboxes join Container Apps alongside Apps, Jobs, and Dynamic Sessions as a foundational compute primitive.

Key characteristics:

- **Sub-second startup** — sandboxes are provisioned from prewarmed pools.
- **Strong isolation** — each sandbox runs in its own secure boundary, safe for untrusted code.
- **Scale to zero** — pay nothing when idle.
- **Massive scale-out** — burst to thousands of concurrent sandboxes.
- **OCI container image support** — bring your own image.
- **Suspend and resume** — snapshot full state (memory + disk), resume later in sub-second time.

## Prerequisites

- An Azure account with an active subscription. [Create one for free](https://azure.microsoft.com/pricing/purchase-options/azure-account).
- A **Microsoft Entra ID** account. Personal Microsoft accounts are not supported.
- Install the [Azure CLI](/cli/azure/install-azure-cli).

```azurecli
az extension update --name containerapp
```

> [!NOTE]
> You need version **1.3.0b4** or later of the `containerapp` extension. [ASSUMPTION]

## Use Cases

| Scenario | How Sandboxes Help |
|---|---|
| **AI code execution** | Safely run LLM-generated code in isolated environments with instant startup |
| **Development environments** | On-demand, suspendable dev environments that preserve state across sessions |
| **CI/CD pipelines** | Ephemeral build and test environments that scale to zero when idle |
| **Interactive user sessions** | Each user gets their own isolated compute environment |
| **Secure multi-tenant compute** | Strong isolation for running untrusted workloads from multiple tenants |
| **Burst workloads** | Scale from zero to thousands of sandboxes on demand |
| **Agent workflows** | Give AI agents persistent, isolated workspaces that survive across task boundaries |

## Quickstart: Create via Portal

1. Navigate to [containerapps.azure.com](https://containerapps.azure.com/).
2. Select **Sandbox Groups** from the navigation.
3. Click **Create Sandbox Group**.
4. Fill in Subscription, Resource Group, Region, and Name.
5. Optionally expand **Sandbox Defaults** to set default CPU, memory, disk, and timeout.
6. Click **Create Sandbox Group**.

## Quickstart: Create via CLI

```azurecli
# Create a resource group
az group create --name <RESOURCE_GROUP> --location westcentralus

# Create a sandbox group [ASSUMPTION: exact CLI syntax]
az containerapp sandbox-group create \
  --name <SANDBOX_GROUP_NAME> \
  --resource-group <RESOURCE_GROUP> \
  --location westcentralus

# Create a sandbox from a public disk image
az containerapp sandbox create \
  --sandbox-group <SANDBOX_GROUP_NAME> \
  --resource-group <RESOURCE_GROUP> \
  --image ubuntu-22.04
```

---

## Create Sandbox Group — Portal Form

URL: `https://containerapps.azure.com/sandbox-groups/create`

### Basics

| Field | Type | Required | Options / Notes |
|---|---|---|---|
| Subscription | Dropdown | Yes | Lists all Azure subscriptions |
| Resource Group | Dropdown | Yes | Lists resource groups in selected subscription |
| Region | Dropdown | Yes | See [Region Availability](#region-availability) |
| Name | Text input | Yes | Lowercase, e.g. `my-sandbox-group` |

### Networking

> Early preview. Available in the UI only with `sandboxGroupCustomVNet` feature flag enabled.

| Field | Type | Required | Options / Notes |
|---|---|---|---|
| Use Custom VNet | Toggle | No | Default: off |
| VNet | Radio + Dropdown | Conditional | **New** (name + address prefix, e.g. `10.0.0.0/16`) or **Existing** (select from subscription) |
| Subnet | Radio + Dropdown | Conditional | **New** (name + address prefix, e.g. `10.0.0.0/23`) or **Existing** (select from VNet) |

### Sandbox Defaults (collapsible, optional)

| Field | Type | Default | Options |
|---|---|---|---|
| Default CPU | Dropdown | Not set | `0.5`, `1`, `2`, `4` vCPU |
| Default Memory | Dropdown | Not set | `1Gi`, `2Gi`, `4Gi`, `8Gi` |
| Default Disk | Dropdown | Not set | `10Gi`, `20Gi`, `50Gi` |
| Max Sandbox Count | Number input | Not set | Minimum: 1 |
| Default Timeout (seconds) | Number input | Not set | Minimum: 1 |

---

## Sandbox Group Overview

URL: `https://containerapps.azure.com/sandbox-groups/<rg>/<name>/overview`

After creation, the overview page displays read-only properties.

### Overview Card

| Property | Description |
|---|---|
| Name | Sandbox group name |
| Subscription | Subscription ID |
| Resource Group | Resource group name |
| Location | Azure region |
| Provisioning State | Current state (e.g. `Succeeded`) |

### Configuration Card

| Property | Description |
|---|---|
| Default CPU | Default vCPU for new sandboxes, or "Not set" |
| Default Memory | Default memory allocation, or "Not set" |
| Default Disk | Default disk allocation, or "Not set" |
| Max Sandbox Count | Maximum sandboxes allowed, or "Not set" |
| Default Timeout | Default timeout in seconds, or "Not set" |

### Networking Card
> Early preview. Available in the UI only with `sandboxGroupCustomVNet` feature flag enabled.


| Property | Description |
|---|---|
| Use Custom VNet | Yes / No |
| Virtual Network | VNet name (if custom VNet enabled) |
| Subnet | Subnet name (if custom VNet enabled) |

### Tags Card

Displays resource tags as key-value pairs. Only shown if tags exist.

**Actions**: Refresh, Delete sandbox group.

---

## Sandboxes

URL: `https://containerapps.azure.com/sandbox-groups/<rg>/<name>/sandboxes`

Lists all sandboxes in the group with search by ID or labels.

### Sandbox States

| State | Description |
|---|---|
| Running | Actively executing |
| Stopped | User-initiated stop |
| Suspended | Auto-suspended; full state preserved |
| Idle | System-suspended; can auto-resume |
| Resuming | Waking from suspended/idle |
| Stopping | Shutdown in progress |
| Creating | Provisioning |
| Deleting | Teardown in progress |

### Create Sandbox

URL: `https://containerapps.azure.com/sandbox-groups/<rg>/<name>/sandboxes/create`

The portal offers multiple creation paths via a dropdown menu:

- **Standard Sandbox** — full configuration options (described below)
- **GitHub Copilot Sandbox** — pre-configured for Copilot
- **Claude Sandbox** — Claude CLI pre-installed
- **OpenClaw Sandbox** — OpenClaw AI agent pre-installed

#### Card 1: Source

| Field | Type | Required | Options / Notes |
|---|---|---|---|
| Source Type | Radio buttons | Yes | **Public Disk Image**, **Disk Image**, **Snapshot** |
| Public Disk Image | Dropdown | If selected | Lists available public images |
| Disk Image | Dropdown | If selected | Lists private disk images in the group |
| Snapshot | Dropdown | If selected | Lists snapshots in the group |

#### Card 2: Additional Details (collapsible)

| Field | Type | Required | Notes |
|---|---|---|---|
| Labels | Key-value editor | No | Add key-value pairs |
| Entrypoint | Text input | No | Space-separated or JSON array. Not available for snapshot source. |
| Command | Text input | No | Space-separated or JSON array. Not available for snapshot source. |
| Environment Variables | Key-value editor | No | Name-value pairs. Not available for snapshot source. |
| Connections | Accumulator dropdown | No | Select from available ready connections; shown as removable chips |

#### Card 3: Ports (collapsible)

| Field | Type | Notes |
|---|---|---|
| Port | Number | Port number to expose |
| Protocol | Dropdown | `Http`, `Http2` |
| Activation Mode | Dropdown | `Manual`, `Auto` |
| Auth Mode | Dropdown | `EntraId`, `GitHub`, `None` |

#### Card 4: Volumes (collapsible)

| Field | Type | Notes |
|---|---|---|
| Volume | Dropdown | Select from group volumes |
| Mount path | Text input | e.g. `/mnt/data` |
| Read-only | Checkbox | Default: off |

#### Card 5: Lifecycle Policy (collapsible)

| Field | Type | Default | Options |
|---|---|---|---|
| Enable auto-suspend | Checkbox | On | — |
| Idle timeout (seconds) | Number input | 300 | `60`, `120`, `300`, `600`, `1800`, `3600` |
| Suspend Mode | Dropdown | Memory | **Memory** (full snapshot with memory state), **Disk** (preserve disk only, VM restarts fresh) |
| Enable auto-delete | Checkbox | Off | — |
| Delete after (days) | Number input | 1 | Minimum: 0 |

#### Card 6: Network Egress Policy (collapsible)

| Field | Type | Notes |
|---|---|---|
| Default Action | Radio | `Allow` or `Deny` |
| Host Rules | Editor | Domain patterns with allow/deny actions |
| Custom Rules | Editor | Network CIDR rules with actions |
| Skip Egress Proxy | Checkbox | When on, outbound traffic bypasses egress proxy |

#### Card 7: Content Packages (collapsible)

| Field | Type | Notes |
|---|---|---|
| Content Package | Dropdown | Select from available packages |
| Target Path | Text input | Path inside sandbox |
| Action | Dropdown | `Download`, `Mount` |

#### Card 8: Resources

| Field | Type | Default | Notes |
|---|---|---|---|
| Resource Tier | Dropdown | M | See table below. Inherited from snapshot when source is snapshot (read-only). |

**Resource Tiers**

| Tier | CPU | Memory | Disk |
|---|---|---|---|
| XS | 0.25 cores (250m) | 0.5 GB (512Mi) | 20 GB (20Gi) |
| S | 0.5 cores (500m) | 1 GB (1Gi) | 20 GB (20Gi) |
| M (default) | 1 core (1000m) | 2 GB (2Gi) | 20 GB (20Gi) |
| L | 2 cores (2000m) | 4 GB (4Gi) | 40 GB (40Gi) |

### Sandbox Detail Page

URL: `https://containerapps.azure.com/sandbox-groups/<rg>/<name>/sandboxes/<id>`

IDE-style layout with terminal (top ~65%) and tabbed panels (bottom ~35%).

**Actions toolbar:**

| Action | Description |
|---|---|
| Resume | Wake a suspended/stopped sandbox |
| Stop | Gracefully stop a running sandbox |
| Snapshot | Capture current state (memory + disk) as a snapshot |
| Commit | Save current disk state as a new disk image |
| Delete | Permanently delete the sandbox |
| Add Port | Expose a new port |
| Details | Open side panel with full properties |

**Tabbed panels:**

| Tab | Description |
|---|---|
| Network Audit | Egress traffic log — allowed and denied requests |
| Monitor | Real-time CPU, memory, disk, network stats |
| Processes | Running process list |
| Files | File explorer / directory browser |
| Log Stream | Streaming container logs |
| Connections | Attached connections with "Add" action |
| Volumes | Mounted volumes with "Add" action |

**Details side panel** shows: ID, State, Created timestamp, CPU, Memory, Disk, Source (image/snapshot), Port mappings, Labels, Lifecycle policies, Connections, Volumes.

---

## Disk Images

URL: `https://containerapps.azure.com/sandbox-groups/<rg>/<name>/disk-images`

Disk images are OCI container images converted for use as sandbox root filesystems. The page has two tabs: **Private** and **Public**.

**Actions**: Create Disk Image, Refresh.

### Create Disk Image

URL: `https://containerapps.azure.com/sandbox-groups/<rg>/<name>/disk-images/create`

#### Image Configuration

| Field | Type | Required | Notes |
|---|---|---|---|
| Base Image URL | Text input | Yes | OCI image ref, e.g. `mcr.microsoft.com/devcontainers/base:ubuntu` |
| Entrypoint | Text input | No | Comma-separated, e.g. `/bin/bash, -c` |
| Command | Text input | No | Comma-separated, e.g. `sleep, infinity` |

#### Registry Authentication

| Option | Fields | Notes |
|---|---|---|
| No authentication | — | Default; for public registries |
| Username and token | Username (text), Token/Password (password) | For private registries |
| Managed identity (for ACR) | User-assigned identity (dropdown) | Feature-flagged (`diskImageManagedIdentity`). Requires identity assigned on Identity page. |

#### Labels

Key-value editor for optional labels.

### Disk Image Detail

| Property | Description |
|---|---|
| ID | Unique image identifier |
| Name | Display name (optional) |
| Base Image | OCI image reference |
| Entrypoint | Container entrypoint args |
| Command | Container command args |
| State | Building, Ready, Failed |
| Error | Error message (if failed) |
| Created / Updated | Timestamps |
| Labels | Key-value pairs |
| Dockerfile | Dockerfile content (if applicable) |

**Actions**: Create Sandbox from this image, Refresh, Delete.

---

## Snapshots

URL: `https://containerapps.azure.com/sandbox-groups/<rg>/<name>/snapshots`

Snapshots capture full sandbox state (memory + disk). Create a snapshot by suspending a sandbox or using the Snapshot action on the sandbox detail page.

**Actions**: Refresh.

### Snapshot Detail

| Property | Description |
|---|---|
| ID | Unique snapshot identifier |
| Source Sandbox | ID of the sandbox this snapshot was taken from |
| VMM Type | Virtualization type (e.g. `CloudHypervisor`) |
| Labels | Key-value pairs |
| CPU | CPU allocation at time of snapshot |
| Memory | Memory allocation at time of snapshot |
| Disk | Disk allocation at time of snapshot |
| GPU SKU / Quantity | GPU info (if applicable) |
| Source Pod Containers | Container names and disk image IDs |
| Created | Timestamp |

**Actions**: Create Sandbox from snapshot, Refresh, Delete.

---

## Volumes

URL: `https://containerapps.azure.com/sandbox-groups/<rg>/<name>/volumes`

Persistent storage that can be mounted into sandboxes.

**Actions**: Create Volume, Search, Bulk delete (when items selected).

### Create Volume

| Field | Type | Required | Options |
|---|---|---|---|
| Volume Name | Text input | Yes | e.g. `my-volume` |
| Volume Type | Radio buttons | Yes | **Azure Blob** (default), **Data Disk** |
| Size | Text input | If Data Disk | e.g. `1Gi`, `10Gi` |

### Volume Types

| Type | Description | Features |
|---|---|---|
| **Azure Blob** | Cloud object storage | File explorer with upload/download/delete, storage usage stats, blob count |
| **Data Disk** | Block storage | Size display, attached/available state, mounted sandboxes list |

### Volume Detail — Azure Blob

| Section | Properties |
|---|---|
| Usage | Storage bytes used, Blob count |
| File Explorer | Browse, upload, download, create folder, delete files. Drag-and-drop upload. Overwrite toggle. |
| Mounted Sandboxes | List of sandboxes using this volume |

### Volume Detail — Data Disk

| Section | Properties |
|---|---|
| Data Disk Info | Size, State (Attached / Available) |
| Mounted Sandboxes | List of sandboxes using this volume |

**Actions**: Details panel, Delete.

---

## Secrets

URL: `https://containerapps.azure.com/sandbox-groups/<rg>/<name>/secrets`

Key-value secrets scoped to the sandbox group.

**Actions**: Add secret, Search by ID.

### Secrets Table

| Column | Description |
|---|---|
| Name / ID | Secret identifier |
| Created / Updated | Timestamps |
| Actions | Edit, Delete |

### Create / Edit Secret Dialog

| Field | Type | Required | Notes |
|---|---|---|---|
| Secret ID | Text input | Yes (create) | Read-only on edit |
| Key-Value Pairs | Dynamic list | Yes | Key (text) + Value (text). Add/remove pairs. |

---

## Identity

URL: `https://containerapps.azure.com/sandbox-groups/<rg>/<name>/identity`

Manage managed identities for the sandbox group.

### System-Assigned Identity

| Field | Type | Notes |
|---|---|---|
| Status | Toggle | Enable or disable system-assigned identity |
| Principal ID | Read-only | Displayed when enabled |
| Role Assignments | Table | Role Name, Scope, Actions (Add/Remove) |

### User-Assigned Identities

| Column | Description |
|---|---|
| Identity Name | Name of the user-assigned managed identity |
| Resource ID | Full ARM resource ID |
| Actions | Manage Roles, Remove |

**Add User-Assigned Identity**: Select from available identities in the subscription via a dropdown dialog.

**Add Role Assignment** dialog:

| Field | Type | Notes |
|---|---|---|
| Scope | Text | ARM resource scope |
| Role Definition | Dropdown | Available RBAC role definitions |

### Identity Types

| Type | Value |
|---|---|
| None | No managed identity |
| SystemAssigned | System-assigned only |
| UserAssigned | User-assigned only |
| SystemAssigned,UserAssigned | Both |

---

## Filing Issues

If you encounter issues during the private preview, file an issue on the [Azure Container Apps GitHub repository](https://github.com/microsoft/azure-container-apps/). Start the issue title with **[SPP]** to identify it as a Sandboxes Private Preview issue. 

Example: `[SPP] Snapshot creation fails for large memory sandboxes`

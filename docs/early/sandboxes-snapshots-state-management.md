---
title: Snapshots and state management for Azure Container Apps sandboxes (preview)
description: Understand how Azure Container Apps sandboxes preserve state through suspend modes, snapshots, and restore semantics.
ms.topic: concept-article
ms.service: azure-container-apps
ms.date: 04/30/2026
---

# Snapshots and state management for Azure Container Apps sandboxes (preview)

Azure Container Apps sandboxes are isolated, lightweight VMs designed for short interactive sessions and long-running agentic workloads. Both types need a way to pause work and resume it later without losing in-memory progress. This article explains the state model, how snapshots fit into it, and how to choose between the implicit (auto-suspend) and explicit (snapshot) paths to preserving state.

> **Note:** Azure Container Apps sandboxes are currently in private preview. Contact your Microsoft representative for access.

## What "state" means in a sandbox

A running sandbox has three layers of state:

- **In-memory state** — process memory, open file descriptors, established network connections, and anything else the kernel and your processes hold in RAM.
- **Local disk state** — the sandbox's root filesystem, including any files written under `/tmp`, `/home`, or the working directory.
- **External state** — anything written to attached volumes, object storage, databases, or upstream services.

External state is naturally durable. Local disk and in-memory state are tied to the sandbox's lifetime, so the platform provides two mechanisms to preserve them across pauses and restarts.

## Sandbox lifecycle

A sandbox transitions through four primary states:

| State | Meaning |
|---|---|
| **Running** | Actively executing your workload. |
| **Idle** | The sandbox is running but didn't receive traffic or exec calls within the configured idle window. |
| **Suspended** | The sandbox is suspended either automatically (lifecycle policy) or explicitly. Compute is released. |
| **Resuming** | The platform is reactivating a suspended sandbox. Resume is sub-second when memory state is preserved. |

The lifecycle policy on the sandbox group controls automatic transitions. Snapshots are an orthogonal mechanism that captures full state independent of the lifecycle.

## Two ways to preserve state

### Implicit: lifecycle policy and auto-suspend

Every sandbox group has a lifecycle policy that controls auto-suspend behavior:

- **Idle timeout** — how long the sandbox can sit idle before suspending. Common values are 60, 120, 300, 600, 1800, and 3600 seconds.
- **Suspend mode** — what to preserve when suspending.
- **Auto-delete** — whether to delete suspended sandboxes after a configurable retention window.

Auto-suspend keeps your sandboxes available for a fast resume without you having to write any snapshot code. It's the right choice when most of your sandboxes follow a predictable idle-then-resume pattern (interactive sessions, agent reasoning loops with pauses).

### Explicit: the snapshot action

A snapshot is a captured copy of a sandbox's full state at a point in time. Unlike auto-suspend, snapshots persist independently of the source sandbox. You can:

- Create a snapshot, delete the source sandbox, and create a new sandbox from the snapshot later.
- Capture multiple snapshots from the same sandbox over time as checkpoints.
- Use snapshots to move a workload from one sandbox to another after the original has been deleted.

## What a snapshot captures

Each snapshot records the following properties:

| Property | Description |
|---|---|
| **ID** | Unique snapshot identifier. |
| **Source sandbox** | ID of the sandbox the snapshot was captured from. |
| **VMM type** | Virtualization type used when the snapshot was taken (for example, `CloudHypervisor`). |
| **CPU / memory / disk** | Resource allocation at the moment of capture. These values become the resource tier of any sandbox restored from the snapshot. |
| **GPU SKU and quantity** | GPU information if the source sandbox had GPU resources. |
| **Source pod containers** | Container names and disk image IDs that made up the source sandbox. |
| **Labels** | User-defined key-value pairs for discovery and filtering. |
| **Created** | Timestamp of capture. |

## Choosing between Memory and Disk suspend modes

When auto-suspend fires (or you call suspend explicitly), the platform preserves state according to the configured suspend mode:

| Mode | What's preserved | Resume latency | Storage footprint | Best for |
|---|---|---|---|---|
| **Memory** | Full memory image plus disk | Sub-second | Larger (memory + disk) | Interactive sessions, agent state, long-running workloads with expensive warm-up. |
| **Disk** | Disk only; VM restarts fresh | Cold start (process restart) | Smaller (disk only) | Workloads that boot quickly from disk and don't depend on in-memory state. |

If you're not sure, start with **Memory**. It's the default and the choice that gives you the sub-second resume sandboxes are designed for. Switch to **Disk** when storage cost or memory size becomes a concern.

## Resume and restore semantics

When you restore a sandbox from a snapshot or resume it from a memory suspend, several constraints apply:

- **Resource tier is inherited.** A restored sandbox uses the CPU, memory, and disk allocation captured in the snapshot. You can't change the resource tier on the restore call. To run the workload at a different size, capture a new snapshot from a sandbox sized appropriately.
- **Entrypoint, command, and environment aren't configurable.** When a sandbox's source is a snapshot, the entrypoint, command, and environment variables come from the snapshot. To change them, create a sandbox from the original disk image instead.
- **Region pinning.** Snapshots are scoped to the region of the sandbox group that owns them. Restoring in another region requires recreating the workload in a sandbox group in that region.

## Operational guidance

A few patterns make snapshots easier to operate at scale:

- **Label every snapshot.** Labels are the primary mechanism for filtering and discovery in the snapshot list. Encode the workload, owner, and purpose in labels at capture time.
- **Build deletion into your workflow.** Snapshots aren't garbage collected. Pair every long-lived snapshot with a retention policy enforced by your application or scheduled cleanup job.
- **Audit snapshot count.** Periodically list snapshots and report on count and label distribution. Storage costs grow with snapshot count.
- **Treat snapshots as immutable.** A snapshot is a point-in-time capture. To "update" a snapshot, capture a new one and delete the old one once consumers have moved over.

## When *not* to snapshot

Snapshots have a cost and aren't always the right tool:

- **Stateless, short-lived sandboxes** — a sandbox that runs for 30 seconds and writes nothing back doesn't benefit from snapshotting. Let it complete and delete it.
- **State that already lives elsewhere** — if your sandbox writes results to attached volumes, blob storage, a database, or a queue, the state is already durable. A snapshot adds storage cost without preserving anything new.
- **Frequent writes to large files** — large rapidly-changing disks make snapshots expensive. Move the data to an attached volume and snapshot only the smaller, slower-changing portion of state if needed.

## Related content

- [Egress policies and network controls for Azure Container Apps sandboxes](sandboxes-egress-policies.md)
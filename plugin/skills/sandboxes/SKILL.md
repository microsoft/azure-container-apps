---
name: sandboxes
description: |
  Hardware-isolated microVMs on Azure Container Apps for AI-generated
  code, coding agents, MCP servers, web apps, ephemeral workloads.
  Snapshot/resume, scale-to-zero, sub-second startup, deny-default
  egress. Driven by `aca` CLI (auth via `az login`).

  Use when the user wants to: create/manage sandbox groups and
  sandboxes; exec or open a shell; read/write files; expose ports;
  snapshot, stop, resume, commit to disk; mount volumes; tighten
  egress; manage secrets, identity, labels; apply YAML; or run
  scenarios like web apps, coding agents, code interpreter, swarms,
  computer-use, or MCP hosting.

  If `aca` is missing, read `references/install.md` first. `aca`
  ships ONLY via GitHub Releases (microsoft/azure-container-apps);
  not npm/pip/winget/brew. Don't guess.

  Triggers: install aca, install aca cli, setup aca, aca doctor, aca
  login, command not found: aca, create sandbox, sandbox group, aca
  cli, aca sandbox, microVM, code interpreter, agent swarm, host mcp.
---

# Sandboxes

Hardware-isolated microVMs on Azure Container Apps. Snapshot/resume,
scale-to-zero, sub-second startup, deny-default egress. This skill
drives sandboxes through the **`aca` CLI** — one command surface, no
ambiguity. Self-contained — everything is under `references/` in this
folder.

## What it is

- **Resource type:** `Microsoft.App/SandboxGroups` (preview).
- **Isolation:** each sandbox is its own microVM, safe for untrusted code.
- **Startup:** sub-second from a prewarmed pool; suspend/resume preserves
  full memory + disk.
- **Scale:** zero to thousands; pay nothing when idle.
- **Auth:** `aca` delegates to `az login` — same identity, same MFA.

> ⚠️ **The `az` CLI has no sandbox commands.** Sandbox groups and
> sandboxes are managed by `aca` — **not** by `az containerapp …`. The
> `az containerapp` commands are for the older Apps / Jobs surface and
> do not touch sandboxes. If you see `az containerapp sandbox …` in a
> snippet, it's wrong.

## Get started

| | Where |
|---|---|
| **Install** | [references/install.md](references/install.md) |
| **Prerequisites** | [references/prerequisites.md](references/prerequisites.md) |
| **Quick start** | [references/quickstart.md](references/quickstart.md) |
| **Full CLI reference** | [references/reference.md](references/reference.md) |
| **Scenario recipes** | [references/scenarios.md](references/scenarios.md) |

After install, always confirm setup with `aca doctor` — it resolves
subscription / RG / group / region / role and tells you which check
is red.

## Capabilities

Everything the platform exposes. Each row is the starting point — open
[references/reference.md](references/reference.md) for full flags and
options.

> Command rows below show only the **shape**. In real invocations:
> - every `aca sandbox <verb>` takes `--id <sandbox-id>`;
> - every `aca sandboxgroup <noun> <verb>` mutation takes `--name <group>`
>   (or relies on the default group set via `--set-config`);
> - omit these from copies into the shell and you'll get a CLI parse error.

| #  | Capability                | What it does                                                                 | `aca` CLI |
|----|---------------------------|------------------------------------------------------------------------------|-----------|
| 00 | **Sandbox groups**        | Provision, list/get, assign Data Owner role, tear down.                      | `aca sandboxgroup create / list / get / role create / delete` |
| 01 | **Sandboxes**             | Create, list, get, delete; cpu/memory/labels/env; parallel.                  | `aca sandbox create / list / get / delete` (+ `--cpu --memory --labels --env`) |
| 02 | **Snapshots**             | Freeze a running sandbox; boot new ones from that point.                     | `aca sandbox snapshot --id <id> --name X` · `aca sandbox create --snapshot X` |
| 03 | **Disks**                 | Public disks, build from container image, commit a running sandbox.          | `aca sandboxgroup disk list-public / create --image` · `aca sandbox commit --id <id> --name X` · `aca sandbox create --disk <public-name>` (or `--disk-id <id>` for private/committed disks) |
| 04 | **Volumes**               | `AzureBlob` (shared) or `DataDisk` (block); mount at create or post-create.  | `aca sandboxgroup volume create --type AzureBlob` · `aca sandbox mount --volume X --path /mnt/x` |
| 05 | **Lifecycle**             | Stop/resume; auto-suspend after idle; auto-delete after TTL.                 | `aca sandbox stop / resume` · `aca sandbox lifecycle set --auto-suspend 60` |
| 06 | **Ports**                 | Expose an HTTP port; anonymous or Entra-gated; revoke.                       | `aca sandbox port add --port 8080 [--anonymous]` · `port list / remove` |
| 07 | **Files**                 | write / read / list / stat / mkdir / delete inside the sandbox.              | `aca sandbox fs write --file ./local` · `fs cat / ls` · `fs cp <src> <dst>` (positional, `sbx-id:/path` syntax) |
| 08 | **Egress**                | Deny-default outbound + host allow-list; audit decisions; YAML transforms.   | `aca sandbox egress set --default Deny --host-allow "*.host.com"` · `egress show / decisions / apply` |
| 09 | **Secrets**               | Group-scoped key/value, fetched at runtime from inside the sandbox.          | `aca sandboxgroup secret upsert --name X --values "K=V"` · `secret list / delete` |
| 10 | **Managed identity**      | System- or User-assigned MI on the group; grant RBAC for cross-group orchestration. | `aca sandboxgroup identity assign --system-assigned` (or `--user-assigned <res-id>`) · `identity show / remove` |
| 11 | **Labels & selectors**    | `--labels k=v` at create time; AND-filter on list. Fleet management pattern. | `aca sandbox create --labels role=worker,tenant=t42` · `aca sandbox list -l role=worker` |
| 12 | **Interactive shell**     | Real PTY into a running sandbox.                                             | `aca sandbox shell --id <id>` |
| 13 | **YAML spec / `apply`**   | Declarative infra-as-code: `init`, `validate`, `apply`, `schema`.            | `aca sandbox init > sandbox.yaml` · `validate` · `apply --file sandbox.yaml` |
| 14 | **`aca doctor`**          | Diagnose subscription / RG / group / region / role.                          | `aca doctor` |

## Scenarios

Composed patterns that combine the capabilities above. Full sketches
in [references/scenarios.md](references/scenarios.md).

- **Web apps** — start a server, expose a port anonymously, hit the URL.
- **Coding agents in a sandbox** — run Copilot CLI / Claude Code / Codex
  with deny-default egress and (optionally) token-swap rules.
- **Code interpreter** — LLM generates → exec → observe → iterate;
  snapshot between turns for rewind.
- **Swarms** — orchestrator fans work across N worker sandboxes by
  label selector.
- **Sandbox inception** — orchestrator runs *inside* a sandbox and uses
  its managed identity to drive a separate worker group. No credentials
  in agent code.
- **Computer-use** — LLM drives a real browser; watch live via noVNC.
- **MCP hosting** — host an MCP server in a sandbox; expose via port or
  Dev Tunnel.
- **Data processing** — producer/consumer pipelines on shared
  `AzureBlob` volumes.
- **Developer workflows** — PR builds, ephemeral CI, on-demand dev envs.

## Python SDK (separate)

An early-access Python SDK (`azure-containerapps-sandbox`) is also
available if you'd rather drive sandboxes from service code instead of
the CLI. It is **out of scope for this skill** — when the user asks for
Python, point them at the upstream README and stop:

> https://github.com/microsoft/azure-container-apps/blob/main/docs/early/python-sdk/README.md

Mixing CLI and SDK in the same answer confuses things. Pick one.

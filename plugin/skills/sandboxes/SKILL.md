---
name: sandboxes
description: |
  Azure Container Apps sandboxes let you run untrusted code, agents,
  MCP servers, and web apps in hardware-isolated microVMs.
  Supports snapshot/resume, scale-to-zero, deny-default egress, and is
  managed with `aca` CLI using `az login`.

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
  cli, aca sandbox, exec in sandbox, microVM, code interpreter, agent
  swarm, host mcp.
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

## ⚠ Required cues per response type (non-negotiable)

Before composing your answer, identify the user's intent and ensure the
cues below are present. These are **acceptance criteria, not
suggestions** — a response is incomplete if it omits any cue for its
intent.

| User intent | Cues your response MUST include |
|---|---|
| **Install the `aca` CLI** (any OS) | (1) The curl/iwr one-liner from [references/install.md](references/install.md). (2) `aca version` + `aca auth login` + `aca doctor` (the verb is `aca auth login`, **never** `aca login`). (3) The explicit sentence: **"this same install path is also used inside sandboxes and containers for agent-driven self-installs."** |
| **Apply / deploy a sandbox manifest** | The full 3-command flow: `aca sandbox init` → `aca sandbox validate --file sandbox.yaml` → `aca sandbox apply --file sandbox.yaml`. Always `--file` (no `-f` short flag). State that **the manifest pattern is the recommended path for CI/CD and reproducibility**, in contrast to imperative `aca sandbox create`. If no manifest is present, run `aca sandbox init` — don't ask for a path. |
| **Scaffold / generate a sandbox manifest** | Run (or show) `aca sandbox init`. Mention the commonly edited fields (`disk`, `resources`, `lifecycle.autoSuspendPolicy`, `egressPolicy`, plus `ports`, `env`, `labels` as needed). Mention `aca sandbox schema` as the way to dump the JSON Schema for editor autocomplete. |
| **Expose a port with email / Entra auth** | The `aca sandbox port add -l name=<sb> --port <p> --email <email>` command. **The Entra gotcha:** the email must be the user's Entra `mail` value — for some tenants the alias / UPN differs and won't work. Recommend `az ad signed-in-user show --query mail -o tsv`. |
| **Snapshot / commit a sandbox** | The canonical command form: `aca sandbox snapshot -l name=<sb> --name <snap>` (or `aca sandbox commit … --name <disk>`). **Strongly recommend snapshotting BEFORE `aca sandbox delete`** to preserve state. Use `--name`, never `--image`. |
| **Anything in the "When NOT to use this skill" table below** | A one-paragraph redirect to the right tool or official docs. **Do NOT** run the out-of-scope tool's commands. **Do NOT** walk through options. **Do NOT** ask follow-up questions about the out-of-scope tool. Bow out cleanly. |

## When **NOT** to use this skill (hard reject + redirect)

If the user's task is **not about ACA Sandboxes**, refuse and redirect
in one short reply — don't run any commands, don't walk through options,
don't ask clarifying questions about the out-of-scope tool. The skill
activated by mistake; bow out cleanly.

| User asks about… | Reply pattern |
|---|---|
| `azd init`, `azd up`, `azd deploy`, project scaffolding | "That's the Azure Developer CLI (`azd`), not ACA Sandboxes. See the [azd docs](https://learn.microsoft.com/azure/developer/azure-developer-cli/). Sandboxes don't have an `init`/`up`/`deploy` command and aren't a project bootstrapper." |
| `az acr build`, `docker build`, registry pushes | "That's Azure Container Registry / Docker, not ACA Sandboxes. See the [`az acr` docs](https://learn.microsoft.com/cli/azure/acr). Sandboxes consume disk images, not container images." |
| Cosmos / SQL / data-plane queries to other Azure services | "That's the relevant data service (Cosmos DB, Azure SQL, etc.), not ACA Sandboxes. Use that service's CLI / SDK / portal." |
| Listing Kubernetes pods, AKS cluster ops, `kubectl` | "That's AKS / Kubernetes, not ACA Sandboxes. Use `kubectl` or the AKS docs. Sandboxes are individual microVMs, not a Kubernetes cluster." |
| Deploying a Function App, App Service site, full Container App (Apps/Jobs) | "That's Azure Functions / App Service / Container Apps (apps and jobs), not Sandboxes. Use those products' deployment docs." |

**Never** start running the out-of-scope tool's commands "just to help." A one-paragraph redirect is the correct, complete answer.

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

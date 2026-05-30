---
name: aca-sandboxes
description: "Use when the user wants to create, manage, or operate Azure Container Apps sandboxes \u2014 hardware-isolated microVMs driven by the `aca` CLI. USE FOR: create sandbox group, create sandbox, aca doctor, aca login, install aca, exec in sandbox, sandbox shell, fs read/write, expose port, mount volume, snapshot/suspend/resume sandbox, commit to disk, egress rules, secrets, identity, scenarios like coding agents, code interpreter, agent swarms, computer-use, web apps, MCP hosting. DO NOT USE FOR: regular Azure Container Apps (`Microsoft.App/containerApps`), AKS, or VM workloads."
license: MIT
metadata:
  author: Microsoft
  version: "0.0.5-beta"
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

> ⚠️ **There is no `aca sandbox-group` (hyphenated) command group.**
> Every group-level verb is `aca sandboxgroup …` (no hyphen):
> `aca sandboxgroup create / get / list / delete / role create /
> identity assign / secret upsert / disk list / volume create / snapshot …`.
> The hyphenated `--sandbox-group <name>` is the *flag* you pass to
> top-level commands to select the default group — it is not a verb.
> If you see `aca sandbox-group …` in a snippet (including for MCP
> connectors, credentials, or triggers), it's wrong / fabricated.

## ⚠ Required cues per response type (non-negotiable)

Before composing your answer, identify the user's intent and ensure the
cues below are present. These are **acceptance criteria, not
suggestions** — a response is incomplete if it omits any cue for its
intent.

| User intent | Cues your response MUST include |
|---|---|
| **Install the `aca` CLI** (any OS) | (1) The curl/iwr one-liner from [references/install.md](references/install.md) — use the `https://aka.ms/aca-cli-install` (Linux/macOS) and `https://aka.ms/aca-cli-install-ps` (Windows) short URLs. (2) `aca --version` + **auth-aware sign-in** (`az account show -o none 2>$null; if ($LASTEXITCODE -ne 0) { az login }`) + `aca doctor` (`aca` delegates auth to `az login` — same Entra identity; **only call `az login` if `az account show` fails, never unconditionally**). (3) The explicit sentence: **"this same install path is also used inside sandboxes and containers for agent-driven self-installs."** |
| **Bootstrap a sandbox group (one-time setup)** | The 4-step flow: **check auth first** (`az account show -o none 2>$null; if ($LASTEXITCODE -ne 0) { az login }` — *never* call `az login` unconditionally; it opens a browser/device flow even when a valid session already exists) → `aca sandboxgroup create --name <g> --location <region> --set-config` → `aca sandboxgroup role create --role "Container Apps SandboxGroup Data Owner" --principal-id $(az ad signed-in-user show --query id -o tsv)` → `aca doctor`. **`--set-config` is required** so subsequent `aca sandbox …` commands don't need `--group` on every call. Treat green `aca doctor` as the gate before doing anything else — if doctor reports an auth red, *then* run `aca auth login` (also conditional). |
| **Create a sandbox (imperative)** | Minimum: `aca sandbox create --disk ubuntu`. Common knobs: `--cpu 2000m`, `--memory 4096Mi`, `--env "K=V"`, `--labels "name=dev,role=worker"`. Capture the printed ID into `SANDBOX_ID=$(aca sandbox create --disk ubuntu -o json \| jq -r .id)` for reuse. For config that should live in source control, use the manifest flow (see the row below) instead. |
| **Apply / deploy a sandbox manifest** | The full 3-command flow: `aca sandbox init` → `aca sandbox validate --file sandbox.yaml` → `aca sandbox apply --file sandbox.yaml`. Always `--file` (no `-f` short flag). State that **the manifest pattern is the recommended path for CI/CD and reproducibility**, in contrast to imperative `aca sandbox create`. If no manifest is present, run `aca sandbox init` — don't ask for a path. |
| **Scaffold / generate a sandbox manifest** | Run (or show) `aca sandbox init`. Mention the commonly edited fields (`disk`, `resources`, `lifecycle.autoSuspendPolicy`, `egressPolicy`, plus `ports`, `env`, `labels` as needed). Mention `aca sandbox schema` as the way to dump the JSON Schema for editor autocomplete. |
| **Run a command or open a shell in a sandbox** | Two distinct verbs: `aca sandbox exec --id "$SANDBOX_ID" -c "<command>"` for one-shot commands (returns stdout/stderr); `aca sandbox shell --id "$SANDBOX_ID"` for an interactive PTY. **Anti-cue:** `ssh` does not work — there is no SSH daemon inside the sandbox. `aca sandbox exec` / `shell` is the only path. |
| **Delete a sandbox** | `aca sandbox delete --id "$SANDBOX_ID" --yes`. **Always recommend snapshotting first** if there is any state worth preserving (`aca sandbox snapshot --id "$SANDBOX_ID" --name <snap>`) — delete is destructive. To delete by label selector: `aca sandbox list -l "name=<n>" -o json \| jq -r '.[].id' \| xargs -I{} aca sandbox delete --id {} --yes`. |
| **Read / write / copy files in a sandbox** | The `aca sandbox fs` family — `fs write --id "$SANDBOX_ID" --path /remote/p --file ./local` to upload, `fs cat --id "$SANDBOX_ID" --path /remote/p` to read, plus `fs ls / stat / mkdir / rm [--recursive]` for management. **Don't** suggest `scp` / `rsync` / shared filesystems — there is no SSH, and `fs` is the only data-plane file transport. |
| **Expose a port — public preview (anonymous)** | The two-step shape: `URL=$(aca sandbox port add --id "$SANDBOX_ID" --port <p> --anonymous -o json \| jq -r .url)`, then hit `$URL`. **State explicitly** that anonymous = anyone with the URL can reach it (public preview only). Remove with `aca sandbox port remove --id "$SANDBOX_ID" --port <p>`. For per-user gating use the Entra row below. |
| **Expose a port with email / Entra auth** | The `aca sandbox port add --id "$SANDBOX_ID" --port <p> --email <email>` command. **The Entra gotcha:** the email must be the user's Entra `mail` value — for some tenants the alias / UPN differs and won't work. Recommend `az ad signed-in-user show --query mail -o tsv` to fetch it. |
| **Mount a shared volume** | Two-step: (1) at the group: `aca sandboxgroup volume create --name <v> --type AzureBlob` (multi-attach, shared) or `--type DataDisk` (single-attach, high-perf block). (2) at the sandbox: `aca sandbox mount --id "$SANDBOX_ID" --volume <v> --path /mnt/<v>`. State that **the volume lives at the group level**; sandboxes attach it at runtime. |
| **Lock down network egress (deny-default + allow-list)** | The canonical form: `aca sandbox egress set --id "$SANDBOX_ID" --default Deny --rule "*.github.com:Allow" --traffic-inspection Full`. Multiple `--rule "host:Allow"` flags accumulate. Inspect current policy with `aca sandbox egress show --id "$SANDBOX_ID"`. For production agent code, **always recommend `--default Deny`** with an explicit allow-list. |
| **Use a non-default disk image** | List published images first: `aca sandboxgroup disk list-public`, then `aca sandbox create --disk <name>`. To bake your own from an OCI image: `aca sandboxgroup disk create --image docker.io/library/alpine:3.19 --name <my-disk>`, then `aca sandbox create --disk-id <id>`. **Flag distinction:** `--disk` takes the public name; `--disk-id` takes the resource ID of a private/committed disk. |
| **Suspend, resume, or set auto-suspend** | Manual: `aca sandbox stop --id "$SANDBOX_ID"` suspends (preserves memory + disk); `aca sandbox resume --id "$SANDBOX_ID"` does sub-second restore. Idle policy: `aca sandbox lifecycle set --id "$SANDBOX_ID" --auto-suspend <seconds>` (default 300s = 5 min). State that **suspended sandboxes incur storage cost only, no compute** — this is the primary cost lever. |
| **Snapshot / commit a sandbox** | Per-sandbox: `aca sandbox snapshot --id "$SANDBOX_ID" --name <snap>`, then boot replicas with `aca sandbox create --snapshot <snap>`. Group-level CRUD: `aca sandboxgroup snapshot list / get / delete --selector "name=<snap>"`. **Strongly recommend snapshotting BEFORE `aca sandbox delete`** to preserve state. Use `--name`, never `--image`. Disk-only baking is `aca sandbox commit … --name <disk>`. |
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

## Try asking

Once the skill is loaded, paste any of these into your agent. Each one
exercises a different capability — together they show the canonical
shape for the most common sandbox tasks (and they double as a routing
smoke test if you're testing changes to this skill).

| Try saying | What you should get back |
|---|---|
| *"install the aca cli"* | the `aka.ms/aca-cli-install` one-liner + `aca --version` + **auth-aware** `az account show; az login *only* if it fails` + `aca doctor` |
| *"set up a sandbox group from scratch"* | the full 4-step bootstrap (group create + Data Owner role + `aca doctor` gate) |
| *"create an ubuntu sandbox and run uname -a in it"* | `aca sandbox create` with ID capture, then `aca sandbox exec` |
| *"how do I ssh into my sandbox?"* | corrective answer — no SSH daemon; use `aca sandbox shell` or `exec` |
| *"copy data.csv into my sandbox"* | `aca sandbox fs write --path … --file …` (and the anti-`scp` note) |
| *"expose port 8080 publicly"* | `aca sandbox port add --anonymous -o json \| jq -r .url` |
| *"mount a shared volume on two sandboxes"* | `aca sandboxgroup volume create --type AzureBlob` + `aca sandbox mount` |
| *"restrict outbound traffic to github.com only"* | `aca sandbox egress set --default Deny --rule "*.github.com:Allow"` |
| *"snapshot my sandbox before I tear it down"* | `aca sandbox snapshot --name <s>` followed by `aca sandbox delete --yes` |
| *"suspend my sandbox to save money"* | `aca sandbox stop`/`resume` plus `aca sandbox lifecycle set --auto-suspend` |
| *"give me a YAML manifest for a 2 vCPU sandbox"* | `aca sandbox init` → edit → `aca sandbox validate --file` → `aca sandbox apply --file` |

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

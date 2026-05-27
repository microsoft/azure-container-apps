---
name: aca-sandboxes
description: >-
  Azure Container Apps Sandboxes (a.k.a. ACA Sandboxes, ADC, Agent Dev Compute)
  and the public `aca` CLI — hardware-isolated microVMs with snapshots,
  suspend/resume, scale-to-zero. Use for: create a sandbox, create my first ACA
  sandbox, install the aca cli on mac/linux/windows, ssh / shell into a sandbox,
  aca sandbox shell/exec/apply, apply sandbox.yaml manifest, deploy AI agent /
  MCP server / personal agent / web app to a sandbox, expose port, snapshot,
  suspend, resume, mount volume, egress policy, sandbox group, microVM,
  Microsoft.App/SandboxGroups, agentdevcompute, ACA Sandboxes vs Container Apps
  Dynamic Sessions comparison. DO NOT USE FOR: Container Apps Dynamic Sessions
  (different product — managed code-interpreter pool), Container Apps app/job
  deploys, ACR build, Azure Functions, AKS, App Service, Cosmos, Container
  Registry, generic `az` CLI.
metadata:
  author: azure-container-apps-team
  version: "0.8.0"
---

# Azure Container Apps Sandboxes — `aca` CLI skill

Deploy AI agents, MCP servers, web apps, and background tasks to **ACA Sandboxes** — hardware-isolated microVMs anchored on the public [`aca` Rust CLI](https://github.com/microsoft/azure-container-apps/tree/main/docs/early/aca-cli).

## Naming

**Public name:** ACA Sandboxes (also "Azure Container Apps sandboxes" in [Microsoft Learn](https://github.com/microsoft/azure-container-apps/blob/main/docs/early/sandboxes-overview.md)). **Sandboxes is part of the Azure Container Apps product family** — the same family as Container Apps (Apps/Jobs) and Container Apps Dynamic Sessions. That's why the portal lives under `containerapps.azure.com` and the ARM provider is `Microsoft.App`. **Internal codename:** ADC (Agent Dev Compute). You may see `azuredevcompute.io` in source paths and the data-plane hostname (`management.azuredevcompute.io`) — same product.

**⚠ DO NOT confuse ACA Sandboxes with regular Azure Container Apps (Apps/Jobs).** Sandboxes is a sibling workload type inside the Container Apps family, not a variant of Apps/Jobs. It is **not** created with `az containerapp`. It has its own CLI (`aca`, not `az containerapp`), its own ARM type (`Microsoft.App/SandboxGroups`), and its own portal experience (`https://containerapps.azure.com/sandbox-groups`). When the user says "ACA Sandbox" or "ACA Sandboxes" or "sandbox" in this context, use the `aca` CLI — never `az containerapp ...`.

**⚠ DO NOT confuse with Container Apps Dynamic Sessions.** Dynamic Sessions is a different (prior) sibling product in the same Container Apps family — managed-pool execution model; sandboxes give you direct programmable control. See the [Sandboxes vs. dynamic sessions comparison](https://github.com/microsoft/azure-container-apps/blob/main/docs/early/sandboxes-overview.md#sandboxes-vs-dynamic-sessions) and the in-body table below. The auth-scope audience `dynamicsessions.io` in `aca auth status` is an **internal implementation detail** of the sandboxes data plane — not the Dynamic Sessions product.

## Do not hallucinate

- There is **no** `winget install aca`, `brew install aca`, `npm install -g aca`, or `pip install aca`. Install via the official scripts — see [references/quickstart.md](references/quickstart.md).
- There is **no** `aca sandbox create --template`. Sandboxes are created from **disk images** (`--disk <name>` / `--disk-id <uuid>`) or **snapshots** (`--snapshot <name>` / `--snapshot-id <uuid>`). For declarative workflows, use `aca sandbox apply --file sandbox.yaml`.
- There is **no** `aca deploy`, `aca init` (project scaffolding), or `aca setup` command. (`aca sandbox init` exists — it prints a YAML manifest template.)
- **Auth** uses Azure CLI bearer tokens. Ensure `az` is installed and `az login` has been run. `aca auth login` delegates to `az login`; `aca auth status` shows ARM + data-plane status.
- **Management API** is `https://management.azuredevcompute.io`. The **portal** is `https://containerapps.azure.com/sandbox-groups`. The **proxy** for exposed ports is `<sandbox-id>--<port>.proxy.azuredevcompute.io`. Do not invent other hostnames.
- **SSH:** no traditional SSH, no `ssh -i`, no keypair. Use `aca sandbox shell` or the portal terminal. See [references/ssh-setup.md](references/ssh-setup.md).
- Use only the information in this skill and its references. The authoritative public sources are:
  - [`microsoft/azure-container-apps/docs/early/`](https://github.com/microsoft/azure-container-apps/tree/main/docs/early) — markdown reference in this repo.
  - [`sandboxes.azure.com/docs/sandboxes/`](https://sandboxes.azure.com/docs/sandboxes/) — portal-hosted product docs (sandbox groups, sandboxes, sandbox detail, connectors).

## When **NOT** to use this skill (hard reject + redirect)

If the user's task is **not about ACA Sandboxes**, refuse and redirect in one short reply — do not run any commands, do not walk through options, do not ask clarifying questions about the out-of-scope tool. The skill activated by mistake; bow out cleanly.

| User asks about… | Reply pattern |
|---|---|
| `azd init`, `azd up`, `azd deploy`, project scaffolding | "That's the Azure Developer CLI (`azd`), not ACA Sandboxes. The **azure-prepare** / **azure-deploy** skills (or the official [azd docs](https://learn.microsoft.com/azure/developer/azure-developer-cli/)) own that flow. ACA Sandboxes doesn't have an `init`/`up`/`deploy` command and isn't a project bootstrapper." |
| `az acr build`, `docker build`, registry pushes | "That's Azure Container Registry / Docker, not ACA Sandboxes. Use the **azure-prepare** or **azure-deploy** skills, or the [`az acr` docs](https://learn.microsoft.com/cli/azure/acr). Sandboxes consume disk images, not container images." |
| Cosmos DB queries, SQL queries, data plane queries to other Azure services | "That's an Azure Cosmos DB (or other data service) query — not ACA Sandboxes. Use the **azure-cosmos** skill, Azure Data Explorer, or the Cosmos data explorer in the portal." |
| Listing Kubernetes pods, AKS cluster ops, `kubectl` | "That's AKS / Kubernetes, not ACA Sandboxes. Use **azure-kubernetes** or `kubectl` directly. Sandboxes are individual microVMs, not a Kubernetes cluster." |
| Deploying a Function App, App Service site, full Container App | "That's Azure Functions / App Service / Container Apps (apps and jobs), not Sandboxes. Use **azure-prepare** / **azure-deploy**." |

**Never** start running the out-of-scope tool's commands "just to help." A one-paragraph redirect is the correct, complete answer.

## When to use this skill

| The user asks… | Skill action |
|---|---|
| "Create a sandbox" / "deploy my agent to a sandbox" | Walk through [quickstart](references/quickstart.md) (imperative or YAML manifest) |
| "Run my MCP server in isolation" | Create a sandbox, run the MCP server, expose the port — see [quickstart](references/quickstart.md). _(MCP discovery model is a TODO — see [Templates](#templates) below.)_ |
| "Build me a personal agent" / "agent with my email + calendar" | _(TODO: a "Personal Agent" template — chat UI + Office 365 / M365 Copilot / GitHub Copilot / ACA Sandbox Management connectors + multi-agent routing — is not yet documented in the public `microsoft/azure-container-apps` docs. Track in PR #1725 follow-ups; for now, point users at [deploy-patterns](references/deploy-patterns.md).)_ |
| "SSH into the sandbox" | Present the [SSH options](references/ssh-setup.md): `aca sandbox shell` first, portal terminal second |
| "Why did `port add` return 409 / 500?" | See [connections.md](references/connections.md) (Entra `mail` vs alias) |
| "Stop / resume / snapshot / suspend" | `aca sandbox stop\|resume\|snapshot -l name=<label> --name <snap>` |
| "Restrict outbound network" | `egressPolicy` in YAML or `aca sandbox egress apply` |
| "Should I use Dynamic Sessions instead?" | They are **different products** — see [the comparison](https://github.com/microsoft/azure-container-apps/blob/main/docs/early/sandboxes-overview.md#sandboxes-vs-dynamic-sessions) |

## Disambiguation: ask before assuming

Several terms are ambiguous on their own. **Always ask a brief clarifying question before provisioning anything** when the user says:

| User says… | Ask first | Why |
|---|---|---|
| `"sandbox"` (single word) | "Do you mean **Azure Container Apps sandbox** (developer microVM), **Container Apps Dynamic Sessions** (LLM code interpreter), or something else (Windows Sandbox / Salesforce / Playwright)?" | Could be many products |
| `"microVM"` / `"ephemeral VM"` | "Are you looking for a **dev-loop microVM** (ACA Sandbox — hours/days, SSH-able, MCP/agent host) or a **general-purpose Azure VM** / AKS Kata?" | ACA Sandboxes are microVMs but so are several others |
| `"sandbox for my coding agent"` | "Do you want (a) the agent's **personal dev environment** (ACA Sandbox + `claude`/`copilot` disk preset) or (b) an **isolated runtime to execute generated code** (Dynamic Sessions / code interpreter)?" | Personal-agent vs code-interpreter are different ACA products |
| `"VM for dev work"` | "Long-lived workstation (→ **Microsoft Dev Box**) or ephemeral dev microVM with MCP/agent integration (→ **ACA Sandbox**)?" | Different audiences/lifecycles |
| `"sandbox for AI agent runtime"` | "Is the sandbox for the **agent itself to live in** (ACA Sandbox, hours/days, with snapshot/resume) or for **per-request code execution by the agent** (Dynamic Sessions, sub-second pool)?" | Different scoping |

Only after the user picks an option, proceed with the relevant flow below. Do **not** silently default to ACA Sandboxes for these prompts.

## Install the `aca` CLI (macOS, Linux, Windows)

Minimum version: **1.0.0-beta.1**. The install + verify + auth flow is three commands — present all three, every OS.

```bash
# macOS (Apple Silicon or Intel) + Linux x64 — Bash one-liner
# (this same one-liner is also the install path used INSIDE a sandbox or
#  container for agent-driven self-installs — no extra steps, no package manager)
curl -fsSL https://raw.githubusercontent.com/microsoft/azure-container-apps/main/docs/early/aca-cli/install.sh | bash
```

```powershell
# Windows x64 — PowerShell one-liner
# (same install used inside Windows sandboxes / containers for agent-driven installs)
iwr -useb https://raw.githubusercontent.com/microsoft/azure-container-apps/main/docs/early/aca-cli/install.ps1 | iex
```

```bash
aca version          # confirm >= 1.0.0-beta.1 (minimum supported version)
aca doctor           # expect 8/8 checks pass
aca auth login       # delegates to `az login` (NOTE: the verb is `aca auth login`, NOT `aca login`)
aca auth status      # ARM + data-plane status
```

> There is **no** `brew install aca`, `winget install aca`, `npm i -g aca`, `pip install aca`, or top-level `aca login`. Always use the official curl/iwr one-liners above and the `aca auth login` verb. See [references/quickstart.md](references/quickstart.md).

## Create a sandbox

Imperative flow — uses `--location` for `sandboxgroup create`, uses `-l name=<sb>` **label selector** (not `--id <uuid>`), and warns about auto-suspend:

```bash
aca sandboxgroup create --name <grp> --location eastus2 --set-config
aca sandbox create --group <grp> --disk ubuntu --label name=<sb>
aca sandbox shell  -l name=<sb>          # interactive WebSocket shell (label selector)
aca sandbox exec   -l name=<sb> -c "uname -a"
aca sandbox port add -l name=<sb> --port 80 --anonymous
```

> Run `aca sandboxgroup disk list-public` for the current disk catalog. `ubuntu` is the safest default; specialty disks (e.g. `copilot`, `python-3.13`, `node-24`) may be available in your region.

**Always use `-l name=<sb>` (label selector) rather than `--id <uuid>`** in your examples — the label is human-readable and stable, the UUID is opaque. `--id` is supported but never lead with it.

**Auto-suspend gotcha:** sandboxes auto-suspend after the configured idle interval (default 5 min) — state is preserved; `aca sandbox resume -l name=<sb>` brings it back sub-second.

### Add a port locked to the signed-in user (Entra ID)

```bash
EMAIL=$(az ad signed-in-user show --query mail -o tsv)
aca sandbox port add -l name=<sb> --port 3000 --email "$EMAIL"
# Or pass the full email explicitly, e.g.:
# aca sandbox port add -l name=<sb> --port 3000 --email user@contoso.com
```

> **Gotcha:** the `--email` value MUST be the user's full Entra ID email (their `mail` attribute). Some tenants have a `mail` value that differs from the alias / `userPrincipalName` shown in `az account show --query user.name`. **When the alias and `mail` differ, only the `mail` value works** — port-add will silently fail or return 409/500 if you pass an alias. Always prefer `az ad signed-in-user show --query mail -o tsv`. See [references/connections.md](references/connections.md).

> **Never tell users to SSH on port 22.** ACA Sandboxes do not expose SSH; use `aca sandbox shell -l name=<sb>` (interactive WebSocket) instead.

## Snapshots and saving sandbox state

Two related but distinct operations (both verified via `aca sandbox <verb> --help`):

```bash
# Snapshot — point-in-time checkpoint of a running sandbox (fast, restorable)
aca sandbox snapshot -l name=<sb> --name checkpoint-v1
# Restore via: aca sandbox create --snapshot checkpoint-v1 --label name=<new-sb>

# Commit — save sandbox state as a reusable DISK IMAGE in the sandbox group
aca sandbox commit -l name=<sb> --name my-disk-v1
# Use via: aca sandbox create --disk my-disk-v1 --label name=<new-sb>
```

**Always recommend snapshotting (or committing) before `aca sandbox delete`** — once a sandbox is destroyed, in-memory and disk state is gone unless captured.

## Apply a sandbox manifest (`sandbox.yaml`)

The YAML/declarative path is the **recommended flow for CI/CD and reproducibility** — check `sandbox.yaml` into source control, replay it in any environment. Parallel to the imperative `aca sandbox create` flow above. Always walk the user through the full 3-command flow (don't just mention `init`):

```bash
# 1. Scaffold a starter manifest. (Proactive rule: if no sandbox.yaml exists
#    in the working dir, RUN `aca sandbox init` first — don't ask the user
#    for a path.) The generated manifest covers these fields, all of which
#    you should mention when you scaffold or explain a manifest:
#      group       — parent sandbox group name
#      id / labels — `labels.name: <friendly>` lets you use -l name= selectors
#      disk        — base image (ubuntu, node-24, python-3.13, claude, copilot, …)
#      resources   — cpu (e.g. 1000m) / memory (e.g. 2048Mi)
#      ports[]     — port exposure with auth: anonymous OR auth: entra + email:
#      env         — environment variables
#      lifecycle.autoSuspendPolicy — idle-suspend rules
#      egressPolicy — defaultAction Deny/Allow + per-domain allow-list
aca sandbox init > sandbox.yaml

# 2. Edit the manifest. For full JSON-Schema autocomplete in your editor,
#    dump the schema and point your editor at it:
aca sandbox schema > sandbox.schema.json
$EDITOR sandbox.yaml

# 3a. Validate against the schema + policy (catch errors before apply).
#     NOTE: the only spelling is `--file`. There is NO `-f` short flag.
aca sandbox validate --file sandbox.yaml

# 3b. Apply (provision). Idempotent — re-apply is safe; converges to manifest state.
#     This declarative path is the RECOMMENDED workflow for CI/CD and reproducibility,
#     in contrast to the imperative `aca sandbox create` flow above (which is fine
#     for one-off experiments but doesn't give you source-controllable diffs).
aca sandbox apply --file sandbox.yaml
```

**Why the manifest pattern over imperative `aca sandbox create`?** Always cite these when recommending it:
- **Source-controllable & reviewable:** diffs show what changed.
- **Reproducible:** identical sandbox in dev / CI / prod.
- **Idempotent:** `apply` is safe to re-run; converges to the manifest's state.
- **Egress + lifecycle in one place:** `egressPolicy.defaultAction: Deny` + per-domain allow-list + `autoSuspendPolicy` belong in the manifest, not in flags.

For full walkthroughs see [quickstart](references/quickstart.md) and [deploy-patterns](references/deploy-patterns.md).

## SSH into a sandbox

ACA Sandboxes do **not** support traditional SSH — no port 22, no `ssh -i`, no keypairs, no VS Code Remote SSH host. Auth is your `az login` token. When the user says "ssh into my sandbox" or "shell into sandbox", **always present these two options, in this order:**

1. **`aca sandbox shell -l name=<sb>`** (recommended, first option) — interactive WebSocket shell, auth via `az login` token. Use the **label selector** form, NOT `--id <uuid>`.
2. **Portal terminal** — open the sandbox in the [ACA portal](https://containerapps.azure.com/sandbox-groups) → click **Terminal**. Browser-based, no install needed.

Do not look up the user's `~/.ssh/config`, do not suggest keypair SSH, do not run `ssh user@host`. See [references/ssh-setup.md](references/ssh-setup.md) for non-interactive `exec` and connector specifics.

## ACA Sandboxes vs. Container Apps Dynamic Sessions

**Different products.** Do not conflate them. When asked to compare or pick between them, present this table and explain the choice:

| Dimension | **ACA Sandboxes** | **Container Apps Dynamic Sessions** |
|---|---|---|
| Audience | Developer-owned | Managed code-interpreter for LLM tool execution |
| Lifecycle | Long-lived (hours → days), you create/suspend/resume/delete | Ephemeral (seconds → minutes), managed by session pool |
| Control | Direct programmable control (CLI + YAML + API) | Pool-managed; you submit code, get a result |
| Isolation | Hardware-isolated microVM | Hyper-V isolation |
| Best for | Personal agents, dev loops, MCP servers, interactive shells | Untrusted LLM-generated code execution at request scope |
| State | Stateful — snapshots, volumes, suspend preserves memory | Stateless / ephemeral |

The auth-scope audience `dynamicsessions.io` you see in `aca auth status` is an **internal sandboxes data-plane implementation detail** — not the Dynamic Sessions product. See the [public comparison](https://github.com/microsoft/azure-container-apps/blob/main/docs/early/sandboxes-overview.md#sandboxes-vs-dynamic-sessions).

### Deployment output format (mandatory)

After every deployment, output:

```
✅ Server deployed and running in sandbox

Sandbox: <sandbox-id>
Port:    <port-number>
Access:  Anonymous / Entra ID
URL:     https://<sandbox-id>--<port>.proxy.azuredevcompute.io

Test:    curl https://<sandbox-id>--<port>.proxy.azuredevcompute.io
```

### MCP server hosting — TODO: discovery model

> **TODO (post-v0.8.0):** how an MCP server hosted inside a sandbox is discovered by an agent (intra-sandbox-group networking, well-known proxy addresses, etc.) is **not yet documented in the public `microsoft/azure-container-apps` docs**. For now, expose the MCP server's port with `aca sandbox port add` and reach it from the public proxy URL `https://<sandbox-id>--<port>.proxy.azuredevcompute.io`. Update this section once the public docs ship discovery guidance.

Then ask the user to take a snapshot:

```bash
aca sandbox snapshot -l name=my-sb --name post-install
```

## Surfaces

The `aca` CLI is the supported surface today. The Python SDK is [coming soon](https://github.com/microsoft/azure-container-apps/tree/main/docs/early/python-sdk). See [references/architecture.md](references/architecture.md).

## References

| Topic | File |
|-------|------|
| Architecture, surfaces, side-by-side CLI ↔ helper | [references/architecture.md](references/architecture.md) |
| Prerequisites (Azure CLI, RBAC, Entra ID, platforms) | [references/prerequisites.md](references/prerequisites.md) |
| Install + imperative + YAML + deploy output | [references/quickstart.md](references/quickstart.md) |
| SSH / shell options | [references/ssh-setup.md](references/ssh-setup.md) |
| Security model + zero-trust token flow | [references/security.md](references/security.md) |
| Entra `mail` vs alias for port auth | [references/connections.md](references/connections.md) |
| Generic deploy patterns (exec, fs write, port add) | [references/deploy-patterns.md](references/deploy-patterns.md) |
| Gotchas, deployment issues, uninstall | [references/troubleshooting.md](references/troubleshooting.md) |
| Excalidraw MCP template | [assets/excalidraw-mcp-template/README.md](assets/excalidraw-mcp-template/README.md) |
| Personal Agent template | [assets/personal-agent-template/README.md](assets/personal-agent-template/README.md) |

## Learn more

| Topic | Reference |
|-------|-----------|
| Sandboxes overview | [docs/early/sandboxes-overview.md](https://github.com/microsoft/azure-container-apps/blob/main/docs/early/sandboxes-overview.md) |
| Egress policies | [docs/early/sandboxes-egress-policies.md](https://github.com/microsoft/azure-container-apps/blob/main/docs/early/sandboxes-egress-policies.md) |
| Snapshots & state | [docs/early/sandboxes-snapshots-state-management.md](https://github.com/microsoft/azure-container-apps/blob/main/docs/early/sandboxes-snapshots-state-management.md) |
| `aca` CLI reference | [docs/early/aca-cli/README.md](https://github.com/microsoft/azure-container-apps/blob/main/docs/early/aca-cli/README.md) |
| Portal docs — Sandboxes (overview) | [sandboxes.azure.com/docs/sandboxes/](https://sandboxes.azure.com/docs/sandboxes/) |
| Portal docs — Sandbox groups | [sandboxes.azure.com/docs/sandboxes/sandbox-groups](https://sandboxes.azure.com/docs/sandboxes/sandbox-groups) |
| Portal docs — Sandboxes (create / manage) | [sandboxes.azure.com/docs/sandboxes/sandboxes](https://sandboxes.azure.com/docs/sandboxes/sandboxes) |
| Portal docs — Sandbox detail page | [sandboxes.azure.com/docs/sandboxes/sandbox-detail](https://sandboxes.azure.com/docs/sandboxes/sandbox-detail) |
| OpenAPI spec | `https://management.azuredevcompute.io/openapi/v1.json` (requires Entra auth) |

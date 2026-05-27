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

**Public name:** ACA Sandboxes (also "Azure Container Apps sandboxes" in [Microsoft Learn](https://github.com/microsoft/azure-container-apps/blob/main/docs/early/sandboxes-overview.md)). **Internal codename:** ADC (Agent Dev Compute). You may see `agentdevcompute.io` / `azuredevcompute.io` in source paths and data-plane endpoints — same product.

**Do not confuse with Container Apps Dynamic Sessions.** Dynamic Sessions is a different (prior) product with a managed-pool execution model; sandboxes give you direct programmable control. See the [Sandboxes vs. dynamic sessions comparison](https://github.com/microsoft/azure-container-apps/blob/main/docs/early/sandboxes-overview.md#sandboxes-vs-dynamic-sessions). The auth-scope audience `dynamicsessions.io` in `aca auth status` is an **internal implementation detail** of the sandboxes data plane — not the Dynamic Sessions product.

## Do not hallucinate

- There is **no** `winget install aca`, `brew install aca`, `npm install -g aca`, or `pip install aca`. Install via the official scripts — see [references/quickstart.md](references/quickstart.md).
- There is **no** `aca sandbox create --template`. Sandboxes are created from **disk images** (`--disk <name>` / `--disk-id <uuid>`) or **snapshots** (`--snapshot <name>` / `--snapshot-id <uuid>`). For declarative workflows, use `aca sandbox apply --file sandbox.yaml`.
- There is **no** `aca deploy`, `aca init` (project scaffolding), or `aca setup` command. (`aca sandbox init` exists — it prints a YAML manifest template.)
- **Auth** uses Azure CLI bearer tokens. Ensure `az` is installed and `az login` has been run. `aca auth login` delegates to `az login`; `aca auth status` shows ARM + data-plane status.
- **Management API** is `https://management.azuredevcompute.io`. The **portal** is `https://containerapps.azure.com/sandbox-groups`. The **proxy** for exposed ports is `<sandbox-id>--<port>.proxy.azuredevcompute.io`. Do not invent other hostnames.
- **SSH:** no traditional SSH, no `ssh -i`, no keypair. Use `aca sandbox shell` or the portal terminal. See [references/ssh-setup.md](references/ssh-setup.md).
- Use only the information in this skill and its references. The authoritative public docs live at [`microsoft/azure-container-apps/docs/early/`](https://github.com/microsoft/azure-container-apps/tree/main/docs/early).

## When to use this skill

| The user asks… | Skill action |
|---|---|
| "Create a sandbox" / "deploy my agent to a sandbox" | Walk through [quickstart](references/quickstart.md) (imperative or YAML manifest) |
| "Run my MCP server in isolation" / "host Excalidraw MCP" | Apply the [Excalidraw MCP template](assets/excalidraw-mcp-template/README.md) recipe |
| "Build me a personal agent" / "agent with my email + calendar" | Run the [Personal Agent onboarding](references/deploy-patterns.md) (4 connectors, port-before-connector order) |
| "SSH into the sandbox" | Present the three [SSH options](references/ssh-setup.md) in order |
| "Why did `port add` return 409 / 500?" | See [connections.md](references/connections.md) (Entra `mail` vs alias, personal-connector order) |
| "Stop / resume / snapshot / suspend" | `aca sandbox stop|resume|snapshot create -l name=<label>` |
| "Restrict outbound network" | `egressPolicy` in YAML or `aca sandbox egress apply` |
| "Should I use Dynamic Sessions instead?" | They are **different products** — see [the comparison](https://github.com/microsoft/azure-container-apps/blob/main/docs/early/sandboxes-overview.md#sandboxes-vs-dynamic-sessions) |

## Install the `aca` CLI (macOS, Linux, Windows)

Minimum version: **1.0.0-beta.1**. Always finish with `aca doctor` (expect 8/8 checks pass) and `aca auth login` (delegates to `az login`).

```bash
# macOS (Apple Silicon or Intel) + Linux x64 — Bash one-liner
curl -sSL https://raw.githubusercontent.com/microsoft/azure-container-apps/main/docs/early/aca-cli/install.sh | bash
```

```powershell
# Windows x64 — PowerShell one-liner
iwr -useb https://raw.githubusercontent.com/microsoft/azure-container-apps/main/docs/early/aca-cli/install.ps1 | iex
```

```bash
aca version          # confirm >= 1.0.0-beta.1
aca doctor           # expect 8/8 checks pass
aca auth login       # delegates to `az login`
aca auth status      # ARM + data-plane status
```

> There is **no** `brew install aca`, `winget install aca`, `npm i -g aca`, or `pip install aca` — install only via the scripts above. See [references/quickstart.md](references/quickstart.md).

## Create a sandbox

Imperative flow — use `--location` (NOT `--region`); mention auto-suspend so users aren't surprised when an idle sandbox suspends:

```bash
aca sandboxgroup create --name mygroup-$USER --location westus3 --set-config
aca sandbox create --group mygroup-$USER --disk ubuntu-24.04 --label name=my-sb
aca sandbox shell  -l name=my-sb        # interactive WebSocket shell
aca sandbox exec   -l name=my-sb -c "uname -a"
aca sandbox port add -l name=my-sb --port 80 --anonymous
```

**Auto-suspend gotcha:** sandboxes auto-suspend after the configured idle interval (default 5 min) — state is preserved; `aca sandbox resume -l name=my-sb` brings it back sub-second.

### Add a port locked to the signed-in user (Entra ID)

```bash
EMAIL=$(az ad signed-in-user show --query mail -o tsv)
aca sandbox port add -l name=my-sb --port 80 --email "$EMAIL"
```

## Apply a sandbox manifest (`sandbox.yaml`)

The YAML/declarative path is the recommended flow for CI/CD and reproducibility — parallel to the imperative `aca sandbox create` flow above. `init` scaffolds a starter manifest, `validate` checks it, `apply` provisions it:

```bash
aca sandbox init > sandbox.yaml          # scaffold a starter manifest
$EDITOR sandbox.yaml
aca sandbox validate --file sandbox.yaml # schema + policy check
aca sandbox apply    --file sandbox.yaml # provision (idempotent)
```

For full walkthroughs see [quickstart](references/quickstart.md) and [deploy-patterns](references/deploy-patterns.md).

## SSH into a sandbox

ACA Sandboxes do **not** support traditional SSH — no port 22, no `ssh -i`, no keypairs, no VS Code Remote SSH host. Auth is your `az login` token. When users say "ssh into my sandbox", present these in order:

1. **`aca sandbox shell -l name=my-sb`** (recommended) — interactive WebSocket shell, auth via `az login` token.
2. **Portal terminal** — open the sandbox in the [ACA portal](https://containerapps.azure.com/sandbox-groups) → click **Terminal**.

See [references/ssh-setup.md](references/ssh-setup.md) for non-interactive `exec`, key-mgmt rationale, and connector specifics.

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

Then ask the user to take a snapshot:

```bash
aca sandbox snapshot create -l name=my-sb --name post-install
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
| Entra `mail` vs alias, MCP discovery, port mgmt | [references/connections.md](references/connections.md) |
| Personal Agent onboarding + deploy code | [references/deploy-patterns.md](references/deploy-patterns.md) |
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
| OpenAPI spec | `https://management.azuredevcompute.io/openapi/v1.json` (requires Entra auth) |

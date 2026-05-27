---
name: aca-sandboxes
description: |
  Azure Container Apps Sandboxes — hardware-isolated microVMs with snapshot/resume,
  zero-trust tokens, and scale-to-zero. Driven by the `aca` CLI (1.0.0-beta.1+).
  Use when:
  - Creating or managing sandbox groups
  - Creating sandboxes (imperative `aca sandbox create` OR declarative `aca sandbox apply --file sandbox.yaml`)
  - Executing commands, opening shells, exposing ports
  - Stopping, resuming, snapshotting, committing sandboxes
  - Mounting volumes, managing egress policies
  - Deploying AI agents, MCP servers, web apps, or background tasks to sandboxes
  Triggers: "aca sandbox", "aca create", "container apps sandbox", "ACA sandbox",
  "sandbox group", "sandbox yaml", "run command in sandbox", "deploy to sandbox",
  "exec", "shell", "snapshot", "suspend", "resume", "ssh", "microvm",
  "Microsoft.App/SandboxGroups", "agent in sandbox", "sandbox as tool",
  "personal agent", "host MCP server", "excalidraw", "go yolo", "copilot sdk"
metadata:
  author: azure-container-apps-team
  version: "0.8.0"
---

# Azure Container Apps Sandboxes — `aca` CLI skill

Deploy AI agents, MCP servers, web apps, and background tasks to **ACA Sandboxes** — hardware-isolated microVMs where secrets never touch your code, anchored on the public [`aca` Rust CLI](https://github.com/microsoft/azure-container-apps/tree/main/docs/early/aca-cli).

> **Naming**
>
> **Public name:** ACA Sandboxes (also "Azure Container Apps sandboxes" in [Microsoft Learn](https://github.com/microsoft/azure-container-apps/blob/main/docs/early/sandboxes-overview.md)). **Internal codename:** ADC (Agent Dev Compute). You may see "ADC" / `agentdevcompute.io` / `azuredevcompute.io` in source paths and data-plane endpoints — same product.
>
> **Do not confuse with Container Apps Dynamic Sessions.** Dynamic Sessions is a different (prior) product with a managed-pool execution model; sandboxes give you direct programmable control. See the [Sandboxes vs. dynamic sessions comparison](https://github.com/microsoft/azure-container-apps/blob/main/docs/early/sandboxes-overview.md#sandboxes-vs-dynamic-sessions) in the public docs. The auth-scope audience `dynamicsessions.io` you'll see in `aca auth status` is an **internal implementation detail** of the sandboxes data plane — not the Dynamic Sessions product.

> **⚠️ IMPORTANT — Do NOT hallucinate CLI commands, install steps, API calls, or SSH methods.**
>
> - There is **no** `winget install aca`, `brew install aca`, `npm install -g aca`, or `pip install aca`. The `aca` CLI is installed from the [official install scripts](#install-the-aca-cli) — see Quick Start.
> - There is **no** `aca sandbox create --template`. Sandboxes are created from **disk images** (`--disk <name>` or `--disk-id <uuid>`) or **snapshots** (`--snapshot <name>` or `--snapshot-id <uuid>`). For declarative workflows, use [`aca sandbox apply --file sandbox.yaml`](#yaml-manifest-pattern).
> - There is **no** `aca deploy`, `aca init` (project scaffolding), or `aca setup` command. (`aca sandbox init` exists — it prints a YAML manifest template; see [YAML manifest pattern](#yaml-manifest-pattern).)
> - **Authentication** uses Azure CLI bearer tokens. Ensure `az` is installed and the user has run `az login`. `aca auth login` delegates to `az login`; `aca auth status` shows ARM + data-plane status.
> - The **management API** is `https://management.azuredevcompute.io`. Do NOT invent `api.agentdevcompute.io` or `api-preview.agentdevcompute.io`. The **portal** is on a different host: `https://containerapps.azure.com/sandbox-groups` (public, Azure-branded) — `https://portal.agentdevcompute.io` is the legacy codename URL and still resolves but is being phased out. The **proxy** for exposed ports is `<sandbox-id>--<port>.proxy.azuredevcompute.io`.
> - **SSH:** There is **no** traditional SSH (port 22), **no** `ssh -i` with private keys, **no** VS Code Remote SSH, **no** SSH hostname or keypair. ACA Sandboxes use a WebSocket-based shell over the management API. When users ask to SSH into a sandbox, present these options:
>   1. **`aca sandbox shell` (easiest):** `aca sandbox shell -l name=my-sb` — interactive WebSocket shell, authenticated via your `az login` token.
>   2. **Portal terminal:** Open the sandbox in the [ACA portal](https://containerapps.azure.com/sandbox-groups) → click **Terminal** — browser-based shell, no install needed.
>   3. **Node.js helper (offline / agent fan-out):** Copy `assets/ssh.mjs` to user's directory, `npm install ws`, then `node ssh.mjs <sandbox-id>` — requires `az login` and Node 18+.
> - When users ask "how do I get started", use **only** the information in this skill file and its references. Do not invent commands, flags, or workflows. The authoritative public docs live at [`microsoft/azure-container-apps/docs/early/`](https://github.com/microsoft/azure-container-apps/tree/main/docs/early).

> ### Related skills
>
> This skill is the **CLI-first successor candidate** to [`annaji-msft/acaexpress/plugin/skills/azure-sandbox`](https://github.com/annaji-msft/acaexpress/tree/main/plugin/skills/azure-sandbox) v0.1.0, opened in coordination with Jenny Lawrance + Annaji Sharma Ganti's consolidation effort. Same product; we re-anchor on the `aca` Rust CLI (the public early-access surface). For the `az sandbox` extension path, see [Other surfaces](#other-surfaces) — it remains fully supported. (Python SDK is "coming soon" per public docs — section TBD when SDK ships.)

---

## What are ACA Sandboxes?

ACA Sandboxes are a **pro-developer surface inside Azure Container Apps** for running AI agents, MCP servers, web apps, APIs, and background tasks in hardware-isolated microVMs. Unlike SaaS app builders that fully abstract compute, sandboxes give developers controls much closer to the compute layer — pick any framework, any language, any toolchain.

More and more agents need a workspace: a computer where they can run code, install packages, and access files. That workspace needs to be **isolated** so the agent can't access your credentials, files, or network. ACA Sandboxes provide this isolation with a hardware boundary (KVM microVMs) between the agent's environment and the outside world.

For the full overview — key characteristics, when-to-use, resource tiers (XS/S/M/L), lifecycle states, volumes (Azure Blob + Data Disk), and the sandboxes-vs-dynamic-sessions comparison — see the public docs:

- [Sandboxes overview](https://github.com/microsoft/azure-container-apps/blob/main/docs/early/sandboxes-overview.md)
- [Egress policies](https://github.com/microsoft/azure-container-apps/blob/main/docs/early/sandboxes-egress-policies.md)
- [Snapshots & state management](https://github.com/microsoft/azure-container-apps/blob/main/docs/early/sandboxes-snapshots-state-management.md)
- [`aca` CLI README](https://github.com/microsoft/azure-container-apps/blob/main/docs/early/aca-cli/README.md)

### Two patterns for connecting agents to sandboxes

**🤖 Pattern 1 — Agent IN Sandbox.** The agent runs **inside** the sandbox. CLIs like Claude Code and GitHub Copilot CLI run on autopilot in a secure microVM; the Copilot SDK and Claude Code Agent SDK lean on those CLIs and benefit from the same isolation. Mirrors local dev — same commands, just inside a sandbox. Use when the agent and execution environment are tightly coupled.

**🔧 Pattern 2 — Sandbox as Tool.** The agent runs **outside** (locally or on your server) and calls a sandbox remotely via `aca`. Credentials stay outside the sandbox; agent state (memory, conversation history) lives separately from execution. Update agent logic without rebuilding environments. Pay for sandboxes only when executing (scale-to-zero). Use when you need parallel fan-out, want to keep secrets out of the sandbox, or prefer cleaner separation.

---

## Prerequisites

| Requirement | Details |
|-------------|---------|
| **Azure CLI (`az`)** | Install from [learn.microsoft.com/cli/azure/install-azure-cli](https://learn.microsoft.com/cli/azure/install-azure-cli). On Windows, `aca` looks for `az.cmd`. |
| **`az login`** | Run once. `aca` delegates auth to Azure CLI; data-plane tokens are acquired automatically. |
| **`aca` CLI** | See [Install the `aca` CLI](#install-the-aca-cli). |
| **RBAC role** | `Container Apps SandboxGroup Data Owner` on the sandbox group (or higher). |
| **Microsoft Entra ID account** | Only Entra ID accounts can access sandboxes. Personal Microsoft accounts are not supported. |
| **Node.js ≥18** | Optional — only needed for the `adc-api.js` helper (in-process Node fan-out) and `ssh.mjs`. |

---

## 🚀 Quick Start

### Install the `aca` CLI

```bash
# macOS (Apple Silicon) / Linux x64
curl -sSL https://raw.githubusercontent.com/microsoft/azure-container-apps/main/docs/early/aca-cli/install.sh | bash

# Windows x64 (PowerShell)
iwr -useb https://raw.githubusercontent.com/microsoft/azure-container-apps/main/docs/early/aca-cli/install.ps1 | iex

# Verify
aca version && aca doctor

# Auth (delegates to az login)
aca auth login
aca auth status
```

Supported platforms today: **macOS ARM64, Linux x64, Windows x64**. Not yet supported: macOS x64 (Intel), Linux ARM64.

### Imperative path — create a sandbox group, then a sandbox

```bash
# Sandbox group (one-time per region)
aca sandboxgroup list
aca sandboxgroup create --name mygroup-$USER --location eastus2 --set-config
aca sandboxgroup disk list-public

# Sandbox (with a friendly label so you can target it without remembering the UUID)
aca sandbox create --group mygroup-$USER --disk ubuntu --label name=my-sb

# Use it — label selectors work alongside --id <UUID>
aca sandbox exec     -l name=my-sb -c "uname -a"
aca sandbox port add -l name=my-sb --port 80 --anonymous

# Lifecycle
aca sandbox stop     -l name=my-sb        # suspend (state preserved)
aca sandbox resume   -l name=my-sb        # resume (sub-second)
aca sandbox delete   -l name=my-sb
```

> **Disk catalog (verified):** `ubuntu, copilot, claude, node-22, node-24, php-8.3, php-8.4, dotnet-8, dotnet-9, dotnet-10, python-3.11, python-3.12, python-3.13, python-3.14, nginx, openclaw, ubuntu-systemd` (17 total). Run `aca sandboxgroup disk list-public` to confirm what's available in your region.

### YAML manifest pattern

`aca` 1.0.0-beta.1 supports a declarative workflow: write a sandbox spec in YAML, apply it.

```bash
aca sandbox init > sandbox.yaml       # prints a template
$EDITOR sandbox.yaml
aca sandbox validate --file sandbox.yaml
aca sandbox apply --file sandbox.yaml
```

Example `sandbox.yaml` (template output):

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

Use the YAML pattern when you want sandbox specs in source control, want repeatable provisioning, or want to manage egress rules / lifecycle policy as code.

### After successful deployment

**Always** ask the user to take a snapshot once an app or template is deployed and verified:

> *"Everything looks good — want me to take a snapshot so you can restore to this state instantly?"*

```bash
aca sandbox snapshot create -l name=my-sb --name post-install
```

### Deployment Output (MANDATORY)

After every deployment, the agent **MUST** output a structured summary:

```
✅ Server deployed and running in sandbox

Sandbox:  <sandbox-id>
Port:     <port-number>
Access:   Anonymous / Entra ID
URL:      https://<sandbox-id>--<port>.proxy.azuredevcompute.io

Test:
  curl https://<sandbox-id>--<port>.proxy.azuredevcompute.io
```

If the URL doesn't respond, check the [ACA portal](https://containerapps.azure.com/sandbox-groups) → Sandbox → Ports.

---

## Other surfaces

ACA Sandboxes can be driven from two surfaces today. Pick one per workflow; don't mix.

> **Python SDK is coming soon.** See [`docs/early/python-sdk/`](https://github.com/microsoft/azure-container-apps/tree/main/docs/early/python-sdk) for status.

### `aca` CLI (default — this skill's anchor)

Human + agent workflows, CI/CD, anything that shells out, YAML-manifest workflows. Install above.

### `az sandbox` extension (Azure CLI integration)

Use when your scripts are already `az`-native everywhere else.

```bash
gh release download --repo annaji-msft/acaexpress --pattern "sandbox-*-py3-none-any.whl" --dir /tmp
az extension add --source /tmp/sandbox-*-py3-none-any.whl
az sandboxgroup --help
az sandbox --help
```

### Programmatic / agent fan-out (`adc-api.js`)

In-process **Node** agent control — same management API `aca` uses, same `az login` auth. Lives at [`assets/adc-api.js`](assets/adc-api.js).

```javascript
import { AdcApi } from "./adc-api.js";
const api = new AdcApi(); // uses az CLI for auth (requires `az login`)

// Fan out across N sandboxes in parallel
const features = ["auth-module", "api-endpoints", "ui-dashboard"];
const sandboxes = await Promise.all(
  features.map(f => api.createSandbox({ diskName: "copilot", lifecycle: { autoSuspendPolicy: { enabled: false } } }))
);
await Promise.all(sandboxes.map((sbx, i) =>
  api.execShell(sbx.id, `git clone https://github.com/org/repo . && git checkout -b ${features[i]}`)
));
```

**Key methods:** `createSandbox`, `execShell`, `uploadFile`, `downloadFile`, `addPort`, `listPorts`, `getSandbox`, `deleteSandbox`, `stopSandbox`, `resumeSandbox`, `createSnapshot`, `listConnections`, `addConnectionToSandbox`, `listDiskImages`, `sshShell`.

---

## Side-by-side CLI ↔ helper reference

| Action | `aca` CLI | `adc-api.js` (Advanced) | `az sandbox` ext (Advanced) |
|---|---|---|---|
| List sandboxes | `aca sandbox list` | `api.listSandboxes()` | `az sandbox list` |
| Create (imperative) | `aca sandbox create --disk ubuntu --label name=my-sb` | `api.createSandbox({ diskName:"ubuntu" })` | `az sandbox create --disk ubuntu` |
| Create (YAML manifest) | `aca sandbox apply --file sandbox.yaml` | n/a | n/a |
| Init manifest template | `aca sandbox init > sandbox.yaml` | n/a | n/a |
| Validate manifest | `aca sandbox validate --file sandbox.yaml` | n/a | n/a |
| Exec | `aca sandbox exec -l name=my-sb -c "cmd"` | `api.execShell(id,"cmd")` | `az sandbox exec --id $ID -c "cmd"` |
| Shell | `aca sandbox shell -l name=my-sb` | `api.sshShell(id)` | `az sandbox shell --id $ID` |
| Upload | `aca sandbox fs put -l name=my-sb --src ./app.js --dest /home/user/app.js` | `api.uploadFile(id,"/path",content)` | `az sandbox fs put …` |
| Download | `aca sandbox fs get -l name=my-sb --src /path --dest ./out.txt` | `api.downloadFile(id,"/path")` | `az sandbox fs get …` |
| Add port (anonymous) | `aca sandbox port add -l name=my-sb --port 80 --anonymous` | `api.addPort(id,80,{anonymous:true})` | `az sandbox port add …` |
| Add port (Entra ID) | `aca sandbox port add -l name=my-sb --port 80 --email you@company.com` | `api.addPort(id,80,{email:"you@company.com"})` | `az sandbox port add … --email …` |
| Egress (declarative) | `aca sandbox egress apply -l name=my-sb --file egress.yaml` | `api.setEgressPolicy(id, …)` | `az sandbox egress add …` |
| Snapshot | `aca sandbox snapshot create -l name=my-sb --name mysnap` | `api.createSnapshot(id,"mysnap")` | `az sandbox snapshot create …` |
| Stop / Resume | `aca sandbox stop -l name=my-sb` / `aca sandbox resume -l name=my-sb` | `api.stopSandbox(id)` / `api.resumeSandbox(id)` | `az sandbox stop` / `az sandbox resume` |
| Disk catalog | `aca sandboxgroup disk list-public` | `api.listDiskImages()` | `az sandboxgroup disk list-public` |

`az sandbox` flag spellings shown for orientation — confirm against `az sandbox <verb> --help`. `adc-api.js` is the current in-process Node surface; Python SDK is the supported in-process Python surface once it ships.

---

## Templates

| Template | What it does | Disk / Node | Ports | Notes |
|----------|-------------|-------------|-------|-------|
| 🎨 **Excalidraw MCP** | Draw diagrams in VS Code / Claude / ChatGPT | `copilot` or `ubuntu` + Node 24 | 80 (anonymous) | Clone + build + start in sandbox. See [assets/excalidraw-mcp-template/README.md](assets/excalidraw-mcp-template/README.md). |
| 🤖 **Personal Agent** | Full personal workspace — chat + Office 365 email/calendar + M365 Copilot + ACA Sandbox management + memory + crons + watchers + multi-agent routing | `copilot` preset + Node 24 | 80 (Entra ID, locked to user) | Requires 4 connections: GitHub Copilot, Office 365, M365 Copilot, ACA Sandbox Management. See [assets/personal-agent-template/README.md](assets/personal-agent-template/README.md) + [Personal Agent onboarding](#personal-agent--onboarding-guide). |
| 🔌 **adc-api.js** | Node API helper — create sandboxes, exec commands, manage ports, fan out | Any disk, Node 18+ | n/a | Import in any template. See [assets/adc-api.js](assets/adc-api.js). |

---

## ⚠️ Gotchas & Important Notes

| Topic | Details |
|-------|---------|
| **Port Entra-email** | Use the email returned by `az ad signed-in-user show --query mail -o tsv` for port Entra ID auth. **For some accounts** this differs from `az account show --query user.name -o tsv` (e.g., display-name vs alias) — when they differ, only the `mail` value works. Use `aca sandbox port add -l name=my-sb --port 80 --email "$EMAIL"`. |
| **Personal connectors + port order** | Office 365 and M365 Copilot are **personal connectors** — require Entra ID port auth attached BEFORE the connector. Otherwise: `500 Cannot add personal connector because port does not have Entra ID authentication`. After personal connectors are attached, port add/remove via `adc-api.js` may return `409 caller email could not be determined` — use the Portal in that case. |
| **`copilot` disk preset** | Confirmed in `aca sandboxgroup disk list-public`. Includes Node 24 pre-installed. For the plain `ubuntu` disk, install Node 24 yourself: `npm install -g n && n 24`. |
| **npm in sandboxes** | Run `npm config set strict-ssl false` before `npm install` — required due to sandbox egress TLS inspection. After install, verify: `ls node_modules/ \| wc -l` — silent failures can occur on network timeouts. |
| **TypeScript** | Prefer `npx tsx src/index.ts` over `tsc && node dist/index.js` — tsx handles ESM module resolution natively and avoids `.js` extension issues with `NodeNext` module resolution. |
| **`execShell` timing** | Blocks until the command completes. `npm install` takes 2–5 minutes (egress proxy), `git clone` 30s–2min, `npm run build` 1–3min. Do NOT assume the command is stuck. |
| **Auto-suspend** | Sandboxes suspend after idle. Configured via `lifecycle.autoSuspendPolicy` (YAML manifest) or `--no-suspend` flag on create. Resume with `aca sandbox resume`. |
| **MCP auto-detection** | Connectors are exposed as MCP servers inside the sandbox. Config is auto-written to `/root/.copilot/mcp-config.json` by the in-sandbox Node Agent when connections are attached. If missing after attaching connections, restart the sandbox to trigger regeneration. |
| **Server health after `nohup`** | Wait 5–10 seconds after `nohup node index.js &` before probing the URL — server may still be starting. |
| **Not Dynamic Sessions** | ACA Sandboxes and Container Apps Dynamic Sessions are **different products**. Sandboxes give you direct programmable microVMs; Dynamic Sessions provide a managed-pool execution model abstracted from infrastructure. See the [comparison table](https://github.com/microsoft/azure-container-apps/blob/main/docs/early/sandboxes-overview.md#sandboxes-vs-dynamic-sessions) in the public docs. The `dynamicsessions.io` auth-scope audience is an internal sandboxes data-plane detail — not the Dynamic Sessions product. |

### Uninstall

```bash
# Plugin (Copilot CLI)
copilot plugin uninstall azure-container-apps@azure-container-apps

# Plugin (Claude Code)
claude plugin uninstall azure-container-apps@azure-container-apps

# aca CLI
rm $(which aca) && rm -rf ~/.aca

# az sandbox extension
az extension remove --name sandbox
```

---

## Security

- **Hardware isolation** — each sandbox is a separate KVM microVM.
- **Zero-trust tokens** — real tokens never enter the sandbox. Egress proxy swaps placeholder credentials for real ones at the boundary.
- **Egress proxy** — all outbound traffic is inspected; per-sandbox allowlists via `egressPolicy` in YAML or `aca sandbox egress apply`.
- **Port auth** — Entra ID (locked to a specific user) or anonymous (public).
- **Personal connector isolation** — sandboxes with personal connectors (Office 365, M365 Copilot) REQUIRE Entra ID port auth locked to the user's email. Only the connection owner can access the sandbox URL.
- **Bearer tokens** — short-lived Entra ID tokens via Azure CLI; no secrets to manage.

See [references/security.md](references/security.md) for details.

---

## 🤖 Personal Agent — Onboarding Guide

> Full end-to-end onboarding for the Personal Agent template with all 4 connectors.

### Setup order (critical — do this exactly)

1. **Create connections in the portal** (one-time):
   - GitHub Copilot → OAuth consent
   - Office 365 → OAuth consent (personal connector)
   - M365 Copilot → OAuth consent (personal connector)
   - ACA Sandbox Management → auto-provisioned API key

2. **Create the sandbox** with the `copilot` disk:
   ```bash
   aca sandbox create --group mygroup --disk copilot --label name=personal-agent --no-suspend
   ```
   Or via YAML:
   ```yaml
   disk: copilot
   resources: { cpu: 2000m, memory: 4096Mi }
   lifecycle: { autoSuspendPolicy: { enabled: false } }
   ```

3. **Add port 80 with Entra ID auth — BEFORE attaching personal connectors:**
   ```bash
   EMAIL=$(az ad signed-in-user show --query mail -o tsv)
   aca sandbox port add -l name=personal-agent --port 80 --email "$EMAIL"
   ```
   Skipping this step makes attaching Office 365 / M365 Copilot fail with `500 Cannot add personal connector because port does not have Entra ID authentication`.

4. **Attach connections** to the sandbox (GitHub Copilot first, then the rest). Use the portal, or `adc-api.js` `api.addConnectionToSandbox(sandboxId, connectionId)` for each.

5. **Verify MCP config:** the in-sandbox Node Agent writes `/root/.copilot/mcp-config.json` when connections are attached. If missing, restart the sandbox to trigger regeneration.
   ```bash
   aca sandbox exec -l name=personal-agent -c "cat /root/.copilot/mcp-config.json || echo MISSING"
   ```

6. **Deploy the Personal Agent template** — upload files, install Node 24 + deps, start the server. See the [deploy path code reference](#deploy-path-code-reference) below.

### Entra email vs alias

| Command | Returns | Use for |
|---------|---------|---------|
| `az account show --query user.name` | alias (e.g., `anganti@microsoft.com`) | ❌ Do NOT use for port auth |
| `az ad signed-in-user show --query mail -o tsv` | Entra email (e.g., `Annaji.Ganti@microsoft.com`) | ✅ Use this for port auth |
| `az ad signed-in-user show --query userPrincipalName -o tsv` | UPN (often same as alias) | ❌ Same as alias |

The port Entra ID auth email **must match** the `mail` attribute in the user's Entra directory. For some accounts all three commands return the same value — when they differ, only `mail` works.

### Port management limitations with personal connectors

When personal connectors (Office 365, M365 Copilot) are attached to a sandbox:

- Port add/remove via `adc-api.js` will fail with `409 caller email could not be determined` because `az` CLI tokens for the sandbox scope don't include the `email` JWT claim.
- **Use `aca sandbox port` or the Portal** for port management when personal connectors are involved — both flow through interactive Entra login and produce tokens with the email claim.

### Your sandbox is locked to YOU

Sandboxes with personal connectors have Entra ID port auth locked to **your email only**. Only you can access the sandbox URL in a browser; your emails, calendar, and documents are never exposed to anyone else. The MCP tools (Office 365, M365 Copilot) operate under your identity.

### MCP server discovery

Connectors are exposed inside the sandbox as MCP servers:

- **Instance Network Proxy:** `http://100.64.100.1/mcp` — all connector tools via a single endpoint
- **Identity Proxy:** `http://100.64.100.2/msi/token` — managed identity tokens
- **ACA Sandbox Management MCP:** `https://management.azuredevcompute.io/mcp` — sandbox management tools

The Personal Agent auto-reads `/root/.copilot/mcp-config.json` at startup to discover all servers. No manual MCP config needed.

### Available MCP tools (discovered at runtime)

| Connector | Tools | Notes |
|-----------|-------|-------|
| **Office 365** | `send_mail`, `get_emails`, `get_email`, `reply_to_email`, `list_calendars`, `get_events`, `get_event` | Personal connector — uses your email identity |
| **M365 Copilot** | `create_copilot_conversation`, `chat_copilot_conversation` | Slow (10–30s per call). Use 5-min timeout. Personal connector. |
| **ACA Sandbox Management** | `list_disk_images`, `create_disk_image`, `get_disk_image`, `create_sandbox`, `delete_sandbox`, `execute_command`, `list_ports`, `add_port`, `remove_port`, `deploy_app`, `create_content_package`, `create_static_site` | Sandbox management from within the agent |
| **Built-in MCP** | `microsoft-learn`, `deepwiki` | General knowledge tools |

### Token & auth flow

```
User → Browser → Sandbox URL (Entra ID login)
                    ↓
              Personal Agent (index.js)
                    ↓
              Copilot SDK (gho_placeholder token)
                    ↓
              Egress Proxy swaps gho_placeholder → real GitHub token
                    ↓
              GitHub Copilot API (AI models)
                    ↓
              MCP tool calls → Instance Network Proxy (100.64.100.1)
                    ↓
              Office 365 / M365 Copilot / ACA Sandbox Management
```

`gho_placeholder` is auto-set by the code when `ADC_SANDBOX_ID` env var is detected. The egress proxy intercepts outbound requests and swaps the placeholder for real credentials. Real tokens **never exist** inside the sandbox.

### Deployment gotchas

| Issue | Solution |
|-------|----------|
| `uploadFile` creates files but not directories | `mkdir -p /path/to/dir` first (`aca sandbox exec` or `api.execShell`) |
| `npm install` silent failures | Always verify `ls node_modules/ \| wc -l`. Run `npm config set strict-ssl false` first (egress TLS). |
| `listModels()` fails with "Client not connected" | Expected inside sandbox. Agent falls back to hardcoded defaults. |
| M365 Copilot calls timeout at 60s | Use 300s (5-min) timeout. Don't reduce. |
| `execShell` returns 500 intermittently | Transient error. Retry with backoff (2–3 retries). |
| Port URL returns 502/504 | Server may still be starting. Wait 5–10s after `node index.js &`. |
| MCP config missing after attaching connections | Restart the sandbox — Node Agent regenerates on boot. |

### Multi-agent routing

Users can prefix messages with `@agent_name` to route to specialized agents:

| Prefix | Agent | Focus |
|--------|-------|-------|
| `@email` | Email Agent | Reading, drafting, sending, searching emails |
| `@research` | Research Agent | M365 Copilot queries, document search, SharePoint |
| (none) | General Agent | Everything — auto-detects intent |

### Deploy path code reference

```javascript
import { AdcApi } from "./adc-api.js";
const api = new AdcApi();
const sandboxId = "<from-user>";

// 1. Create dirs
await api.execShell(sandboxId, "mkdir -p /home/user/personal-agent/public");

// 2. Upload files
await api.uploadFile(sandboxId, "/home/user/personal-agent/index.js", indexJsContent);
await api.uploadFile(sandboxId, "/home/user/personal-agent/package.json", packageJsonContent);
await api.uploadFile(sandboxId, "/home/user/personal-agent/public/index.html", htmlContent);

// 3. Install Node 24 + deps
await api.execShell(sandboxId, "npm install -g n && n 24");
await api.execShell(sandboxId, "cd /home/user/personal-agent && npm config set strict-ssl false && npm install");

// 4. Verify
const check = await api.execShell(sandboxId, "ls /home/user/personal-agent/node_modules/ | wc -l");
if (parseInt(check.stdout?.trim() || "0") < 10) throw new Error("npm install failed");

// 5. Start
await api.execShell(sandboxId, "cd /home/user/personal-agent && PORT=80 nohup node index.js > /tmp/server.log 2>&1 &");

// 6. Wait + verify
await new Promise(r => setTimeout(r, 5000));
const health = await api.execShell(sandboxId, "curl -s http://localhost/health");
console.log(health.stdout); // {"status":"ok","app":"personal-agent",...}
```

---

## 📚 Learn More

| Topic | Reference |
|-------|-----------|
| **Sandboxes overview** | [microsoft/azure-container-apps/docs/early/sandboxes-overview.md](https://github.com/microsoft/azure-container-apps/blob/main/docs/early/sandboxes-overview.md) |
| **Egress policies** | [microsoft/azure-container-apps/docs/early/sandboxes-egress-policies.md](https://github.com/microsoft/azure-container-apps/blob/main/docs/early/sandboxes-egress-policies.md) |
| **Snapshots & state management** | [microsoft/azure-container-apps/docs/early/sandboxes-snapshots-state-management.md](https://github.com/microsoft/azure-container-apps/blob/main/docs/early/sandboxes-snapshots-state-management.md) |
| **`aca` CLI reference** | [microsoft/azure-container-apps/docs/early/aca-cli/README.md](https://github.com/microsoft/azure-container-apps/blob/main/docs/early/aca-cli/README.md) |
| **OpenAPI spec** | [management.azuredevcompute.io/openapi/v1.json](https://management.azuredevcompute.io/openapi/v1.json) |
| **Architecture** | [references/architecture.md](references/architecture.md) |
| **Prerequisites** | [references/prerequisites.md](references/prerequisites.md) |
| **Quickstart** | [references/quickstart.md](references/quickstart.md) |
| **Deploy patterns** | [references/deploy-patterns.md](references/deploy-patterns.md) |
| **SSH setup** | [references/ssh-setup.md](references/ssh-setup.md) |
| **Security model** | [references/security.md](references/security.md) |
| **Connections** | [references/connections.md](references/connections.md) |
| **Troubleshooting** | [references/troubleshooting.md](references/troubleshooting.md) |

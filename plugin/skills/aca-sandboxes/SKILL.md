---
name: aca-sandboxes
description: >-
  Create and manage Azure Container Apps Sandboxes (ACA Sandboxes) — hardware-isolated
  microVMs with snapshots and scale-to-zero — using the public `aca` CLI, imperatively
  or via YAML manifest.
  USE FOR: sandbox group, sandbox create/apply/exec/shell, expose port, snapshot,
  suspend/resume, mount volume, egress policy, deploy AI agent / MCP server / web app,
  personal agent, microVM, `Microsoft.App/SandboxGroups`.
  DO NOT USE FOR: Container Apps Dynamic Sessions (different product), Azure Functions,
  Container Apps deploys, AKS pods, App Service, Cosmos, Container Registry.
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

## Examples

### Create + use a sandbox (imperative)

```bash
aca sandboxgroup create --name mygroup --location eastus2 --set-config
aca sandbox create --group mygroup --disk ubuntu --label name=my-sb
aca sandbox exec     -l name=my-sb -c "uname -a"
aca sandbox port add -l name=my-sb --port 80 --anonymous
```

### Declarative — YAML manifest

```bash
aca sandbox init > sandbox.yaml
aca sandbox validate --file sandbox.yaml
aca sandbox apply    --file sandbox.yaml
```

### Add a port locked to the signed-in user (Entra ID)

```bash
EMAIL=$(az ad signed-in-user show --query mail -o tsv)
aca sandbox port add -l name=my-sb --port 80 --email "$EMAIL"
```

For full walkthroughs see [quickstart](references/quickstart.md) and [deploy-patterns](references/deploy-patterns.md).

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

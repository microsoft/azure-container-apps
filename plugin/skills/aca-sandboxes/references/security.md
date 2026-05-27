# Security model

ACA Sandboxes provide hardware-isolated microVMs with a zero-trust token boundary.

## Isolation primitives

- **Hardware isolation** — each sandbox is a separate KVM microVM.
- **Zero-trust tokens** — real tokens never enter the sandbox. The egress proxy swaps placeholder credentials for real ones at the boundary.
- **Egress proxy** — all outbound traffic is inspected; per-sandbox allowlists via `egressPolicy` in YAML or `aca sandbox egress apply`.
- **Bearer tokens** — short-lived Entra ID tokens via Azure CLI; no secrets to manage.

## Port authentication

- **Anonymous** — public; no auth required to hit the port.
- **Entra ID** — locked to a specific user's Entra `mail` attribute; only that user can reach the URL.

When personal connectors (Office 365, M365 Copilot) are attached to a sandbox, the port must have Entra ID auth locked to the user's `mail`. Only the connection owner can access the sandbox URL.

## Token & auth flow (with personal connectors)

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

`gho_placeholder` is auto-set when the `ADC_SANDBOX_ID` env var is detected. The egress proxy intercepts outbound requests and swaps the placeholder for real credentials. Real tokens **never exist** inside the sandbox.

## Audiences and scopes

`aca auth status` shows ARM + data-plane tokens. The data-plane audience is `dynamicsessions.io` — this is an internal sandboxes implementation detail, **not** the separate Container Apps Dynamic Sessions product. See [the comparison in the public overview](https://github.com/microsoft/azure-container-apps/blob/main/docs/early/sandboxes-overview.md#sandboxes-vs-dynamic-sessions).

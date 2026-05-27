# Security model

ACA Sandboxes provide hardware-isolated microVMs. The information below is limited to what is documented in the public [`microsoft/azure-container-apps/docs/early/`](https://github.com/microsoft/azure-container-apps/tree/main/docs/early) source.

## Isolation primitives

- **Hardware isolation** — each sandbox is a separate microVM with its own CPU, memory, disk, and network boundary (see [sandboxes-overview.md](https://github.com/microsoft/azure-container-apps/blob/main/docs/early/sandboxes-overview.md)).
- **Egress policy** — per-sandbox outbound allow/deny lists configured via `egressPolicy` in `sandbox.yaml` or `aca sandbox egress apply --file egress.yaml`. See [sandboxes-egress-policies.md](https://github.com/microsoft/azure-container-apps/blob/main/docs/early/sandboxes-egress-policies.md).
- **Bearer tokens** — auth uses short-lived Entra ID tokens via Azure CLI (`az login`). No long-lived secrets to manage in the skill.

## Port authentication

When you expose a port with `aca sandbox port add`, choose one of:

- **Anonymous** (`--anonymous`) — public; no auth required to hit the URL.
- **Entra ID** (`--email <email>`) — locked to a specific user's Entra `mail` attribute; only that user can reach the URL in a browser. See [connections.md](connections.md) for the `mail` vs alias gotcha.

## Audiences and scopes

`aca auth status` shows ARM + data-plane tokens. The data-plane audience is `dynamicsessions.io` — this is an **internal sandboxes implementation detail**, **not** the separate Container Apps Dynamic Sessions product. See [the comparison in the public overview](https://github.com/microsoft/azure-container-apps/blob/main/docs/early/sandboxes-overview.md#sandboxes-vs-dynamic-sessions).

## Connector / token-swap flow

> **TODO:** if external connectors (e.g. GitHub Copilot, Office 365) are attached to a sandbox, the token model — how placeholder credentials inside the sandbox are exchanged for real tokens at the egress boundary — is **not yet documented in the public [`microsoft/azure-container-apps`](https://github.com/microsoft/azure-container-apps/tree/main/docs/early) docs**. Update this section once published.

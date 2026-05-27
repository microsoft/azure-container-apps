# Personal Agent template

A full personal workspace running inside an ACA sandbox: chat UI + Office 365 (email, calendar) + M365 Copilot + ACA Sandbox Management + memory + crons + watchers + multi-agent routing.

## Status

**v0.8.0 placeholder.** Template source files (`index.js`, `package.json`, `public/index.html`, deploy script) will land in v0.9. Until then, follow the onboarding recipe in [`../../references/deploy-patterns.md`](../../references/deploy-patterns.md).

## Required connections

Create all four in the portal **before** running the deploy script:

1. **GitHub Copilot** — OAuth consent
2. **Office 365** — OAuth consent (personal connector)
3. **M365 Copilot** — OAuth consent (personal connector)
4. **ACA Sandbox Management** — auto-provisioned API key

## Sandbox shape

| Field | Value |
|-------|-------|
| Disk | `copilot` (Node 24 pre-installed) |
| CPU / Memory | `2000m` / `4096Mi` |
| Auto-suspend | disabled (`--no-suspend`) |
| Port | `80`, Entra ID auth locked to your `mail` attribute |

Port 80 with Entra ID auth **must** be added BEFORE the Office 365 and M365 Copilot connectors are attached. See [`../../references/deploy-patterns.md`](../../references/deploy-patterns.md) for the full setup order.

## Related references

- [`../../references/deploy-patterns.md`](../../references/deploy-patterns.md) — full onboarding + multi-agent routing + deploy code
- [`../../references/security.md`](../../references/security.md) — token flow with personal connectors
- [`../../references/connections.md`](../../references/connections.md) — MCP discovery + Entra email
- [`../../references/troubleshooting.md`](../../references/troubleshooting.md) — gotchas

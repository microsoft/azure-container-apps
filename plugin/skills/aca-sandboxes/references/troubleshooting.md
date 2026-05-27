# Troubleshooting and gotchas

## Common gotchas

| Topic | Details |
|-------|---------|
| **Port Entra-email** | Use the email returned by `az ad signed-in-user show --query mail -o tsv`. For some accounts this differs from `az account show --query user.name -o tsv` — when they differ, only `mail` works. See [connections.md](connections.md). |
| **Personal connectors + port order** | Office 365 and M365 Copilot require Entra ID port auth attached BEFORE the connector, otherwise: `500 Cannot add personal connector because port does not have Entra ID authentication`. After personal connectors are attached, port add/remove via `adc-api.js` may return `409 caller email could not be determined` — use the Portal in that case. |
| **`copilot` disk preset** | Confirmed in `aca sandboxgroup disk list-public`. Includes Node 24 pre-installed. For the plain `ubuntu` disk, install Node 24 yourself: `npm install -g n && n 24`. |
| **npm in sandboxes** | Run `npm config set strict-ssl false` before `npm install` — required due to sandbox egress TLS inspection. After install, verify: `ls node_modules/ \| wc -l` — silent failures can occur on network timeouts. |
| **TypeScript** | Prefer `npx tsx src/index.ts` over `tsc && node dist/index.js` — tsx handles ESM module resolution natively and avoids `.js` extension issues with `NodeNext` module resolution. |
| **`execShell` timing** | Blocks until the command completes. `npm install` takes 2–5 minutes (egress proxy), `git clone` 30s–2min, `npm run build` 1–3min. Do NOT assume the command is stuck. |
| **Auto-suspend** | Sandboxes suspend after idle. Configured via `lifecycle.autoSuspendPolicy` (YAML manifest) or `--no-suspend` flag on create. Resume with `aca sandbox resume`. |
| **MCP auto-detection** | Connectors are exposed as MCP servers inside the sandbox. Config is auto-written to `/root/.copilot/mcp-config.json` by the in-sandbox Node Agent when connections are attached. If missing after attaching, restart the sandbox to trigger regeneration. |
| **Server health after `nohup`** | Wait 5–10 seconds after `nohup node index.js &` before probing the URL — server may still be starting. |
| **Not Dynamic Sessions** | ACA Sandboxes and Container Apps Dynamic Sessions are **different products**. See the [comparison table](https://github.com/microsoft/azure-container-apps/blob/main/docs/early/sandboxes-overview.md#sandboxes-vs-dynamic-sessions) in the public docs. |

## Deployment gotchas

| Issue | Solution |
|-------|----------|
| `uploadFile` creates files but not directories | `mkdir -p /path/to/dir` first (`aca sandbox exec` or `api.execShell`) |
| `npm install` silent failures | Always verify `ls node_modules/ \| wc -l`. Run `npm config set strict-ssl false` first (egress TLS). |
| `listModels()` fails with "Client not connected" | Expected inside sandbox. Agent falls back to hardcoded defaults. |
| M365 Copilot calls timeout at 60s | Use 300s (5-min) timeout. Don't reduce. |
| `execShell` returns 500 intermittently | Transient error. Retry with backoff (2–3 retries). |
| Port URL returns 502/504 | Server may still be starting. Wait 5–10s after `node index.js &`. |
| MCP config missing after attaching connections | Restart the sandbox — Node Agent regenerates on boot. |

## Uninstall

```bash
# Plugin (Copilot CLI)
copilot plugin uninstall azure-container-apps@azure-container-apps

# Plugin (Claude Code)
claude plugin uninstall azure-container-apps@azure-container-apps

# aca CLI
rm $(which aca) && rm -rf ~/.aca
```

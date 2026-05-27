# Troubleshooting and gotchas

## Common gotchas

| Topic | Details |
|-------|---------|
| **Port Entra-email** | Use the email returned by `az ad signed-in-user show --query mail -o tsv`. For some accounts this differs from `az account show --query user.name -o tsv` — when they differ, only `mail` works. See [connections.md](connections.md). |
| **Disk catalog** | Run `aca sandboxgroup disk list-public` for the up-to-date list. `ubuntu` is the safest default. Specialty disks (e.g. `copilot`, `python-3.13`, `node-24`) may have pre-installed runtimes that save install time. |
| **`aca sandbox exec` timing** | Blocks until the command completes. `npm install` can take several minutes through the egress proxy, `git clone` 30s–2min. Do NOT assume the command is stuck. |
| **Auto-suspend** | Sandboxes auto-suspend after the configured idle interval (default 5 min). Configure via YAML `lifecycle.autoSuspendPolicy` on `aca sandbox apply`, or post-create via `aca sandbox lifecycle set --auto-suspend <seconds>`. Resume with `aca sandbox resume`. **There is no `--no-suspend` flag on `aca sandbox create`.** |
| **Server health after `nohup`** | Wait 5–10 seconds after `nohup node index.js &` before probing the URL — the server may still be binding. |
| **Not Dynamic Sessions** | ACA Sandboxes and Container Apps Dynamic Sessions are **different products**. See the [comparison table](https://github.com/microsoft/azure-container-apps/blob/main/docs/early/sandboxes-overview.md#sandboxes-vs-dynamic-sessions). |

## Deployment gotchas

| Issue | Solution |
|-------|----------|
| `aca sandbox fs write` fails because parent directory doesn't exist | Run `aca sandbox exec ... -c "mkdir -p /path/to/dir"` first |
| `aca sandbox exec` returns 500 intermittently | Transient error. Retry with backoff (2–3 retries). |
| Port URL returns 502/504 | Server may still be starting. Wait 5–10s after `node index.js &`. |
| `npm install` appears to complete but `node_modules/` is empty | Egress timeouts during install are silent. Verify with `ls node_modules/ \| wc -l`. If install consistently fails, check egress policy: outbound to `registry.npmjs.org` (and equivalents) must be allowed. |

## Uninstall

```bash
# Plugin (Copilot CLI)
copilot plugin uninstall azure-container-apps@azure-container-apps

# Plugin (Claude Code)
claude plugin uninstall azure-container-apps@azure-container-apps

# aca CLI
rm $(which aca) && rm -rf ~/.aca
```

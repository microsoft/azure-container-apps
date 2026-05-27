# Architecture — patterns and surfaces

## Two patterns for connecting agents to sandboxes

**Pattern 1 — Agent IN Sandbox.** The agent runs **inside** the sandbox. CLIs like Claude Code and GitHub Copilot CLI run on autopilot in a secure microVM; the Copilot SDK and Claude Code Agent SDK lean on those CLIs and benefit from the same isolation. Mirrors local dev — same commands, just inside a sandbox. Use when the agent and execution environment are tightly coupled.

**Pattern 2 — Sandbox as Tool.** The agent runs **outside** (locally or on your server) and calls a sandbox remotely via `aca`. Credentials stay outside the sandbox; agent state (memory, conversation history) lives separately from execution. Update agent logic without rebuilding environments. Pay for sandboxes only when executing (scale-to-zero). Use when you need parallel fan-out, want to keep secrets out of the sandbox, or prefer cleaner separation.

## Surfaces

ACA Sandboxes can be driven from two surfaces today. Pick one per workflow; don't mix.

> Python SDK is coming soon. See [`docs/early/python-sdk/`](https://github.com/microsoft/azure-container-apps/tree/main/docs/early/python-sdk) for status.

### `aca` CLI (default — the skill's anchor)

Human + agent workflows, CI/CD, anything that shells out, YAML-manifest workflows. See [quickstart.md](quickstart.md) for install.

### Programmatic / agent fan-out (`adc-api.js`)

In-process **Node** agent control — same management API `aca` uses, same `az login` auth. Lives at [`../assets/adc-api.js`](../assets/adc-api.js).

```javascript
import { AdcApi } from "./adc-api.js";
const api = new AdcApi();

const features = ["auth-module", "api-endpoints", "ui-dashboard"];
const sandboxes = await Promise.all(
  features.map(f => api.createSandbox({ diskName: "copilot" }))
);
await Promise.all(sandboxes.map((sbx, i) =>
  api.execShell(sbx.id, `git clone https://github.com/org/repo . && git checkout -b ${features[i]}`)
));
```

**Key methods:** `createSandbox`, `execShell`, `uploadFile`, `downloadFile`, `addPort`, `listPorts`, `getSandbox`, `deleteSandbox`, `stopSandbox`, `resumeSandbox`, `createSnapshot`, `listConnections`, `addConnectionToSandbox`, `listDiskImages`, `sshShell`.

## Side-by-side CLI ↔ helper reference

| Action | `aca` CLI | `adc-api.js` |
|---|---|---|
| List sandboxes | `aca sandbox list` | `api.listSandboxes()` |
| Create (imperative) | `aca sandbox create --disk ubuntu --label name=my-sb` | `api.createSandbox({ diskName:"ubuntu" })` |
| Create (YAML manifest) | `aca sandbox apply --file sandbox.yaml` | n/a |
| Init manifest template | `aca sandbox init > sandbox.yaml` | n/a |
| Validate manifest | `aca sandbox validate --file sandbox.yaml` | n/a |
| Exec | `aca sandbox exec -l name=my-sb -c "cmd"` | `api.execShell(id,"cmd")` |
| Shell | `aca sandbox shell -l name=my-sb` | `api.sshShell(id)` |
| Upload | `aca sandbox fs put -l name=my-sb --src ./app.js --dest /home/user/app.js` | `api.uploadFile(id,"/path",content)` |
| Download | `aca sandbox fs get -l name=my-sb --src /path --dest ./out.txt` | `api.downloadFile(id,"/path")` |
| Add port (anonymous) | `aca sandbox port add -l name=my-sb --port 80 --anonymous` | `api.addPort(id,80,{anonymous:true})` |
| Add port (Entra ID) | `aca sandbox port add -l name=my-sb --port 80 --email you@company.com` | `api.addPort(id,80,{email:"you@company.com"})` |
| Egress (declarative) | `aca sandbox egress apply -l name=my-sb --file egress.yaml` | `api.setEgressPolicy(id, …)` |
| Snapshot | `aca sandbox snapshot create -l name=my-sb --name mysnap` | `api.createSnapshot(id,"mysnap")` |
| Stop / Resume | `aca sandbox stop -l name=my-sb` / `aca sandbox resume -l name=my-sb` | `api.stopSandbox(id)` / `api.resumeSandbox(id)` |
| Disk catalog | `aca sandboxgroup disk list-public` | `api.listDiskImages()` |

`adc-api.js` is the current in-process Node surface; Python SDK will be the supported in-process Python surface once it ships.

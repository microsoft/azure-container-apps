# Architecture — patterns and surfaces

## Two patterns for connecting agents to sandboxes

**Pattern 1 — Agent IN Sandbox.** The agent runs **inside** the sandbox. CLIs like Claude Code and GitHub Copilot CLI run on autopilot in a secure microVM; the Copilot SDK and Claude Code Agent SDK lean on those CLIs and benefit from the same isolation. Mirrors local dev — same commands, just inside a sandbox. Use when the agent and execution environment are tightly coupled.

**Pattern 2 — Sandbox as Tool.** The agent runs **outside** (locally or on your server) and calls a sandbox remotely via the `aca` CLI. Credentials stay outside the sandbox; agent state (memory, conversation history) lives separately from execution. Update agent logic without rebuilding environments. Pay for sandboxes only when executing (scale-to-zero). Use when you need parallel fan-out, want to keep secrets out of the sandbox, or prefer cleaner separation.

## Surface

The `aca` CLI is the supported surface today. Drives all human and agent workflows: imperative commands, YAML manifests, CI/CD, anything that shells out. See [quickstart.md](quickstart.md) for install.

> A Python SDK is coming soon. See [`docs/early/python-sdk/`](https://github.com/microsoft/azure-container-apps/tree/main/docs/early/python-sdk) for status.

## Common operations

| Action | Command |
|---|---|
| List sandboxes | `aca sandbox list` |
| Create (imperative) | `aca sandbox create --group <g> --disk ubuntu --label name=my-sb` |
| Create (YAML manifest) | `aca sandbox apply --file sandbox.yaml` |
| Init manifest template | `aca sandbox init > sandbox.yaml` |
| Validate manifest | `aca sandbox validate --file sandbox.yaml` |
| Exec a one-off command | `aca sandbox exec -l name=my-sb -c "cmd"` |
| Open an interactive shell | `aca sandbox shell -l name=my-sb` |
| Upload a file | `aca sandbox fs put -l name=my-sb --src ./app.js --dest /home/user/app.js` |
| Download a file | `aca sandbox fs get -l name=my-sb --src /path --dest ./out.txt` |
| Add port (anonymous) | `aca sandbox port add -l name=my-sb --port 80 --anonymous` |
| Add port (Entra ID) | `aca sandbox port add -l name=my-sb --port 80 --email you@company.com` |
| Apply egress policy | `aca sandbox egress apply -l name=my-sb --file egress.yaml` |
| Snapshot | `aca sandbox snapshot create -l name=my-sb --name mysnap` |
| Stop / Resume | `aca sandbox stop -l name=my-sb` / `aca sandbox resume -l name=my-sb` |
| Disk catalog | `aca sandboxgroup disk list-public` |


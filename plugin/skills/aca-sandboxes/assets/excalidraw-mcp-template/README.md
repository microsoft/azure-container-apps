# Excalidraw MCP template

Deploy an [Excalidraw](https://excalidraw.com) MCP server inside an ACA sandbox so AI agents (Claude Code, GitHub Copilot, ChatGPT, etc.) can create and edit Excalidraw diagrams as a tool.

## Status

**v0.8.0 placeholder.** Template assets (Dockerfile, source, deploy script) will land in v0.9. Until then, follow the manual recipe below.

## Manual recipe

| Step | Command / detail |
|------|------------------|
| Disk | `ubuntu` is the safe default. Run `aca sandboxgroup disk list-public` to see specialty disks (e.g. `copilot`, `node-24`) that may have Node pre-installed in your region. |
| Create sandbox | `aca sandbox create --group <yourgroup> --disk ubuntu --label name=excalidraw-mcp` |
| Port | `aca sandbox port add -l name=excalidraw-mcp --port 80 --anonymous` |
| Source | Clone an Excalidraw MCP server repo into the sandbox via `aca sandbox exec ... git clone ...` |
| Build + start | `aca sandbox exec ... -c "cd /home/user/app && npm install && PORT=80 nohup node server.js > /tmp/srv.log 2>&1 &"` |
| Verify | `curl https://<sandbox-id>--80.proxy.azuredevcompute.io/health` |

After verification, snapshot the sandbox:

```bash
aca sandbox snapshot -l name=excalidraw-mcp --name post-install
```

> **TODO (post-v0.8.0):** how an MCP server inside a sandbox is **discovered** by an external agent (Claude Code, GitHub Copilot, ChatGPT) is not yet documented in the public [`microsoft/azure-container-apps`](https://github.com/microsoft/azure-container-apps/tree/main/docs/early) docs. For now, agents point to the public proxy URL above.

## Related references

- [`../../references/quickstart.md`](../../references/quickstart.md)
- [`../../references/deploy-patterns.md`](../../references/deploy-patterns.md)
- [`../../references/troubleshooting.md`](../../references/troubleshooting.md) (silent npm failures, server-health timing)

# Excalidraw MCP template

Deploy an [Excalidraw](https://excalidraw.com) MCP server inside an ACA sandbox so AI agents (Claude Code, GitHub Copilot, ChatGPT, etc.) can create and edit Excalidraw diagrams as a tool.

## Status

**v0.8.0 placeholder.** Template assets (Dockerfile, source, deploy script) will land in v0.9. Until then, follow the manual recipe below.

## Manual recipe

| Step | Command / detail |
|------|------------------|
| Disk | `copilot` (Node 24 pre-installed) or `ubuntu` + `npm install -g n && n 24` |
| Create sandbox | `aca sandbox create --group <yourgroup> --disk copilot --label name=excalidraw-mcp` |
| Port | `aca sandbox port add -l name=excalidraw-mcp --port 80 --anonymous` |
| Source | Clone an Excalidraw MCP server repo into the sandbox via `aca sandbox exec` |
| Build + start | `npm install && PORT=80 nohup node server.js > /tmp/srv.log 2>&1 &` |
| Verify | `curl https://<sandbox-id>--80.proxy.azuredevcompute.io/health` |

After verification, snapshot the sandbox:

```bash
aca sandbox snapshot create -l name=excalidraw-mcp --name post-install
```

## Related references

- [`../../references/quickstart.md`](../../references/quickstart.md)
- [`../../references/deploy-patterns.md`](../../references/deploy-patterns.md)
- [`../../references/troubleshooting.md`](../../references/troubleshooting.md) (silent npm failures, server-health timing)

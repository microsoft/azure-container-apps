# Deploy patterns

Generic patterns for getting code running inside an ACA Sandbox using only the public `aca` CLI surface. All commands are verified against `aca <verb> --help` in 1.0.0-beta.1.

## Pattern: write files, install, run

```bash
SB="-l name=my-sb"

# 1. (Optional) make a target directory
aca sandbox exec $SB -c "mkdir -p /home/user/app"

# 2. Upload local files into the sandbox
aca sandbox fs write $SB --file ./index.js     --path /home/user/app/index.js
aca sandbox fs write $SB --file ./package.json --path /home/user/app/package.json

# 3. Install deps and start the server (Node example)
aca sandbox exec $SB -c "cd /home/user/app && npm install"
aca sandbox exec $SB -c "cd /home/user/app && PORT=80 nohup node index.js > /tmp/server.log 2>&1 &"

# 4. Expose the port
aca sandbox port add $SB --port 80 --anonymous   # public
# or: aca sandbox port add $SB --port 80 --email "$(az ad signed-in-user show --query mail -o tsv)"

# 5. Health check (give the server 5–10s to bind)
sleep 8
aca sandbox exec $SB -c "curl -s http://localhost/health || true"
```

## Pattern: clone a repo inside the sandbox

```bash
aca sandbox exec $SB -c "git clone https://github.com/<org>/<repo>.git /home/user/app"
aca sandbox exec $SB -c "cd /home/user/app && <build-command>"
```

## Pattern: snapshot after a successful deploy

Once the app is running and verified, always offer the user a snapshot — it's the fastest way to restore a known-good state:

```bash
aca sandbox snapshot $SB --name post-install
# Restore later via: aca sandbox create --snapshot post-install --label name=my-sb-restored
```

If you want a reusable disk image instead of a point-in-time snapshot, use `commit`:

```bash
aca sandbox commit $SB --name my-app-disk-v1
# Use later via: aca sandbox create --disk my-app-disk-v1 --label name=fresh-sb
```

## Personal Agent / multi-connector scenario

> **TODO (post-v0.8.0):** an end-to-end "Personal Agent" template (chat UI + Office 365 + M365 Copilot + GitHub Copilot + ACA Sandbox Management connectors, multi-agent routing, in-sandbox MCP config) is **not yet documented in the public [`microsoft/azure-container-apps`](https://github.com/microsoft/azure-container-apps/tree/main/docs/early) docs**.
>
> Tracked as a v0.9 follow-up in PR #1725. For now, use the generic deploy pattern above and the public `port add` / `egress` / `snapshot` primitives.

See [troubleshooting.md](troubleshooting.md) for deploy-time gotchas.

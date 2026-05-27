# Deploy patterns

## Personal Agent — onboarding guide

End-to-end onboarding for the Personal Agent template with all 4 connectors.

### Setup order (critical — do this exactly)

1. **Create connections in the portal** (one-time):
   - GitHub Copilot → OAuth consent
   - Office 365 → OAuth consent (personal connector)
   - M365 Copilot → OAuth consent (personal connector)
   - ACA Sandbox Management → auto-provisioned API key

2. **Create the sandbox** with the `copilot` disk:
   ```bash
   aca sandbox create --group mygroup --disk copilot --label name=personal-agent --no-suspend
   ```
   Or via YAML:
   ```yaml
   disk: copilot
   resources: { cpu: 2000m, memory: 4096Mi }
   lifecycle: { autoSuspendPolicy: { enabled: false } }
   ```

3. **Add port 80 with Entra ID auth — BEFORE attaching personal connectors:**
   ```bash
   EMAIL=$(az ad signed-in-user show --query mail -o tsv)
   aca sandbox port add -l name=personal-agent --port 80 --email "$EMAIL"
   ```
   Skipping this step makes attaching Office 365 / M365 Copilot fail with `500 Cannot add personal connector because port does not have Entra ID authentication`.

4. **Attach connections** to the sandbox in the portal (GitHub Copilot first, then the rest).

5. **Verify MCP config:** the in-sandbox Node Agent writes `/root/.copilot/mcp-config.json` when connections are attached. If missing, restart the sandbox to trigger regeneration.
   ```bash
   aca sandbox exec -l name=personal-agent -c "cat /root/.copilot/mcp-config.json || echo MISSING"
   ```

6. **Deploy the Personal Agent template** — upload files, install Node 24 + deps, start the server. See [deploy path](#deploy-path-cli-walkthrough) below.

## Multi-agent routing

Users can prefix messages with `@agent_name` to route to specialized agents:

| Prefix | Agent | Focus |
|--------|-------|-------|
| `@email` | Email Agent | Reading, drafting, sending, searching emails |
| `@research` | Research Agent | M365 Copilot queries, document search, SharePoint |
| (none) | General Agent | Everything — auto-detects intent |

## Deploy path (CLI walkthrough)

```bash
SB="-l name=personal-agent"

# 1. Make directories
aca sandbox exec $SB -c "mkdir -p /home/user/personal-agent/public"

# 2. Upload files
aca sandbox fs put $SB --src ./index.js        --dest /home/user/personal-agent/index.js
aca sandbox fs put $SB --src ./package.json    --dest /home/user/personal-agent/package.json
aca sandbox fs put $SB --src ./public/index.html --dest /home/user/personal-agent/public/index.html

# 3. Install Node 24 + deps (copilot disk already has Node 24; ubuntu does not)
aca sandbox exec $SB -c "npm install -g n && n 24"
aca sandbox exec $SB -c "cd /home/user/personal-agent && npm config set strict-ssl false && npm install"

# 4. Verify install succeeded (silent failures happen on egress timeouts)
aca sandbox exec $SB -c "ls /home/user/personal-agent/node_modules/ | wc -l"  # expect > 10

# 5. Start the server
aca sandbox exec $SB -c "cd /home/user/personal-agent && PORT=80 nohup node index.js > /tmp/server.log 2>&1 &"

# 6. Health check (give it 5–10s to bind)
sleep 8
aca sandbox exec $SB -c "curl -s http://localhost/health"
```

See [troubleshooting.md](troubleshooting.md) for deployment gotchas (silent npm failures, `aca sandbox exec` timing, etc.).

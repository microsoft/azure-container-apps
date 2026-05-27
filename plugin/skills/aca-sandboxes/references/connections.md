# Connections, MCP, and Entra email

## Entra email vs alias

| Command | Returns | Use for |
|---------|---------|---------|
| `az account show --query user.name` | alias (e.g., `you@microsoft.com`) | ❌ Do NOT use for port auth |
| `az ad signed-in-user show --query mail -o tsv` | Entra email (the `mail` attribute) | ✅ Use this for port auth |
| `az ad signed-in-user show --query userPrincipalName -o tsv` | UPN (often same as alias) | ❌ Same as alias |

The port Entra ID auth email **must match** the `mail` attribute in the user's Entra directory. For some accounts all three commands return the same value — when they differ, only `mail` works.

```bash
EMAIL=$(az ad signed-in-user show --query mail -o tsv)
aca sandbox port add -l name=my-sb --port 80 --email "$EMAIL"
```

## Port management limitations with personal connectors

When personal connectors (Office 365, M365 Copilot) are attached to a sandbox:

- Port management must use `aca sandbox port` or the Portal — both flow through interactive Entra login and produce tokens with the `email` JWT claim, which the personal-connector port flow requires.

## MCP server discovery

Connectors are exposed inside the sandbox as MCP servers:

- **Instance Network Proxy:** `http://100.64.100.1/mcp` — all connector tools via a single endpoint
- **Identity Proxy:** `http://100.64.100.2/msi/token` — managed identity tokens
- **ACA Sandbox Management MCP:** `https://management.azuredevcompute.io/mcp` — sandbox management tools

The Personal Agent auto-reads `/root/.copilot/mcp-config.json` at startup to discover all servers. No manual MCP config needed.

If the config is missing after attaching connections, restart the sandbox to trigger regeneration by the in-sandbox Node Agent.

## Available MCP tools (discovered at runtime)

| Connector | Tools | Notes |
|-----------|-------|-------|
| **Office 365** | `send_mail`, `get_emails`, `get_email`, `reply_to_email`, `list_calendars`, `get_events`, `get_event` | Personal connector — uses your email identity |
| **M365 Copilot** | `create_copilot_conversation`, `chat_copilot_conversation` | Slow (10–30s per call). Use 5-min timeout. Personal connector. |
| **ACA Sandbox Management** | `list_disk_images`, `create_disk_image`, `get_disk_image`, `create_sandbox`, `delete_sandbox`, `execute_command`, `list_ports`, `add_port`, `remove_port`, `deploy_app`, `create_content_package`, `create_static_site` | Sandbox management from within the agent |
| **Built-in MCP** | `microsoft-learn`, `deepwiki` | General knowledge tools |

## Your sandbox is locked to YOU

Sandboxes with personal connectors have Entra ID port auth locked to **your email only**. Only you can access the sandbox URL in a browser; your emails, calendar, and documents are never exposed to anyone else. The MCP tools (Office 365, M365 Copilot) operate under your identity.

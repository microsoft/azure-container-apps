# Connections and Entra email

## Entra email vs alias

When adding a port locked to a specific user with `aca sandbox port add --email <email>`, the value **must** be that user's Entra `mail` attribute. For some tenants this differs from the alias / UPN — in that case only `mail` works; an alias will fail.

| Command | Returns | Use for port auth? |
|---------|---------|--------------------|
| `az account show --query user.name` | alias (e.g. `you@microsoft.com`) | ❌ No |
| `az ad signed-in-user show --query mail -o tsv` | Entra `mail` attribute | ✅ Yes |
| `az ad signed-in-user show --query userPrincipalName -o tsv` | UPN (often same as alias) | ❌ No |

```bash
EMAIL=$(az ad signed-in-user show --query mail -o tsv)
aca sandbox port add -l name=my-sb --port 80 --email "$EMAIL"
```

If `port add` returns 409/500 with an alias but succeeds with the `mail` value, that's the gotcha.

## MCP servers and connector discovery

> **TODO (post-v0.8.0):** how an MCP server hosted inside a sandbox is discovered by an agent — and how external connectors (e.g. Office 365, M365 Copilot, GitHub Copilot) attach to a sandbox — is **not yet documented in the public [`microsoft/azure-container-apps`](https://github.com/microsoft/azure-container-apps/tree/main/docs/early) docs**.
>
> For now: expose the MCP server's port with `aca sandbox port add` and reach it from the public proxy URL `https://<sandbox-id>--<port>.proxy.azuredevcompute.io`. Update this section once the public docs ship discovery and connector guidance.

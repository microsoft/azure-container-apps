# SSH and shell access

ACA Sandboxes do **not** support traditional SSH (port 22), `ssh -i` with private keys, VS Code Remote SSH, or any SSH hostname/keypair. They use a WebSocket-based shell over the management API, authenticated via your `az login` token.

When users ask to SSH into a sandbox, present these options in order:

## 1. `aca sandbox shell` (easiest)

```bash
aca sandbox shell -l name=my-sb
```

Interactive WebSocket shell, authenticated via your `az login` token. No keys to manage.

## 2. Portal terminal

Open the sandbox in the [ACA portal](https://containerapps.azure.com/sandbox-groups) → click **Terminal**. Browser-based shell, no install needed.

## 3. Node.js helper (offline / agent fan-out)

Copy [`../assets/ssh.mjs`](../assets/ssh.mjs) to a working directory, then:

```bash
npm install ws
node ssh.mjs <sandbox-id>
```

Requires `az login` and Node 18+. Useful when you want a programmatic shell from a Node script — for example, agent fan-out across many sandboxes.

# CLI quick start

Goal: log in, create a sandbox group, grant yourself access, create a
sandbox, run a command, and clean up — all via the `aca` CLI.

> Assumes `aca` is installed (see [install.md](install.md)) and the
> Azure CLI is on your `PATH`. Full prereqs: [prerequisites.md](prerequisites.md).

```bash
# 0. Log in to Azure
az login

# 1. Create a resource group (skip if you have one)
az group create --name my-rg --location eastus2

# 2. Create a sandbox group (saves config automatically with --set-config)
aca sandboxgroup create --name my-sandbox-group --location eastus2 --set-config

# 3. Grant yourself data-plane access
aca sandboxgroup role create \
  --role "Container Apps SandboxGroup Data Owner" \
  --principal-id $(az ad signed-in-user show --query id -o tsv)

# 4. Verify setup
aca doctor

# 5. Create a sandbox (capture the ID for reuse)
SANDBOX_ID=$(aca sandbox create --disk ubuntu -o json | jq -r .id)

# 6. Run a command
aca sandbox exec --id "$SANDBOX_ID" -c "echo hello world && uname -a"

# 7. Clean up (snapshot first if there's state you want to keep)
aca sandbox delete --id "$SANDBOX_ID" --yes
```

`aca doctor` should print eight green checks:

```
✓ Azure CLI found
✓ Azure CLI logged in
✓ Subscription: a59d7183-… (config)
✓ Resource group: my-rg (config)
✓ Sandbox group: my-sandbox-group (config: sandbox)
✓ Region: eastus2 (config: sandbox)
✓ Sandbox group 'my-sandbox-group' exists in Azure
✓ Container Apps SandboxGroup Data Owner role assigned

aca 1.0.0-beta.1 — all checks passed
```

Defaults applied when flags are omitted:

| Flag | Default |
|---|---|
| `--cpu`    | `1000m` (1 vCPU) |
| `--memory` | `2048Mi` (2 GiB) |
| auto-suspend | 300s (5 min idle → suspend) |

Label + selector shortcut (target sandboxes without remembering IDs):

```bash
aca sandbox create --disk ubuntu --label name=dev
aca sandbox exec -l "name=dev" -c "echo hello"
```

Tear down the whole group later:

```bash
aca sandboxgroup delete --name my-sandbox-group --yes
```

## Common follow-up tasks

Once a sandbox is running, these are the most-used data-plane verbs.

### Open an interactive shell

```bash
aca sandbox shell --id "$SANDBOX_ID"
```

`exec` runs one command and returns; `shell` gives you a real PTY. There
is no SSH daemon — these two are the only paths into the sandbox.

### Copy a file in and out

```bash
aca sandbox fs write --id "$SANDBOX_ID" --path /tmp/data.csv --file ./data.csv
aca sandbox fs cat   --id "$SANDBOX_ID" --path /tmp/out.json > ./out.json
```

`fs` also has `ls`, `stat`, `mkdir`, `rm [--recursive]`.

### Expose a port publicly (preview)

```bash
URL=$(aca sandbox port add --id "$SANDBOX_ID" --port 8080 --anonymous -o json | jq -r .url)
curl "$URL"

# When done:
aca sandbox port remove --id "$SANDBOX_ID" --port 8080
```

`--anonymous` makes the URL reachable by anyone who has it (public
preview). For per-user gating, swap to `--email <entra-mail>`.

### Mount a shared volume

```bash
# Once, at the group:
aca sandboxgroup volume create --name shared --type AzureBlob

# Each sandbox that needs it:
aca sandbox mount --id "$SANDBOX_ID" --volume shared --path /mnt/shared
```

`AzureBlob` is multi-attach (shared across sandboxes); `DataDisk` is
single-attach high-perf block storage.

### Suspend and resume to save cost

```bash
aca sandbox stop   --id "$SANDBOX_ID"   # preserves memory + disk
aca sandbox resume --id "$SANDBOX_ID"   # sub-second restore

# Or set an idle policy (default 300s):
aca sandbox lifecycle set --id "$SANDBOX_ID" --auto-suspend 60
```

Suspended sandboxes incur storage cost only — no compute.

### Snapshot before destructive changes

```bash
aca sandbox snapshot --id "$SANDBOX_ID" --name pre-experiment
# ... do risky thing ...
# If it goes wrong, boot a clean replica from the snapshot:
aca sandbox create --snapshot pre-experiment
```

## What next

- [reference.md](reference.md) — full `aca` CLI reference (auth, config, YAML, selectors, output, verbose).
- [scenarios.md](scenarios.md) — patterns: web apps, coding agents, swarms, MCP hosting.
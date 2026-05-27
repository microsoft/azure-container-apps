# Scenarios — when sandboxes shine

Composed patterns that combine multiple sandbox capabilities. Each
entry has a "when to use" and a minimal command sketch.

---

## 1. Web apps

**When:** you have a web server and want a public URL in under a minute
without provisioning ingress, certs, or a load balancer.

**Sketch:**

```bash
SBX=$(aca sandbox create --disk ubuntu -o json | jq -r .id)

# Upload + start
aca sandbox fs write --id $SBX --path /app/server.py --file ./server.py
aca sandbox exec --id $SBX -c "nohup python3 /app/server.py > /tmp/srv.log 2>&1 &"

# Expose
URL=$(aca sandbox port add --id $SBX --port 8080 --anonymous -o json | jq -r .url)
echo "$URL"
```

Variants:

- **simple-anonymous** — open to the internet (above).
- **authenticated** — Entra-gated port (omit `--anonymous`).

---

## 2. Coding agents in a sandbox

**When:** you want to run Copilot CLI, Claude Code, Codex, or any other
coding agent in an isolated VM with deny-default egress, so the agent
can only reach the endpoints you allow.

**Sketch:**

```bash
# Per-task sandbox with deny-default egress + allow-list
SBX=$(aca sandbox create --disk ubuntu --label task=copilot-run -o json | jq -r .id)
aca sandbox egress set --id $SBX \
  --default Deny \
  --host-allow "api.githubcopilot.com" \
  --host-allow "*.githubusercontent.com"

aca sandbox exec --id $SBX -c "curl -fsSL https://github.com/cli/cli/releases/.../gh.tar.gz | tar -xz && ./gh ..."
```

Token-swap (inject the agent's auth header on egress, so the token
never lands in the sandbox filesystem) — via the YAML policy:

```bash
aca sandbox egress init > egress-policy.yaml
# edit egress-policy.yaml: add a rule with host: api.githubcopilot.com
# and a header transform Authorization=Bearer <TOKEN>
aca sandbox egress apply --id $SBX --file egress-policy.yaml
```

---

## 3. Code interpreter

**When:** an LLM generates code in a loop — generate, run, observe,
iterate — and you need a fresh isolated environment per session.

**Sketch:**

```bash
SBX=$(aca sandbox create --disk ubuntu --label kind=interpreter -o json | jq -r .id)

# Loop:
#   1. LLM emits code
#   2. write -> exec -> capture stdout/stderr
#   3. feed back into prompt
aca sandbox fs write --id $SBX --path /tmp/step.py --file ./step.py
aca sandbox exec --id $SBX -c "python3 /tmp/step.py" -o json
```

Snapshot between turns so you can rewind:

```bash
aca sandbox snapshot --id $SBX --name turn-3
```

---

## 4. Swarms

**When:** one orchestrator wants to fan work out across N worker
sandboxes (rendering, scraping, eval, batch inference).

**Sketch:**

```bash
# Orchestrator sandbox spawns workers in the same group via the
# group's managed identity (no secrets needed inside the sandbox).
BATCH_ID="batch-$(date +%s)"
for i in $(seq 1 10); do
  aca sandbox create --disk ubuntu \
    --label role=worker --label batch=$BATCH_ID \
    --no-wait
done

# Fan-out work by selector
aca sandbox list -l "role=worker,batch=$BATCH_ID" -o json \
  | jq -r '.[].id' \
  | xargs -I{} -P 10 aca sandbox exec --id {} -c "./run-shard.sh"

# Clean up — selector delete only matches one sandbox; iterate.
aca sandbox list -l "role=worker,batch=$BATCH_ID" -o json \
  | jq -r '.[].id' \
  | xargs -I{} aca sandbox delete --id {} --yes
```

Add a shared AzureBlob volume to the group for durable scratch space
across workers (`aca sandboxgroup volume …`).

---

## 5. Computer-use

**When:** an LLM with computer-use capability drives a real browser
inside a sandbox (form filling, web research, end-to-end tests). Watch
live via noVNC.

**Sketch:**

```bash
SBX=$(aca sandbox create --disk ubuntu --cpu 2000m --memory 4096Mi -o json | jq -r .id)
aca sandbox exec --id $SBX -c "apt-get install -y chromium x11vnc novnc && start-desktop.sh"

# Expose noVNC for the human to watch
aca sandbox port add --id $SBX --port 6080 --anonymous
```

The LLM (Azure OpenAI `computer-use-preview` or similar) drives the
browser via screenshot + click/keys actions sent through `sandbox exec`.

---

## 6. MCP hosting

**When:** you want to host a Model Context Protocol (MCP) server in a
sandbox for AI clients to connect to over HTTPS.

**Sketch (public via `port add`):**

```bash
SBX=$(aca sandbox create --disk ubuntu -o json | jq -r .id)
aca sandbox exec --id $SBX -c "npx -y @excalidraw/mcp-server &"
aca sandbox port add --id $SBX --port 3000 --anonymous
```

**Sketch (no inbound port — Dev Tunnels from inside the sandbox):**

```bash
SBX=$(aca sandbox create --disk ubuntu -o json | jq -r .id)
aca sandbox exec --id $SBX -c "npx -y @excalidraw/mcp-server &"
aca sandbox exec --id $SBX -c "devtunnel host -p 3000 --allow-anonymous"
# Tunnel URL is printed by devtunnel; share it with the MCP client.
```

---

## 7. Data processing

**When:** producer/consumer pipelines that need shared scratch space
across short-lived sandboxes.

**Sketch:**

```bash
# Create a group-level shared volume (default type: AzureBlob)
aca sandboxgroup volume create --name shared --type AzureBlob

# Create the sandboxes, then mount the volume into each
SBX_P=$(aca sandbox create --disk ubuntu --label role=producer -o json | jq -r .id)
aca sandbox mount --id $SBX_P --volume shared --path /data

SBX_C=$(aca sandbox create --disk ubuntu --label role=consumer -o json | jq -r .id)
aca sandbox mount --id $SBX_C --volume shared --path /data
```

Producers write to `/data/inbox/`, consumers drain it. Sandboxes
suspend when idle and pay nothing.

---

## 8. Developer workflows

**When:** PR builds, ephemeral CI, on-demand dev environments. A fresh
sandbox per PR or per developer, deleted on close.

**Sketch:**

```bash
SBX=$(aca sandbox create --disk ubuntu \
  --label pr=$PR_NUMBER --label kind=ci -o json | jq -r .id)
aca sandbox fs write --id $SBX --path /repo.tar.gz --file ./repo.tar.gz
aca sandbox exec --id $SBX -c "cd /tmp && tar xzf /repo.tar.gz && make test"
aca sandbox delete --id $SBX --yes
```

---

## 9. Sandbox-backed agent frameworks

**When:** you're using an agent framework (OpenAI Agents SDK, Claude
Managed Agents, LangChain) and want sandboxes to be the tool-execution
backend instead of the local machine.

**Sketch:** the framework's "tool" implementation calls
`aca sandbox exec --id $SBX -c "<tool-cmd>"` (or the equivalent API)
and returns the stdout/stderr to the agent. Each conversation gets its
own sandbox, snapshotted between turns for rewind.

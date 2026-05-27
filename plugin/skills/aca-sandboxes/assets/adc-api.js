/**
 * ADC API Helper — Direct API access to Azure Dev Compute.
 * Uses Azure CLI bearer tokens for auth (az account get-access-token).
 *
 * Authentication:
 *   Requires Azure CLI (`az`) installed and `az login` completed.
 *   Tokens are obtained on each request via `az account get-access-token`.
 *   az CLI handles token caching and refresh internally.
 *
 * SECURITY:
 *   - Bearer tokens are short-lived Entra ID tokens — no secrets to manage
 *   - Tokens are NEVER logged, printed, or included in error messages
 *   - All requests use HTTPS
 *   - File contents are sent as binary body, not URL params
 */

import { execSync } from "child_process";

const API_BASE = "https://management.azuredevcompute.io";
// OpenAPI spec: https://management.azuredevcompute.io/openapi/v1.json
const ADC_SCOPE = "https://management.azuredevcompute.io/AzureDevCompute.Management.ReadWrite.All";

/**
 * Check if Azure CLI is installed. Throws with install instructions if not.
 */
function checkAzInstalled() {
  try {
    execSync("az --version", { stdio: "ignore" });
    return true;
  } catch {
    throw new Error(
      "Azure CLI (az) is not installed. Install it:\n" +
      "  Windows: winget install -e --id Microsoft.AzureCLI\n" +
      "  macOS:   brew install azure-cli\n" +
      "  Linux:   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash\n" +
      "  Docs:    https://learn.microsoft.com/cli/azure/install-azure-cli"
    );
  }
}

/**
 * Check if Node.js is installed and meets the minimum version (>=18).
 * Throws with install instructions if not found or version too low.
 */
function checkNodeInstalled() {
  try {
    const ver = execSync("node --version", { encoding: "utf8", stdio: ["pipe", "pipe", "ignore"] }).trim();
    const major = parseInt(ver.replace("v", "").split(".")[0], 10);
    if (major < 18) {
      throw new Error(
        `Node.js ${ver} found but >=18 is required. Upgrade:\n` +
        "  https://nodejs.org/en/download\n" +
        "  Or use nvm: nvm install 18"
      );
    }
    return true;
  } catch (e) {
    if (e.message && e.message.includes("found but")) throw e;
    throw new Error(
      "Node.js is not installed. Install it:\n" +
      "  https://nodejs.org/en/download\n" +
      "  Windows: winget install -e --id OpenJS.NodeJS.LTS\n" +
      "  macOS:   brew install node@18\n" +
      "  Linux:   curl -fsSL https://deb.nodesource.com/setup_18.x | sudo bash - && sudo apt-get install -y nodejs"
    );
  }
}

/**
 * Get a bearer token via Azure CLI. az handles caching/refresh internally.
 */
function getAccessToken() {
  checkAzInstalled();
  try {
    return execSync(
      `az account get-access-token --scope "${ADC_SCOPE}" --query accessToken -o tsv`,
      { encoding: "utf8", stdio: ["pipe", "pipe", "ignore"] }
    ).trim();
  } catch {
    throw new Error(
      "Failed to get access token. Run 'az login' first to authenticate."
    );
  }
}

export class AdcApi {
  constructor() {
    checkAzInstalled();
    checkNodeInstalled();
  }

  // --- Internal ---

  async _req(method, path, body, extraHeaders) {
    const url = API_BASE + path;
    if (!url.startsWith(API_BASE)) throw new Error("Refusing to send token to non-ADC host");
    const headers = { "Authorization": "Bearer " + getAccessToken(), ...extraHeaders };
    if (body && typeof body === "object" && !(body instanceof ArrayBuffer) && !(body instanceof Uint8Array)) {
      headers["Content-Type"] = "application/json";
      body = JSON.stringify(body);
    }
    const resp = await fetch(url, { method, headers, body: method === "GET" || method === "DELETE" ? undefined : body });
    if (!resp.ok) {
      const text = await resp.text().catch(() => "");
      throw new Error(`ADC API ${method} ${path}: ${resp.status} ${text.slice(0, 200)}`);
    }
    const ct = resp.headers.get("content-type") || "";
    if (ct.includes("json")) return resp.json();
    if (resp.status === 204) return null;
    return resp.text();
  }

  // --- Sandboxes ---

  async createSandbox({ diskName, diskId, connections, preset, cpu, memory, ports, lifecycle, labels, env, vmmType } = {}) {
    const body = {
      vmmType: vmmType || "cloudhypervisor",
    };
    // Presets provide their own disk + resources; don't set them
    if (preset) {
      body.presetSandboxType = preset;
    } else {
      body.sourcesRef = diskId
        ? { diskImage: { id: diskId } }
        : { diskImage: { name: diskName || "ubuntu", isPublic: true } };
      body.resources = { cpu: cpu || "1000m", memory: memory || "2048Mi" };
    }
    if (connections) body.connections = connections;
    // SECURITY: ports are authenticated by default (Portal auth).
    // Anonymous access only when user explicitly opts in via auth: { anonymous: true }.
    if (ports) body.ports = ports.map(p => {
      if (typeof p === "number") return { port: p };
      const entry = { port: p.port, name: p.name };
      if (p.anonymous === true) entry.auth = { anonymous: true };
      return entry;
    });
    // Default lifecycle: 1 hour idle timeout (platform default is 5 min which is too short for dev)
    body.lifecycle = lifecycle || {
      autoSuspendPolicy: { enabled: true, interval: 3600, mode: "Memory" }
    };
    if (labels) body.labels = labels;
    if (env) body.environment = env;
    return this._req("PUT", "/sandboxes", body);
  }

  listSandboxes() { return this._req("GET", "/sandboxes"); }
  getSandbox(id) { return this._req("GET", `/sandboxes/${id}`); }
  deleteSandbox(id) { return this._req("DELETE", `/sandboxes/${id}`); }
  stopSandbox(id) { return this._req("POST", `/sandboxes/${id}/stop`); }
  resumeSandbox(id) { return this._req("POST", `/sandboxes/${id}/resume`); }

  // --- Connections ---

  listConnectionTypes() { return this._req("GET", "/connections/types"); }
  listConnections() { return this._req("GET", "/connections"); }
  createConnection(type, name) { return this._req("POST", "/connections", { type, name }); }
  deleteConnection(id) { return this._req("DELETE", `/connections/${encodeURIComponent(id)}`); }

  generateConsentLink(id, redirectUrl) {
    return this._req("POST", `/connections/${encodeURIComponent(id)}/generateConsentLink`,
      redirectUrl ? { redirectUrl } : {});
  }

  authorizeConnection(id, parameterValues) {
    return this._req("POST", `/connections/${encodeURIComponent(id)}/authorize`, { parameterValues });
  }

  refreshConnection(id) {
    return this._req("POST", `/connections/${encodeURIComponent(id)}/refresh`);
  }

  addConnectionToSandbox(sandboxId, connectionId) {
    return this._req("POST", `/sandboxes/${sandboxId}/connections/add`, { connectionId });
  }

  // --- Exec ---

  execCommand(sandboxId, command, args) {
    return this._req("POST", `/sandboxes/${sandboxId}/executeCommand`, { command, arguments: args || [] });
  }

  execShell(sandboxId, shellCommand) {
    return this._req("POST", `/sandboxes/${sandboxId}/executeShellCommand`, { command: shellCommand });
  }

  // --- Files ---

  async uploadFile(sandboxId, remotePath, content) {
    const data = typeof content === "string" ? new TextEncoder().encode(content) : content;
    try {
      return await this._req("PUT", `/sandboxes/${sandboxId}/files?path=${encodeURIComponent(remotePath)}`, data, {
        "Content-Type": "application/octet-stream",
      });
    } catch {
      // Fallback: write via shell command (workaround for file upload API issues)
      const text = typeof content === "string" ? content : new TextDecoder().decode(content);
      return this.execShell(sandboxId, `cat > ${remotePath} << 'ADCEOF'\n${text}\nADCEOF`);
    }
  }

  async downloadFile(sandboxId, remotePath) {
    const url = `${API_BASE}/sandboxes/${sandboxId}/files?path=${encodeURIComponent(remotePath)}`;
    const resp = await fetch(url, { headers: { "Authorization": "Bearer " + getAccessToken() } });
    if (!resp.ok) throw new Error(`Download failed: ${resp.status}`);
    return resp.arrayBuffer();
  }

  listFiles(sandboxId, path) {
    return this._req("GET", `/sandboxes/${sandboxId}/files/list?path=${encodeURIComponent(path)}`);
  }

  mkdir(sandboxId, path) {
    return this._req("POST", `/sandboxes/${sandboxId}/files/mkdir`, { path });
  }

  // --- Ports ---

  // Ports require Entra ID auth by default.
  // Pass { anonymous: true } for public access (e.g., MCP servers).
  // Email is required for Entra ID auth — the coding agent should ask the user for their Microsoft email.
  addPort(sandboxId, port, { name, anonymous, auth, email } = {}) {
    const body = { port };
    if (name) body.name = name;
    if (anonymous === true) {
      body.auth = { anonymous: true };
    } else if (auth) {
      body.auth = auth;
    } else {
      const userEmail = email || process.env.ADC_USER_EMAIL;
      if (!userEmail) {
        throw new Error("Email required for port auth. Pass { email } or set ADC_USER_EMAIL env var.");
      }
      body.auth = {
        entraId: { enabled: true, emails: [userEmail], emailSuffixes: [], objectIds: [], tenantIds: [] },
      };
    }
    return this._req("POST", `/sandboxes/${sandboxId}/ports/add`, body);
  }

  removePort(sandboxId, port) {
    return this._req("POST", `/sandboxes/${sandboxId}/ports/remove`, { port });
  }

  listPorts(sandboxId) {
    return this._req("GET", `/sandboxes/${sandboxId}/ports`);
  }

  // --- Egress ---

  setEgressPolicy(sandboxId, policy) {
    return this._req("POST", `/sandboxes/${sandboxId}/egresspolicy`, policy);
  }

  getEgressDecisions(sandboxId) {
    return this._req("GET", `/sandboxes/${sandboxId}/egress-decisions`);
  }

  // --- Disk Images ---

  createDiskImage(image, name, labels) {
    return this._req("PUT", "/diskimages", {
      image: { base: image },
      labels: { ...labels, ...(name ? { name } : {}) },
    });
  }

  listDiskImages() { return this._req("GET", "/diskimages"); }
  getDiskImage(id) { return this._req("GET", `/diskimages/${id}`); }
  deleteDiskImage(id) { return this._req("DELETE", `/diskimages/${id}`); }

  // --- Snapshots ---

  createSnapshot(sandboxId, labels) {
    return this._req("POST", `/sandboxes/${sandboxId}/snapshot`, { labels });
  }

  listSnapshots() { return this._req("GET", "/snapshots"); }
  getSnapshot(id) { return this._req("GET", `/snapshots/${id}`); }
  deleteSnapshot(id) { return this._req("DELETE", `/snapshots/${id}`); }

  // --- Stats ---

  getSandboxStats(sandboxId) { return this._req("GET", `/sandboxes/${sandboxId}/stats`); }

  // --- SSH / Interactive Shell ---

  /**
   * Open an interactive shell session in a sandbox via WebSocket.
   * Takes over stdin/stdout — use in a terminal context.
   * @param {string} sandboxId
   * @param {{ command?: string }} options
   * @returns {Promise<void>} resolves when session ends
   */
  async sshShell(sandboxId, { command = "/bin/bash" } = {}) {
    const WebSocket = (await import("ws")).default;
    const wsProtocol = API_BASE.startsWith("https://") ? "wss:" : "ws:";
    const baseUrl = new URL(API_BASE);
    const wsUrl = `${wsProtocol}//${baseUrl.host}/sandboxes/${sandboxId}/exec/stream`;

    return new Promise((resolve, reject) => {
      const ws = new WebSocket(wsUrl, {
        headers: { Authorization: `Bearer ${getAccessToken()}` },
      });

      const cols = process.stdout.columns || 80;
      const rows = process.stdout.rows || 24;

      ws.on("open", () => {
        ws.send(JSON.stringify({
          type: "start",
          start: {
            command,
            environment: { TERM: "xterm-256color", LANG: "C.UTF-8", LC_ALL: "C.UTF-8" },
            tty: true, stdin: true, height: rows, width: cols,
          },
        }));

        if (process.stdin.isTTY) process.stdin.setRawMode(true);
        process.stdin.resume();
        process.stdin.on("data", (data) => {
          if (data.length === 1 && data[0] === 0x04) { ws.close(); return; }
          ws.send(JSON.stringify({ type: "stdin", data: data.toString("base64") }));
        });
      });

      ws.on("message", (raw) => {
        try {
          const msg = JSON.parse(raw.toString());
          if (msg.type === "stdout" || msg.type === "stderr") {
            const output = Buffer.from(msg.data || "", "base64");
            (msg.type === "stdout" ? process.stdout : process.stderr).write(output);
          } else if (msg.type === "exit_code") { ws.close(); }
          else if (msg.type === "error") { console.error(`\nError: ${JSON.stringify(msg)}`); ws.close(); }
        } catch {}
      });

      ws.on("close", () => {
        if (process.stdin.isTTY) process.stdin.setRawMode(false);
        resolve();
      });

      ws.on("error", (err) => reject(err));
    });
  }
}

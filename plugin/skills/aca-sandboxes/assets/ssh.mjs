#!/usr/bin/env node
/**
 * ADC SSH — Interactive shell into an ADC sandbox via WebSocket.
 * No CLI dependency. Requires Node.js 18+ and the `ws` package.
 *
 * Usage:
 *   npx -y ws && node ssh.mjs <sandbox-id>
 *   # or if ws is already installed:
 *   node ssh.mjs <sandbox-id>
 *
 * Authentication:
 *   Requires Azure CLI (`az`) installed and `az login` completed.
 *   Bearer token is obtained automatically via `az account get-access-token`.
 *
 * Press Ctrl+D to exit.
 */

import { execSync } from "child_process";

const API_BASE = "management.azuredevcompute.io";
const ADC_SCOPE = "https://management.azuredevcompute.io/AzureDevCompute.Management.ReadWrite.All";

function checkAzInstalled() {
  try {
    execSync("az --version", { stdio: "ignore" });
    return true;
  } catch {
    console.error("Error: Azure CLI (az) is not installed. Install it:");
    console.error("  Windows: winget install -e --id Microsoft.AzureCLI");
    console.error("  macOS:   brew install azure-cli");
    console.error("  Linux:   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash");
    console.error("  Docs:    https://learn.microsoft.com/cli/azure/install-azure-cli");
    process.exit(1);
  }
}

function checkNodeInstalled() {
  try {
    const ver = execSync("node --version", { encoding: "utf8", stdio: ["pipe", "pipe", "ignore"] }).trim();
    const major = parseInt(ver.replace("v", "").split(".")[0], 10);
    if (major < 18) {
      console.error(`Error: Node.js ${ver} found but >=18 is required. Upgrade:`);
      console.error("  https://nodejs.org/en/download");
      console.error("  Or use nvm: nvm install 18");
      process.exit(1);
    }
    return true;
  } catch {
    console.error("Error: Node.js is not installed. Install it:");
    console.error("  https://nodejs.org/en/download");
    console.error("  Windows: winget install -e --id OpenJS.NodeJS.LTS");
    console.error("  macOS:   brew install node@18");
    console.error("  Linux:   curl -fsSL https://deb.nodesource.com/setup_18.x | sudo bash - && sudo apt-get install -y nodejs");
    process.exit(1);
  }
}

function getAccessToken() {
  try {
    return execSync(
      `az account get-access-token --scope "${ADC_SCOPE}" --query accessToken -o tsv`,
      { encoding: "utf8", stdio: ["pipe", "pipe", "ignore"] }
    ).trim();
  } catch {
    console.error("Error: Failed to get access token. Run 'az login' first to authenticate.");
    process.exit(1);
  }
}

const sandboxId = process.argv[2];
const command = process.argv[3] || "/bin/bash";

if (!sandboxId) {
  console.error("Usage: node ssh.mjs <sandbox-id> [command]");
  console.error("  Requires: Azure CLI (`az`) installed and `az login` completed");
  process.exit(1);
}

checkAzInstalled();
checkNodeInstalled();
const token = getAccessToken();

let WebSocket;
try {
  WebSocket = (await import("ws")).default;
} catch {
  console.error("Error: 'ws' package not found. Install it first:");
  console.error("  npm install ws");
  process.exit(1);
}

const wsUrl = `wss://${API_BASE}/sandboxes/${sandboxId}/exec/stream`;

console.log(`Connecting to sandbox ${sandboxId.substring(0, 12)}...`);
console.log("Press Ctrl+D to exit\n");

const ws = new WebSocket(wsUrl, {
  headers: { Authorization: `Bearer ${token}` },
});

const cols = process.stdout.columns || 80;
const rows = process.stdout.rows || 24;

ws.on("open", () => {
  ws.send(JSON.stringify({
    type: "start",
    start: {
      command,
      environment: { TERM: "xterm-256color", LANG: "C.UTF-8", LC_ALL: "C.UTF-8" },
      tty: true,
      stdin: true,
      height: rows,
      width: cols,
    },
  }));

  if (process.stdin.isTTY) {
    process.stdin.setRawMode(true);
  }
  process.stdin.resume();
  process.stdin.on("data", (data) => {
    if (data.length === 1 && data[0] === 0x04) {
      ws.close();
      return;
    }
    ws.send(JSON.stringify({ type: "stdin", data: data.toString("base64") }));
  });
});

ws.on("message", (raw) => {
  try {
    const msg = JSON.parse(raw.toString());
    if (msg.type === "stdout" || msg.type === "stderr") {
      const output = Buffer.from(msg.data || "", "base64");
      (msg.type === "stdout" ? process.stdout : process.stderr).write(output);
    } else if (msg.type === "exit_code") {
      ws.close();
    } else if (msg.type === "error") {
      console.error(`\nError: ${JSON.stringify(msg)}`);
      ws.close();
    }
  } catch {}
});

ws.on("close", () => {
  if (process.stdin.isTTY) process.stdin.setRawMode(false);
  console.log("\nDisconnected");
  process.exit(0);
});

ws.on("error", (err) => {
  console.error(`Connection error: ${err.message}`);
  process.exit(1);
});

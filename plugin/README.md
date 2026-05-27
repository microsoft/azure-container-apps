# Azure Container Apps — plugin

This directory is the plugin marketplace seed for [Azure Container Apps](https://github.com/microsoft/azure-container-apps). Today it ships **one skill**, with more planned:

| Skill | Purpose |
|---|---|
| [`aca-sandboxes`](./skills/aca-sandboxes/) | Drive [ACA Sandboxes](https://github.com/microsoft/azure-container-apps/blob/main/docs/early/sandboxes-overview.md) (hardware-isolated microVMs) from agents using the `aca` CLI. |

## Install

The marketplace manifest at the repo root ([`/.claude-plugin/marketplace.json`](../.claude-plugin/marketplace.json)) is consumed by both GitHub Copilot CLI and Claude Code.

**GitHub Copilot CLI:**

```bash
copilot plugin marketplace add microsoft/azure-container-apps
copilot plugin install azure-container-apps@azure-container-apps
```

**Claude Code:**

```bash
claude plugin marketplace add microsoft/azure-container-apps
claude plugin install azure-container-apps@azure-container-apps
```

After install, the skill activates automatically when an agent question matches its triggers (e.g., "create an ACA sandbox", "run command in a sandbox", "expose a port from my sandbox").

## What is this?

A plugin store seed for the ACA ecosystem. The intent is to grow it into the canonical location for first-party agent skills, MCP companions, and helper assets that target Container Apps.

If you're working on an adjacent surface (ACA deploy, ACA jobs, ACA networking, an MCP server, etc.), open an issue here proposing the addition.

## Versioning

| Component | Version |
|---|---|
| Plugin | 0.8.0 |
| Skills | each carries its own `version.json` |

## Layout

```
.claude-plugin/marketplace.json    ← marketplace manifest (repo root, consumed by Copilot CLI + Claude Code)
plugin/
├── .claude-plugin/plugin.json     ← Claude Code plugin manifest
├── .plugin/plugin.json            ← Copilot CLI plugin manifest
├── LICENSE                        ← MIT
├── README.md                      ← this file
└── skills/
    └── aca-sandboxes/             ← v0.8.0 — `aca` CLI-driven microVMs skill
```

Cursor, Gemini, MCP server config, and a brand-approved logo are planned for follow-up PRs.

## License

[MIT](./LICENSE) © Microsoft Corporation.

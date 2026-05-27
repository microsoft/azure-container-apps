# Prerequisites

| Requirement | Details |
|-------------|---------|
| **Azure CLI (`az`)** | Install from [learn.microsoft.com/cli/azure/install-azure-cli](https://learn.microsoft.com/cli/azure/install-azure-cli). On Windows, `aca` looks for `az.cmd`. |
| **`az login`** | Run once. `aca` delegates auth to Azure CLI; data-plane tokens are acquired automatically. |
| **`aca` CLI** | See [quickstart.md](quickstart.md). |
| **RBAC role** | `Container Apps SandboxGroup Data Owner` on the sandbox group (or higher). |
| **Microsoft Entra ID account** | Only Entra ID accounts can access sandboxes. Personal Microsoft accounts are not supported. |

## Supported platforms

macOS ARM64, Linux x64, Windows x64.

Not yet supported: macOS x64 (Intel), Linux ARM64.

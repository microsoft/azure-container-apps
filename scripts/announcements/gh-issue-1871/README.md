# Dapr component scope audit

Read-only helper for [issue #1871](https://github.com/microsoft/azure-container-apps/issues/1871).
Finds empty component scopes and scoped IDs with no matching app in the same environment.

Requires PowerShell 7, Azure CLI signed in with `az login`, and read access to the subscription.

Run from this directory:

```powershell
.\Get-DaprComponentInventory.ps1 -SubscriptionId "<subscription-id>"
```

Add `-EnvironmentId "<environment-resource-id>"` to check one environment.

Results go to `.\dapr-scope-audit-<subscription-id>-<timestamp>\`: `summary.json`
and non-empty CSV inventories/findings. Use `-OutputDirectory "<new-directory>"` to override.

**Limits:** Existing Dapr-disabled matches are not flagged. RBAC and deployment ordering
are not checked. An API read failure stops the audit without producing a complete report.

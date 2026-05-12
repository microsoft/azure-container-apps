# Egress policies and network controls for Azure Container Apps sandboxes (preview)

Azure Container Apps sandboxes execute arbitrary workloads, including AI-generated code, agent toolchains, and untrusted user input. Controlling what those workloads can reach on the network is a foundational security control. This article describes the egress policy model, how policies are evaluated, and how to apply them through the SDK.

> **Note:** Azure Container Apps sandboxes are currently in private preview. Contact your Microsoft representative for access.

## The egress policy model

An egress policy answers two questions for every outbound request a sandbox makes:

1. Should this request be allowed?

1. Should this request be transformed (for example, by injecting an authentication header or rewriting the destination)?

A policy has the following shape:

| Field | Description |
|---|---|
| **Default action** | `Allow` or `Deny`. Applied to any request that doesn't match a more specific rule. |
| **Host rules** | Pattern-matched rules keyed on hostname (for example, `*.github.com`). Each rule has its own `Allow` or `Deny` action. |
| **Rules** | Richer rules that match on host, path, and HTTP method, and support `Allow`, `Deny`, `Transform`, and `Rewrite` actions. |
| **Traffic inspection** | Controls how the egress proxy inspects traffic (`Legacy`, `Partial`, `Full`, or `None`). |

The recommended starting posture for any sandbox that runs untrusted code is `default_action = Deny` plus an explicit allow list of the destinations the workload genuinely needs.

## Where policies live

You can apply egress policies at two scopes:

- **At create time**: Set on the request that creates the sandbox, so the workload starts under the policy.

- **At runtime**: Update on a running sandbox via the SDK. The new policy takes effect for subsequent requests.

The SDK exposes both shapes:

### C#

```csharp
// Apply a policy to a running sandbox
await scope.Sandboxes.SetEgressPolicyAsync(sandbox.Id, new EgressPolicy
{
    DefaultAction = EgressAction.Deny,
    HostRules =
    [
        new EgressHostRule { Pattern = "*.github.com", Action = EgressAction.Allow },
        new EgressHostRule { Pattern = "github.com", Action = EgressAction.Allow }
    ]
});
```

### Python

```python
from adc.models.sandbox import (
    EgressPolicy,
    EgressPolicyAction,
    EgressHostRule,
)

await sandbox.set_egress_policy(EgressPolicy(
    default_action=EgressPolicyAction.DENY,
    host_rules=[
        EgressHostRule(pattern="*.github.com", action=EgressPolicyAction.ALLOW),
        EgressHostRule(pattern="github.com", action=EgressPolicyAction.ALLOW),
    ],
))
```

## Rule evaluation order

Egress decisions follow a predictable order:

1. **Rich rules** are evaluated first, in the order they appear in the `rules` list. The first rule whose `match` (host, path, method) matches the request wins. The action attached to that rule is applied.

1. **Host rules** are evaluated next when no rich rule matches. Host patterns support a leading wildcard (for example, `*.example.com`).

1. **Default action** is applied when no rule matches.

Order rich rules from most specific to most general. A `Deny` rule on `api.example.com/admin` placed before an `Allow` rule on `api.example.com` blocks the admin path while permitting the rest of the API.

## Rule actions

Rules support four action types:

| Action | Use case |
|---|---|
| **Allow** | Permit the request unchanged. |
| **Deny** | Block the request before it leaves the sandbox. |
| **Transform** | Permit the request and modify its headers (for example, inject an authentication token). |
| **Rewrite** | Permit the request and rewrite the destination scheme, host, or path. |

`Transform` and `Rewrite` together let you front a sandbox's outbound calls with policy that authenticates and routes them without the sandbox ever needing to hold the credentials directly.

## Header transforms and credential injection

For workloads that call authenticated upstream APIs, `Transform` actions can attach headers from one of three sources:

- **Static value**: A literal string baked into the rule.

- **Secret reference**: Pulled from the sandbox group's Secrets store. Use a format string like `Bearer {value}` to combine the secret with a constant prefix.

- **Managed identity reference**: A token acquired on demand from a managed identity for a specified resource URI.

The Python model exposes these through `EgressPolicyHeaderTransform`, `EgressPolicySecretRef`, and `EgressPolicyManagedIdentityRef`. The C# SDK exposes equivalent types under the `EgressPolicy` namespace.

This pattern is especially useful for AI agent scenarios where the agent needs to call an LLM API, but you don't want the agent code to handle the API key directly.

## Traffic inspection

The egress proxy supports several inspection modes:

| Mode | Behavior |
|---|---|
| **Legacy** | Default for backward compatibility. Legacy host-based filtering only. |
| **Partial** | Inspects request lines and headers; rich rules and transforms apply. |
| **Full** | Full inspection including body for the rules and transforms that need it. |
| **None** | Outbound traffic bypasses the egress proxy entirely. |

Choose `Partial` or `Full` to use rich rules. Set inspection to `None` (or use the per-sandbox `skip_egress_proxy` flag at creation time) only when latency matters more than control and you trust the destination.

## Observability

The platform records every egress decision the proxy makes so you can audit what the sandbox attempted and what was allowed or blocked.

### C#

```csharp
var decisions = await scope.Sandboxes.GetEgressDecisionsAsync(sandbox.Id);

Console.WriteLine($"Allowed: {decisions.NetworkEgress.Allowed.Count}");
Console.WriteLine($"Denied:  {decisions.NetworkEgress.Denied.Count}");
```

### Python

```python
decisions = await sandbox.get_egress_decisions()

allowed = [d for d in decisions if d.action == "Allow"]
denied = [d for d in decisions if d.action == "Deny"]

print(f"Allowed: {len(allowed)}")
print(f"Denied:  {len(denied)}")
```

Use the decisions log to validate that a new policy denies what you expect before you push it to production, and to audit attempted exfiltration in workloads you don't fully trust.

## Considerations

| Area | Detail |
|---|---|
| **Default-deny posture** | Workloads that execute untrusted code should default to `Deny` and add narrow allow rules for the destinations they need. |
| **Layered rules** | Use `rules` for path- or method-specific decisions and `host_rules` for whole-domain decisions. Keep host rules short; promote anything that needs path matching into a rich rule. |
| **Policy lifecycle** | Policies are mutable on running sandboxes. Updates apply to subsequent requests; in-flight requests aren't reevaluated. |
| **Per-environment policies** | Maintain separate policies for development, staging, and production. Devs can iterate against a permissive policy while production stays locked down. |
| **Audit cadence** | Pull egress decisions periodically from long-running sandboxes and review denied counts. A spike usually indicates a workload misconfiguration or an exfiltration attempt. |
| **Skip the proxy carefully** | `skip_egress_proxy` (or traffic inspection `None`) trades safety for latency. Only enable it for sandboxes that don't run untrusted code and only for trusted destinations. |

## Related content

- [Snapshots and state management for sandboxes](sandboxes-snapshots-state-management.md)
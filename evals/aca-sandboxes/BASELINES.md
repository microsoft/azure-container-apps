# Baseline runs

Per-run summaries. Raw JSON is gitignored (size). Full PR comments are linked.

## Run 1 — commit `8cc45a2` — 2026-05-26

| Stat | Value |
|---|---|
| Aggregate score | **0.50** |
| Pass rate | **18.5% (5 / 27)** |
| Failed | 22 |
| Grader errors | 0 |
| Duration | 13m 14s |
| Premium requests | 169 |
| Engine / model | `copilot-sdk` / `claude-sonnet-4.6` |
| Gate (≥0.70) | ❌ not met |

**Pass (5):** `neg-acr-build`, `neg-app-service-deploy`, `neg-deploy-function-app`, `compare-sandbox-vs-container-app`, `syn-microvm-vague`.

**Critical failures:** `compare-sandbox-vs-dynamic-session`, `pos-create-sandbox`, `pos-install-aca-{linux,macos,windows}`, `pos-yaml-apply`.

**Root causes:**
1. Skill not activating in eval session (10 of 11 positive failures).
2. Negative-test eval isolation artifact (5 of 7 negative failures) — bare model engages out-of-scope queries that would route elsewhere in production.
3. Dynamic Sessions disambiguation absent from body (0 of 3 disambiguation tasks).

Full diagnosis: see [PR #1725 comment](https://github.com/microsoft/azure-container-apps/pull/1725) and [`../docs/aca-sandboxes/eval-framework.md`](../../docs/aca-sandboxes/eval-framework.md) §5.1.

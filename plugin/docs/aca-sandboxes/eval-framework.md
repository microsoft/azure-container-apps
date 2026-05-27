# `aca-sandboxes` — Eval Framework

> Baseline + ground truth + human-eval process for the [`aca-sandboxes`](../../skills/aca-sandboxes/SKILL.md) skill.
> Modeled on [`coreai-microsoft/forge-builderskit/docs/azure-quickstart/eval-framework.md`](https://github.com/coreai-microsoft/forge-builderskit/tree/main/docs/azure-quickstart).

---

## 1. Suite

| File | Purpose |
|------|---------|
| [`plugin/evals/aca-sandboxes/eval.yaml`](../../evals/aca-sandboxes/eval.yaml) | 6 weighted metrics, copilot-sdk executor, claude-sonnet-4.6 model |
| [`plugin/evals/aca-sandboxes/tasks/*.yaml`](../../evals/aca-sandboxes/tasks/) | 27 task files (11 pos / 7 neg / 6 syn / 3 compare) |

**Standards compliance** (per [forge-builderskit `SKILL-STANDARDS.md` §1](https://github.com/coreai-microsoft/forge-builderskit/blob/main/docs/SKILL-STANDARDS.md)):

| Bar | Required | Actual |
|-----|----------|--------|
| Total tasks | ≥20 | **27** ✅ |
| Positive (`pos-*` + `compare-*` should-trigger) | ≥50% | **52%** ✅ |
| Negative (`neg-*`) | ≥20% | **26%** ✅ |
| Synthetic (`syn-*`) | ≥20% | **22%** ✅ |

---

## 2. Metrics and Thresholds

| Metric | Weight | Threshold | What it measures |
|--------|--------|-----------|------------------|
| `routing_accuracy` | 0.25 | 0.90 | Activates for ACA Sandboxes / microVM / sandbox-group queries; rejects Functions, AKS, ACR, Cosmos, App Service, **Dynamic Sessions** queries. |
| `cli_command_correctness` | 0.25 | 0.90 | `aca` 1.0.0-beta.1 verbs and flags are correct (`--location` not `--region`, `-l name=` selectors, `aca sandbox apply -f`, `aca sandboxgroup create --set-config`). |
| `install_path_selection` | 0.15 | 0.85 | Picks `aca` CLI primary; `adc-api.js` only when agent fan-out is needed; Python SDK marked "coming soon". |
| `portal_url_correctness` | 0.10 | 0.95 | Uses `https://containerapps.azure.com/sandbox-groups`; never `portal.agentdevcompute.io` or fabricated hosts. |
| `gotcha_handling` | 0.15 | 0.85 | Applies Entra-email gotcha, port-order warning, snapshot-before-destroy, auto-suspend awareness, Dynamic Sessions disambiguation. |
| `naming_policy` | 0.10 | 0.90 | "ACA Sandboxes" / "Azure Container Apps sandboxes" in customer text; "ADC" only as internal codename. |

Weights sum to 1.00.

---

## 3. Ground Truth Sources

When grading, the prompt grader can reference these authoritative sources:

| Source | Authority for |
|--------|---------------|
| [`microsoft/azure-container-apps/docs/early/sandboxes-overview.md`](https://github.com/microsoft/azure-container-apps/blob/main/docs/early/sandboxes-overview.md) | Product framing, **Dynamic Sessions comparison table (lines 163-177)**, terminology |
| [`microsoft/azure-container-apps/docs/early/aca-cli/`](https://github.com/microsoft/azure-container-apps/tree/main/docs/early/aca-cli) | `aca` 1.0.0-beta.1 CLI surface, verb names, flags |
| [`microsoft/azure-container-apps/docs/early/quickstarts/`](https://github.com/microsoft/azure-container-apps/tree/main/docs/early/quickstarts) | Step ordering for end-to-end sandbox creation |
| [`microsoft/azure-container-apps/docs/early/python-sdk/`](https://github.com/microsoft/azure-container-apps/tree/main/docs/early/python-sdk) | Python SDK status (currently "coming soon" — graders should NOT expect detailed Python steps) |
| Phase 0b live-verification log (in tracking issue) | 17-disk catalog including `copilot` + `claude` presets, `aca doctor` 8/8 baseline |

---

## 4. Running the Suite

### Prerequisites

1. Install `waza` (Copilot CLI plugin) — `copilot plugin install waza@agency-playground`.
2. Install this plugin (so the skill is discoverable):
   ```bash
   copilot plugin marketplace add microsoft/azure-container-apps
   copilot plugin install azure-container-apps@azure-container-apps
   ```
3. Set `OPENAI_API_KEY` or have Copilot SDK auth configured for the `copilot-sdk` executor.

### Local run

```bash
cd /path/to/azure-container-apps
waza eval plugin/evals/aca-sandboxes/eval.yaml
```

Outputs land in `results/aca-sandboxes-run-<timestamp>.md` (gitignored — local only).

### CI run

Not yet wired. Phase 10 follow-up will add a GitHub Action that runs the suite on every PR touching `plugin/skills/aca-sandboxes/` or `plugin/evals/aca-sandboxes/`.

---

## 5. Baseline (TBD)

**Status:** Not yet collected. First baseline will be run before marking PR #1725 ready-for-review (Phase 9).

**Pass gate for the PR:** ≥0.70 average across all 6 metrics. Below that = SKILL.md needs more work, not eval tuning.

**Critical task gates (any failure blocks PR):**

| Task | Why it's critical |
|------|-------------------|
| `compare-sandbox-vs-dynamic-session` | Highest-stakes naming/product disambiguation per Paul (5/26). |
| `neg-dynamic-session-query` | If skill activates here, we are conflating two distinct products. |
| `pos-install-aca-windows` | Windows must be a first-class platform — no "Windows unsupported, use WSL" fallback per Paul (5/26). |
| `pos-create-sandbox` | The Quick Start IS the skill. If this fails, the whole skill fails. |
| `pos-yaml-apply` | The YAML manifest pattern is the v0.8.0 anchor — it's the recommended path. |

Baseline + critical-task results will be appended here as `### 5.1 Baseline run-1 (YYYY-MM-DD)` after Phase 9 smoke test.

---

## 6. Human Eval Process (when prompt-grader output is borderline)

When `routing_accuracy < 0.85` or `cli_command_correctness < 0.85` in a run:

1. Open each failed task's transcript in `results/`.
2. For each, classify the failure:
   - **(a) Skill content gap** — SKILL.md doesn't say enough on this topic → fix SKILL.md, re-run.
   - **(b) Grader prompt unclear** — the grader prompt is ambiguous → tighten the task yaml.
   - **(c) Model variance** — same task passes on different trials → bump `trials_per_task` and use median grade.
3. Open a PR with the fix; mark this doc with `### 5.N Baseline run-N (date)` and the delta.

Two reviewers required for (a) fixes — one PM (Paul), one engineer familiar with the `aca` CLI surface.

---

## 7. Changelog

| Date | Version | Change |
|------|---------|--------|
| 2026-05-26 | 0.1 | Initial suite — 27 tasks, 6 metrics. Baseline TBD. |

# `aca-sandboxes` — Eval Framework

> Baseline + ground truth + human-eval process for the [`aca-sandboxes`](../../skills/aca-sandboxes/SKILL.md) skill.

---

## 1. Suite

The eval suite (eval.yaml + 27 task YAMLs) is **not checked into this repo** to keep the marketplace install slim — `copilot plugin marketplace add` clones the whole repo, so eval fixtures bloat every consumer install. Skill authors run the suite from their own checkout and publish results via PR comments on the change that motivated the run.

| Item | Where |
|------|-------|
| `eval.yaml` (6 weighted metrics, copilot-sdk executor, claude-sonnet-4.6 model) | Maintained off-repo by the skill author |
| 27 task files (11 pos / 7 neg / 6 syn / 3 compare) | Same — see published results for the catalog |
| Per-run baseline numbers + pass/fail breakdown | Posted as a PR comment on the changing PR |
| Methodology + ground truth + thresholds | This document |

**Standards compliance** (using the conventional skill-eval task-mix bar — ≥20 tasks, ≥50% positive, ≥20% negative, ≥20% synthetic):

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
| `install_path_selection` | 0.15 | 0.85 | Picks `aca` CLI primary; Python SDK marked "coming soon". |
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

The suite lives in the skill author's local working directory (not in this repo). Typical layout:

```bash
~/src/aca-sandboxes-evals/
├── eval.yaml
└── tasks/*.yaml
```

```bash
cd ~/src/aca-sandboxes-evals
waza run eval.yaml --parallel --output /tmp/aca-eval/results.json
```

Raw JSON results stay local — only summary numbers + pass/fail breakdown get published in PR comments.

### CI run

Not wired. Eval results are published manually via PR comments today. A future option is a private GitHub Action in a sibling repo that posts results to PRs touching `plugin/skills/aca-sandboxes/`.

---

## 5. Baseline

**Pass gate for the PR:** ≥0.70 aggregate score across all tasks. Below that = SKILL.md needs more work, not eval tuning.

**Critical task gates (any failure flagged but not blocking until Phase 9 reaches ready-for-review):**

| Task | Why it's critical |
|------|-------------------|
| `compare-sandbox-vs-dynamic-session` | Highest-stakes naming/product disambiguation. |
| `neg-dynamic-session-query` | If skill activates here, we are conflating two distinct products. |
| `pos-install-aca-windows` | Windows must be a first-class platform — no "Windows unsupported, use WSL" fallback. |
| `pos-create-sandbox` | The Quick Start IS the skill. If this fails, the whole skill fails. |
| `pos-yaml-apply` | The YAML manifest pattern is the v0.8.0 anchor — it's the recommended path. |

### 5.1 Baseline run-1 (2026-05-26, commit 8cc45a2)

First baseline against the slim layout (commit `8cc45a2` — evals moved out of repo, JS helpers dropped to keep install slim).

| Stat | Value |
|---|---|
| Aggregate score | **0.50** |
| Pass rate | **18.5% (5 / 27)** |
| Failed | 22 |
| Errors (grader transient) | 0 |
| Duration | 13m 14s |
| Gate (≥0.70) | ❌ not met |

**Pass:** `neg-acr-build`, `neg-app-service-deploy`, `neg-deploy-function-app`, `compare-sandbox-vs-container-app`, `syn-microvm-vague` (5).

**Critical failures:**

- `compare-sandbox-vs-dynamic-session` (CRITICAL) — failed. The most important disambiguation in the suite.
- `pos-create-sandbox` (CRITICAL) — failed. Bare model used `az login` / `az account show` instead of `aca` CLI.
- `pos-install-aca-{linux, macos, windows}` (CRITICAL for Windows) — all failed. Bare model suggested `brew install aca` or web-searched without finding the tool.
- `pos-yaml-apply` (CRITICAL) — failed. Bare model didn't scaffold a manifest, just asked "where is sandbox.yaml?"

**Root cause analysis:**

1. **Skill activation (10 of 11 positive failures).** Grader notes show bare-model behavior, not skill-augmented behavior. Either (a) the copilot-sdk eval session isn't loading SKILL.md, or (b) trigger phrases in the `USE FOR` block don't match the natural language of the prompts (e.g., "create a sandbox", "ssh into my sandbox"). Likely both.

2. **Negative-test eval-isolation artifact (5 of 7 negative failures).** Without other Copilot skills loaded (e.g., `azure-prepare`, `azure-cosmos`), the bare model engages deeply with out-of-scope queries (azd, Cosmos, K8s, Dynamic Sessions). In production with the wider skill set loaded, those queries route elsewhere. Eval isolation overstates the failure rate here.

3. **Dynamic Sessions disambiguation (0 of 3).** `DO NOT USE FOR` line in description isn't enough — needs body-level coverage.

**Per-metric breakdown:** waza's `.metrics` object returned `{}` (no per-metric weighted scoring). Eval.yaml `metrics:` section declares names + weights but graders are per-task (`behavior-<id>`), not per-metric. Waza apparently expects graders to tag the metric they're scoring. Investigating whether to (a) refactor graders to be metric-tagged, or (b) compute weighted aggregates externally from task pass/fail.

**Iteration plan:**

1. Tighten `USE FOR` triggers — add shorter natural phrases.
2. Verify skill loading via `--session-log` and inspect transcript.
3. Hoist Dynamic Sessions disambiguation into SKILL.md body (not just description).
4. Re-baseline. Target ≥0.70 before flipping draft → ready-for-review.

Structured results JSON: kept locally only (gitignored to avoid repo bloat). Per-run summaries: [`evals/aca-sandboxes/BASELINES.md`](../../evals/aca-sandboxes/BASELINES.md).

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

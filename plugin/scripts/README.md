# plugin/scripts

Maintenance scripts for the plugin's skills.

## `verify-aca-verbs.mjs`

Walks every `*.md` file under `plugin/skills/`, extracts every `aca <verb1> <verb2>`
invocation from shell code fences, and runs `aca <verb1> <verb2> --help` against
the real `aca` binary on `PATH`. Fails the run if any verb pair does not exist.

This catches **fabricated commands** before they ship — e.g. `aca sandbox-group
connector add` (not a real command; the group is `aca sandboxgroup` with no hyphen).

### Run it

```bash
# Requires Node 18+ and the aca CLI on PATH.
# Install: https://aka.ms/aca-cli-install (bash) or https://aka.ms/aca-cli-install-ps (Windows)
node plugin/scripts/verify-aca-verbs.mjs

# Or scope to a single skill:
node plugin/scripts/verify-aca-verbs.mjs plugin/skills/aca-sandboxes
```

### Exit codes

| Code | Meaning |
| ---- | ------- |
| 0    | Every verb pair resolves against the real `aca` binary. |
| 1    | At least one verb pair does not exist (fabrication). |
| 2    | `aca` is not on `PATH` — skipped, not failed (CI-friendly). |

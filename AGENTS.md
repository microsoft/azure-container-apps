# Agent instructions — azure-container-apps

This file is read by AI coding agents (GitHub Copilot CLI, Claude Code,
Cursor, etc.) working in this repository. Follow these conventions when
authoring documentation, samples, skills, or code in this repo.

## Python tooling: lead with `uv`

`uv` is the canonical Python tooling for this repository. When writing
docs, skills, samples, or scripts that involve Python, **always lead
with `uv`** — never lead with bare `python`, `python3`, `pip`, or
`pip3`.

### Required commands

| Task | Use |
|---|---|
| Install a package | `uv pip install <pkg>` |
| Install from a local wheel | `uv pip install ./path/to/*.whl` |
| Create a virtual env | `uv venv` |
| Run a script | `uv run <script.py>` |
| Run a one-shot tool | `uvx <tool>` |
| Sync a project's deps | `uv sync` |
| Add a dependency to a project | `uv add <pkg>` |

### Hard rules

1. **Do not lead with `pip install …` / `pip3 install …`** in any
   prose, code block, README, skill cue, or sample. Use
   `uv pip install …`.
2. **Do not lead with `python script.py` / `python3 script.py`** to
   invoke a script. Use `uv run script.py`.
3. **No "or" branches** that present `pip` / `python` / `python3` /
   `pip3` as an equally-valid alternative. Example of what **not** to
   write:

   > Canonical install: `uv pip install foo` (or `pip install foo`).

   Just write `uv pip install foo`. Period. No alternative.
4. Bare `python` / `python3` / `pip` / `pip3` are **acceptable inside
   examples that are showing legacy behavior, error output, or
   third-party docs we are quoting** — but never as the recommended
   command. If they appear, they should be incidental, not the
   instruction.
5. **Installing `uv` itself** uses the upstream installer:
   `curl -LsSf https://astral.sh/uv/install.sh | sh` (or
   `irm https://astral.sh/uv/install.ps1 | iex` on Windows). Don't
   recommend `pip install uv` (chicken-and-egg, and we are not leading
   with `pip`).
6. **Always preflight `uv` before invoking it in docs / scripts /
   skills.** Don't assume the user has `uv`. Gate the install:

   ```bash
   # Linux / macOS
   command -v uv >/dev/null 2>&1 || curl -LsSf https://astral.sh/uv/install.sh | sh
   uv pip install <pkg>
   ```

   ```powershell
   # Windows
   if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
     irm https://astral.sh/uv/install.ps1 | iex
   }
   uv pip install <pkg>
   ```

   This pattern works for any uv-leading command (`uv pip install`,
   `uv run`, `uv venv`, etc.).

### Why

- `uv` is materially faster and reproducible.
- Single-tool guidance reduces the "two ways to do it" tax on readers
  and downstream agents.
- Agents that fan out from our docs (e.g. coding agents in a sandbox)
  inherit a clean, consistent install path with no decision points.

## Other conventions

- Documentation lives near the code/skill it documents. Skill docs are
  under `plugin/skills/<skill-name>/`.
- When updating a skill, also update its acceptance-criteria table in
  `SKILL.md` if the change affects what a "correct response" looks
  like.
- Verify CLI flags against `aca --help` / `aca <verb> --help` before
  documenting them. Do not invent flags.

## Language runtime versions: recommend mainstream LTS only

When docs, samples, skills, or prereqs specify a minimum version of a
language runtime, **always recommend a version that is currently in
mainstream (full-support / bug-fix) status from its upstream
maintainer** — not just security-fix-only status, and never a version
that is EOL.

### Current floors (review quarterly)

| Stack | Recommend at least | Why |
|---|---|---|
| **Python** | **3.13+** | Python 3.13 is in mainstream bug-fix support through ~2027; 3.12 drops to security-only in late 2026; 3.10 / 3.11 are security-only / near-EOL. |
| **Node.js** | The current **Active LTS** (even-numbered) line | Skip "Current" odd lines for docs; skip "Maintenance LTS" once it drops to security-only. |
| **.NET** | The current **LTS** release (e.g. `.NET 10` once GA) | Use the LTS tag in `mcr.microsoft.com/dotnet/...:<tag>`. STS releases are fine for samples that explicitly call themselves out as such, but defaults / floors are LTS. |
| **Go** | One of the two most recent stable lines | Go supports only the two latest minors; older minors get no fixes. |
| **Java** | Latest **LTS** (e.g. 21) | Skip non-LTS feature releases for default guidance. |

### Rules

1. When you write "Python X.Y or later", "Node X+", ".NET X", etc.,
   pick the version from the table above. Bump the table when an
   upstream release rolls a line out of mainstream.
2. Do **not** carry over a previously-documented floor without
   checking it against current upstream support. Stale floors are
   the most common version-related doc bug.
3. CI matrices, container base images, and dev-container definitions
   should also default to the mainstream LTS version. Older versions
   are acceptable only as *additional* matrix legs (compatibility
   coverage), not as the default.
4. When a doc PR changes a runtime floor, update **every mention of
   that runtime version in the changed scope** in the same PR (search
   for `python 3\.` / `node` / `dotnet` / etc.). Don't leave one page
   on the old floor and another on the new one.

### Why

Recommending a runtime that is only on security-only support pushes
users onto a release that gets fewer / slower fixes and shorter
remaining support life. For samples and quickstarts in particular,
the floor we document tends to become what readers actually install
and run in production for years. We owe them the version that has
the longest remaining mainstream support window.

## Pre-PR checklist

- [ ] No bare `pip install …` / `pip3 install …` leading instructions
      added to docs or samples.
- [ ] No bare `python script.py` / `python3 script.py` leading
      instructions added to docs or samples.
- [ ] No "or `pip install …`" / "or `python …`" alternative branches
      added.
- [ ] Every `uv pip install …` / `uv run …` example in docs is
      preceded by the `command -v uv` (bash) / `Get-Command uv`
      (PowerShell) preflight (or runs in an environment where `uv` is
      known to be pre-installed, e.g. a sandbox disk that ships uv).
- [ ] Any new CLI commands verified against `aca --help`.
- [ ] Any language runtime version floor (Python, Node, .NET, Go,
      Java) matches the current mainstream-LTS table in the "Language
      runtime versions" section above.

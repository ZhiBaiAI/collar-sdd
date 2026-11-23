# Collar SDD — Universal AI-First Project Starter Template

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE) [![PRs Welcome](https://img.shields.io/badge/PRs%20welcome-brightgreen.svg)](CONTRIBUTING.md)

[中文](README.md) | English

> A tech-agnostic, AI-tool-agnostic starter scaffold that puts a practical "collar" on coding agents — **higher code quality and fewer rework loops, without burying day-to-day coding under heavy paperwork.**

## Why

AI coding in real repositories usually fails at one of two extremes:
1. **No guardrails**: session conclusions evaporate, new sessions guess repo conventions, and agents leave fake fixes or dead code.
2. **Heavyweight paperwork**: forcing full specs, duplicate test docs, and manual changelogs on every tiny edit slows delivery to a crawl.

Collar SDD balances both via **tiered workflow + real deterministic gates + lean context**:
- **Zero doc tax on Minor edits**: bugfixes and small refactors go straight through fast tests + automatic gates.
- **Lean docs on Standard/Major work**: a 4-section minimal `spec.md` (~30 lines), optional `tests.md`, and `git log`-generated changelogs via `scripts/collar-changelog.sh`.
- **High-signal context for any coding agent**: crisp repo map, enforced `default: deny` write boundaries, 3-tier validation (`fast` / `commit` / `release`), and battle-tested coding guardrails.

## What It Includes

| Component | Role |
|---|---|
| `AGENTS.md` entry map | Single entry point for every agent session: repo map, change tiers, validation commands, core guardrails (checked by S1) |
| `collar.yaml` contract | Identity (minimal must-read + lazy-read), Boundary (`default: deny` enforced), Validation (`fast` / `commit` / `release` gates) |
| Lean `docs/` knowledge base | 3 core modules out of the box (`specs`, `architecture`, `runbook`); 3 on-demand (`changelog`, `vendor`, `wiki`) |
| Tool-agnostic `skills/` | Maintenance skills stored once in `skills/` and symlinked to `.agents/skills` during cold start |
| POSIX scripts & Git hooks | Zero runtime dependencies, macOS & Linux compatible, `--json` output and semantic exit codes |

Read-only visual dashboard: [collar-board](https://github.com/ZhiBaiAI/collar-board).

---

## Quick Start (≤ 15-Minute Cold Start)

1. **Copy the skeleton** into your new project root (delete `.git` first if cloned).
2. **Initialize git and run cold start**:
   ```bash
   git init
   sh scripts/collar-init.sh --yes
   ```
   Cleans demo domains & demo changelogs, creates the universal `.agents/skills -> ../skills` symlink, installs git hooks, lists remaining `⟨⟩` placeholders, and runs structural checks.
3. **Fill live placeholders**: replace `⟨⟩` in `AGENTS.md` (project overview, repo map, 3-tier commands) and `collar.yaml` (add your root config files like `package.json`/`Makefile` to `allow_write` and wire real `fast`/`commit`/`release` commands).
   **Do NOT edit placeholders inside `_templates/`, `_template-*`, or `skills/*/SKILL.md`.**
4. **Smoke test**: ask any coding agent to read `AGENTS.md` and state the repo entry point and fast-check command.

### Tracking Template Updates

```bash
sh scripts/collar-sync.sh
```
Mechanical assets (`scripts/`, `skills/`, `docs/specs/_templates/`, `VERSION`) sync directly; skeleton docs show a diff for manual picking; project-owned files are never touched. See root [CHANGELOG.md](CHANGELOG.md) for template release notes.

---

## Directory Structure

```
.
├── AGENTS.md                 # Single entry map for agents (navigation + core guardrails)
├── collar.yaml               # Identity / Boundary / Validation contract
├── VERSION                   # Template version
├── scripts/                  # POSIX gate & workflow scripts (support --json)
│   ├── collar-check.sh       #   Structural gate (S0–S8)
│   ├── collar-boundary.sh    #   Enforces default: deny + allow_write + deny_write
│   ├── collar-init.sh        #   One-command cold start (clean + .agents/skills link + hooks)
│   ├── collar-new.sh         #   Auto-numbered feature / patch / sunset / proposal (--with-tests optional)
│   ├── collar-status.sh      #   In-flight overview + overdue patches + --specs --json
│   ├── collar-converge.sh    #   Mechanically merges patch §⑥ Delta into spec.md
│   ├── collar-changelog.sh   #   Generates grouped Markdown changelog from git log
│   ├── collar-anchors.sh     #   Generates anchor registry from //! comments
│   ├── collar-hooks.sh       #   Installs core.hooksPath → scripts/hooks/
│   ├── collar-sync.sh        #   Syncs upstream mechanical assets
│   └── hooks/                #   pre-commit / commit-msg / post-commit / pre-push
├── skills/                   # Six tool-agnostic collar-* Skills (symlinked to .agents/skills)
├── src/                      # Project source code (including tests)
└── docs/                     # Knowledge base (core: specs/architecture/runbook; on-demand: changelog/vendor/wiki)
```

---

## Progressive Adoption

| Stage | Enable | Overhead |
|---|---|---|
| **Day 1** | `AGENTS.md` + `collar.yaml` (write boundary + 3-tier checks) + `conventions.md` + `pre-commit` | Minimal — zero extra docs for Minor edits |
| **Feature work (Standard)** | Concise 4-section `spec.md` (inline AC checks) + `collar-specs` drift check | Low — no mandatory `tests.md` or manual changelog |
| **Parallel / Architecture (Major)** | `PATCH-NNN` (bidirectional pointers + Delta) + `ADR` + context stitching + `handoff.md` | On demand |
| **Larger teams** | `SUNSET` state machine + `PROPOSAL` channel + pre-seeded blueprints | Only when symptoms appear |

---

## Core Discipline

1. **Match process weight to impact**: Minor edits take the fast lane; only Standard/Major work creates specs/ADRs.
2. **Keep entry & conventions lean**: `AGENTS.md` only navigates; `conventions.md` holds proven coding guardrails (warns above 15 entries).
3. **Three-tier validation**: `fast` for after-edit/review, `commit` for pre-commit, `release` for merge/release.
4. **Never auto-backfill specs**: report Spec-Code drift for human decision.
5. **Externalize = stitch**: moving logic out of code requires an MCP read channel or `//!` anchors.
6. **Present tense in live docs**: history lives in git log / changelog / ADR / archives (enforced by S7).
7. **Single source of truth for Skills**: keep Skills in `skills/` and symlink (`.agents/skills`) rather than duplicating files.

---

## Contributing & License

Issues and PRs are welcome; see [CONTRIBUTING.md](CONTRIBUTING.md). Released under the [MIT License](LICENSE).

# Collar SDD — The open-source template that makes every AI session understand your project

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE) [![PRs Welcome](https://img.shields.io/badge/PRs%20welcome-brightgreen.svg)](CONTRIBUTING.md)

[中文](README.md) | English

> A project scaffold that puts a "collar" on your AI agent — for an agent, knowledge it can't see doesn't exist.
> Collar writes project context into repository files — **structured, versioned, automated** — so AI stops re-ingesting context every session.

## Why

AI coding on real projects keeps being "locally correct, globally wrong": the function is right, but a convention elsewhere just broke. The root cause is not model capability — it's missing and broken context. A session ends and its conclusions evaporate; a new session starts and the AI knows nothing; people and tools work in parallel and nobody can tell which knowledge is current.

Collar's answer: make the repository itself the AI's memory. Knowledge lands in files by convention, an entry map tells the agent where to read, and gates keep those files from rotting.

## What it is

| Component | Role |
|---|---|
| `AGENTS.md` entry map | The single entry point for every agent session, ≤120 lines, navigation only |
| Six-module knowledge base | specs (intent) · changelog (timeline) · architecture (structure & decisions) · runbook (pitfalls & conventions) · vendor (external references) · wiki (free-form) |
| Six companion Skills | Tool-agnostic maintenance specs defining how each module is read and written |
| `collar.yaml` three-layer collar | Identity (what it knows) · Boundary (what it may change, deny-by-default) · Validation (whether the change is right) |
| Unified commit gate | One git commit = structural gate + knowledge deposit + spec-drift check, all at once |

All of the above is **tech-agnostic**: no framework lock-in, no AI-tool lock-in (Cursor / Claude Code / WorkBuddy / any agent).

The companion [collar-board](https://github.com/ZhiBaiAI/collar-board) renders the knowledge base as a visual board — project status at a glance (see below).

---

## Quick Start (15-minute cold start for a new project)

1. **Copy the skeleton** into your new project root. An archive download ships without `.git`, so the copy starts clean; if you `git clone`d it, delete `.git` first so upstream remotes don't leak into the new project.
2. **Remove the demo content** (do this right after copying — checklist below; the mechanical parts can be run via `sh scripts/collar-init.sh --yes`).
3. **Fill in config placeholders**: only replace `⟨⟩` placeholders in the **live docs** — `AGENTS.md` (focus on "What is this project / Repo map / Quick commands"; keep it ≤ 120 lines), `collar.yaml`, this file's title, and defaults in each `docs/*/README.md` and `docs/runbook/*`.
   **Do NOT touch placeholders inside `_templates/`, `_template-*`, or `skills/*/SKILL.md`** — those are template internals, filled only when used.
4. **Lay out the site map**: create `NN_[Domain]xx/` directories under `docs/specs/` following your business map — see [docs/specs/README.md](docs/specs/README.md).
5. **git init**: the sooner the better — from the very first commit, `collar-changelog` has something to record.
6. **Wire the commit gate**: run `sh scripts/collar-hooks.sh` (hooks ship with the template — see [docs/runbook/commit-gate.md](docs/runbook/commit-gate.md)).
7. **Run a smoke test**: ask your AI to read `AGENTS.md` and answer "what is this project and which spec do I own?" — a correct answer means the context pipeline works.

### Tracking Template Updates

The upstream template keeps evolving after you copy it. `sh scripts/collar-sync.sh` applies a three-layer ownership rule:
`scripts/`, `skills/`, `docs/specs/_templates/`, `VERSION` are mechanical assets — **overwritten directly**;
`docs/runbook/` and `docs/*/README.md` are skeleton docs — **a diff report is produced for manual picking**;
your filled `AGENTS.md`, `collar.yaml`, `docs/specs/` business content, `docs/changelog/` are project-owned — **untouched**.
The template version lives in the root `VERSION` file; upstream releases bump it.

### Cleanup Checklist (delete / keep after copying)

| Action | Content |
|---|---|
| 🗑 Delete | `docs/specs/00_[示例域].../`, `docs/specs/01_[示范域].../` (demo data — pollutes your real site map) |
| 🗑 Delete | `docs/wiki/blue-print/[技术方案]核心循环V4-MVP.md` (demo blueprint) |
| 🗑 Empty examples | keep only the title and intro lines in `docs/changelog/2026/2026-09.md`; remove the ⟨示例域⟩ row from the claim table in `docs/specs/README.md` |
| ✅ Keep | `docs/wiki/blue-print/[讨论稿]哨兵机.md` (a pre-seeded advanced blueprint, not a demo) |
| ✅ Keep | `docs/specs/_templates/`, `docs/architecture/ADR/0000`, `docs/runbook/_template-*` (template internals) |
| ✂ After cold start | delete the "Quick Start", "Cleanup Checklist" and "Adopt as You Grow" sections of this file (usage instructions, obsolete once onboarded; the "Tracking Template Updates" subsection inside Quick Start is long-term guidance — keep it). **This file may be rewritten as your project's README**: the discipline & tailoring rules below are dual-written into runtime files (`collar.yaml` gates / `conventions.md` / `skills/README.md`), so replacing this README affects nothing |

---

## Directory Structure

```
.
├── AGENTS.md                 # The single entry map for agents (≤120 lines, navigation only)
├── collar.yaml               # Identity / Boundary / Validation — three-layer declaration
├── scripts/                  # Gate & operation scripts (language-agnostic, work out of the box)
│   ├── collar-check.sh       #   Structural gate: skeleton / line budget / AC alignment / pointers+delta / session deixis, 8 checks
│   ├── collar-new.sh         #   Scaffold a feature / patch / sunset from templates (auto-numbered)
│   ├── collar-status.sh      #   In-flight navigator: unconverged patches / gaps / overdue items + --specs listing
│   ├── collar-converge.sh    #   Mechanical patch convergence: merges Delta sections into spec.md
│   ├── collar-init.sh        #   Cold-start executor: cleans demo content + lists placeholders + runs the gate
│   ├── collar-hooks.sh       #   Installs git hooks (core.hooksPath → scripts/hooks/)
│   ├── collar-sync.sh        #   Template upgrade: pulls mechanical assets from upstream collar-sdd
│   └── hooks/                #   The pre-commit / commit-msg / post-commit / pre-push hook bodies
├── src/                      # Project source code (all code lives here, tests included)
│                             #   When adding top-level dirs, update the repo map in AGENTS.md
│                             #   and allow_write in collar.yaml
├── skills/                   # Six collar-* Skills (project assets, AI-tool agnostic)
│   ├── collar-specs/         #   specs module: source of intent + code-drift detection
│   ├── collar-changelog/     #   changelog module: what was done
│   ├── collar-architecture/  #   architecture module: current state + why it's designed this way
│   ├── collar-runbook/       #   runbook module: lessons learned (also guards AGENTS.md)
│   ├── collar-vendor/        #   vendor module: external reference code assets
│   └── collar-wiki/          #   wiki module: free-form human knowledge
└── docs/                     # Six knowledge-base modules (module ↔ Skill ↔ README trinity)
    ├── specs/                #   ① Site map / formal spec layer (feature · patch · sunset)
    ├── changelog/            #   ② Timeline (AI-maintained)
    ├── architecture/         #   ③ Architecture: structure view + engineering principles + ADR
    ├── runbook/              #   ④ Process knowledge: conventions · env deltas · commit gate · context stitching
    ├── vendor/               #   ⑤ External reference code (human drops in, AI distills)
    └── wiki/                 #   ⑥ Human knowledge base, incl. the blue-print exploration layer
```

---

## Adopt as You Grow

The system is adopted progressively — "when a symptom appears, enable the matching mechanism".
Most mechanisms work out of the box; a few are pre-seeded blueprints to activate at scale:

| When | You need | What's in the template |
|---|---|---|
| **Out of the box** | AI "understands" the project in every session | `AGENTS.md` entry map + six-module knowledge base + six Skills + `collar.yaml` + unified commit gate (all enabled by default) |
| **Multi-dev collaboration starts** | Conflicts and context breakage | specs site-map physical isolation + four change types (feature/patch/sunset/blueprint) + patch bidirectional pointers + sunset state machine + context-stitching protocol (built in — just follow it) |
| **Many parallel pre-release branches** — "every branch green, breaks after merge" | Invisible-conflict detection | Sentinel: pre-seeded blueprint ([讨论稿]哨兵机) + upgrade signals ([commit-gate.md](docs/runbook/commit-gate.md)) + timing decision ([ADR-0001](docs/architecture/ADR/0001-冲突检测介入时机.md)). The executor (daemon code) graduates from the blueprint |
| **Non-engineers join** (PM / design / QA) | Non-git users safely expressing intent on top of code | Proposal channel ([_templates/proposal.md](docs/specs/_templates/proposal.md)) + role-based Boundary (`collar.yaml` `roles`). Platform executors (sandbox, soft/hard locks) built as needed |

> Research sources for the pre-seeded blueprints are noted in the corresponding files.

---

## Companion dashboard: collar-board

The spec structures project knowledge into the repo, but seeing the project's status at a glance still means opening Markdown files one by one. The companion
[collar-board](https://github.com/ZhiBaiAI/collar-board) parses any Collar SDD project into a browser board —
what the project is, business map, in-flight changes, decision lineage, change timeline, structural facts:
whether the discipline holds and which changes are still unconverged, visible at a glance.

```bash
git clone https://github.com/ZhiBaiAI/collar-board && cd collar-board
npm start          # open http://localhost:5173, click "Import project", pick the project root
```

Two design lines shared with Collar: **read-only** (never touches the viewed project),
**no scoring** (only mechanically verifiable facts, each with its source; judgment stays with humans).
Requires Chrome / Edge (directory reading is currently Chromium-only).

---

## Discipline (what keeps this system from rotting)

1. **Knowledge must land in files.** A conclusion that stays in the chat was never concluded.
2. **The entry map must not bloat.** AGENTS.md only navigates; details move to `docs/`.
3. **The commit gate must not be bypassed.** One commit = structural gate + changelog + runbook + spec-drift check, all at once.
4. **Specs are never auto-backfilled.** When code drifts from spec, output a diff report — humans decide.
5. **If you move logic out of code, stitch the context back.** Any externalization must come with an MCP channel or anchor comments.
6. **Current-state docs use present tense only.** History belongs to changelog / ADR / sunset / archives (structural gate S7 enforces).
7. **Central registries hold low-frequency info only.** Ownership may be registered; progress, dates and routes are derivable —
   never hand-copy what the directory tree and the structural gate already answer (parallel-merge hotspots).

---

## Tailoring Rules

- The `collar.yaml` boundary list **only tightens, never loosens** (deny-by-default).
- The six Skills can be added or removed, but the **module ↔ Skill ↔ README trinity** must hold: a directory implies a Skill, a Skill implies a README defining its boundary.
- Numeric directory prefixes (`00_` / `01_`) keep the site map naturally ordered — do not switch to alphabetical sorting.
- `skills/` is **AI-tool agnostic**. When switching tools, only change symlinks or config —
  never copy Skill content into tool-specific directories. Multiple copies of the truth always rot.

---

## Contributing & License

Issues and PRs are welcome — this repo runs on Collar SDD discipline itself; see
[CONTRIBUTING.md](CONTRIBUTING.md) for the commit process. Released under the [MIT License](LICENSE).

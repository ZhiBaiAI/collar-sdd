# collar-* Skills

> **工具无关的唯一真源**：所有 Skill 只存一份在项目根 `skills/`；跨工具只建软链，不复制副本。
> 冷启执行 `sh scripts/collar-init.sh --yes` 会自动创建通用软链 `.agents/skills -> ../skills`。

---

## 速查（3 核心 + 3 按需）

| 层级 | Skill | 管哪个模块 | 适用时机 |
|---|---|---|---|
| **核心** | [collar-specs](collar-specs/SKILL.md) | `docs/specs/` | Standard/Major 新建精简 spec、patch 收敛、提交前 Spec-Code 差异检查（Minor 小改不触发） |
| **核心** | [collar-runbook](collar-runbook/SKILL.md) | `docs/runbook/` | 反复踩坑沉淀、编码红线维护（≤15 条）、`AGENTS.md` 入口守卫 |
| **核心** | [collar-architecture](collar-architecture/SKILL.md) | `docs/architecture/` | 不可逆技术决策（ADR）、结构视图、外置逻辑缝补检查 |
| **按需** | [collar-changelog](collar-changelog/SKILL.md) | `docs/changelog/` | 发版说明 / 阶段回顾（调用 `scripts/collar-changelog.sh`）与 `BREAKING` 迁移说明 |
| **按需** | [collar-vendor](collar-vendor/SKILL.md) | `docs/vendor/` | 外部参考代码减法引入与要点提炼 |
| **按需** | [collar-wiki](collar-wiki/SKILL.md) | `docs/wiki/` | 人工调研与蓝图孵化毕业 |

---

## Skill 编写与结构约定

1. **frontmatter 必填**：`name`（与目录名一致）、`description`（**必须同时写清「适用场景」与「不适用负例边界」**，防止误触发）、可选 `argument-hint`。
2. **渐进披露**：`SKILL.md` 只放路由与核心主流程，长细则与模板拆到同目录 `references/` 按需读取（参考 `collar-specs/references/`）。
3. **护栏集中**：`## 护栏` 列出硬否定句；流程末尾附 `Next:` 衔接行。

---

## 各 Agent 工具如何接入（只建软链，不复制）

| 工具约定 | 接入方式 |
|---|---|
| 支持通用 `.agents/skills` 的工具 | `collar-init.sh --yes` 已自动创建 `.agents/skills -> ../skills` |
| 需特定项目级技能目录的工具（如 `.claude/skills`） | 按需加一行软链：`mkdir -p .claude && ln -s ../skills .claude/skills` |
| 通用兜底 | 任意工具启动时先读根目录 `AGENTS.md`，按图索骥定位本目录 |

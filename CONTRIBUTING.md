# Contributing

本仓库自身按 Collar SDD 纪律运转——先读 [AGENTS.md](AGENTS.md)（它是所有贡献的入口地图）。

## 上手

```bash
git clone <repo> && cd collar-sdd
sh scripts/collar-hooks.sh   # 装配 git hooks（pre-commit / commit-msg / post-commit / pre-push）
```

## 提交纪律（提交关卡）

每次 commit = 四件事同时发生：changelog 条目 + runbook 沉淀 + Spec 差异确认 + 结构门禁全绿。

- commit message：`<类型>(<范围>): <说明>`（类型见 `docs/changelog/README.md` 与 `skills/collar-changelog`）
- 结构门禁：`sh scripts/collar-check.sh`（pre-commit 自动跑，CI 复核）
- 细节协议：[docs/runbook/commit-gate.md](docs/runbook/commit-gate.md) 与 [commit-checklist.md](docs/runbook/commit-checklist.md)

## 改动入口

| 要改什么 | 去哪 |
|---|---|
| 变更流程 / spec 模板 / 收敛 | `docs/specs/` + `scripts/collar-converge.sh` |
| 门禁规则 | `scripts/collar-check.sh` + `collar.yaml` `validation.gates` |
| 技能行为 | `skills/collar-*/SKILL.md`（结构约定见 `skills/README.md`） |
| git hooks | `scripts/hooks/` + `scripts/collar-hooks.sh` |

改脚本后请在临时副本里自测（`cp -r . /tmp/x`），脚本只依赖 POSIX sh + grep/find/sed/awk——**不许引入语言运行时依赖**。

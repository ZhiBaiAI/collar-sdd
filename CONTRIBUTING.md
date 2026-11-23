# Contributing

本仓库自身按 Collar SDD 纪律运转——先读 [AGENTS.md](AGENTS.md)。

## 上手

```bash
git clone <repo> && cd collar-sdd
sh scripts/collar-hooks.sh   # 装配 git hooks（pre-commit / commit-msg / post-commit / pre-push）
```

## 提交纪律（分级提交关卡）

- **所有提交**：`commit-msg` 首行遵守 `<类型>(<范围>): <说明>`；`pre-commit` 自动跑 `sh scripts/collar-check.sh` 与 `sh scripts/collar-boundary.sh`（CI 复核）。
- **Minor 小改**：门禁全绿即可提交，免写额外文档。
- **Standard / Major 改动**：按 [docs/runbook/commit-gate.md](docs/runbook/commit-gate.md) 完成 Spec 差异确认或 ADR 沉淀；模板版本演进记录在根目录 [CHANGELOG.md](CHANGELOG.md)。

## 改动入口

| 要改什么 | 去哪 |
|---|---|
| 变更流程 / spec 模板 / 收敛 | `docs/specs/` + `scripts/collar-converge.sh` |
| 门禁与写边界 | `scripts/collar-check.sh` + `scripts/collar-boundary.sh` + `collar.yaml` |
| 技能行为 | `skills/collar-*/SKILL.md`（结构约定见 `skills/README.md`） |
| git hooks | `scripts/hooks/` + `scripts/collar-hooks.sh` |

改脚本后请在临时副本里自测（`cp -r . /tmp/x`），脚本只依赖 POSIX sh + grep/find/sed/awk——**不许引入语言运行时依赖**，且需同时兼容 macOS (BSD) 与 Linux (GNU)。

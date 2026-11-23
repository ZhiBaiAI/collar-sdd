# docs/ — 轻量化知识库

> **对 Agent 来说，看不到的知识等于不存在；但代码与 Git 已表达的事实不手抄第二遍。**

---

## 模块分工（3 核心 + 3 按需）

新项目冷启默认使用 **核心 3 模块**；其余 3 模块按需启用，不在空项目里强塞空文件。

| 层级 | 模块 | 回答什么 | 启用时机 | 对应 Skill |
|---|---|---|---|---|
| **核心** | [specs/](specs/README.md) | 要做什么（意图源 + 验收标准） | Standard / Major 改动 | `collar-specs` |
| **核心** | [architecture/](architecture/README.md) | 现在怎样运转 + 为什么这么设计 | 架构/契约/原则变动 | `collar-architecture` |
| **核心** | [runbook/](runbook/README.md) | 编码红线、验证分层、排障与交接 | Day 1 即用 | `collar-runbook` |
| **按需** | [changelog/](changelog/README.md) | 关键里程碑与破坏性变更摘要 | 发版 / 阶段回顾（`collar-changelog.sh` 生成） | `collar-changelog` |
| **按需** | [vendor/](vendor/README.md) | 外部参考代码精简提炼 | 引入外部参考实现时 | `collar-vendor` |
| **按需** | [wiki/](wiki/README.md) | 未定型调研与蓝图孵化 | 大方案前期预研时 | `collar-wiki` |

## 分级协同

- **Minor 小改**：直接改代码 → 跑 `fast` 验证 → `pre-commit` 自动过结构与写边界门禁提交（零文档开销）。
- **Standard / Major 改动**：走精简 `spec.md` / `ADR`，提交前核对 Spec-Code 差异与外置逻辑缝补。详见 [runbook/commit-gate.md](runbook/commit-gate.md)。

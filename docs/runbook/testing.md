# docs/runbook/testing.md — 验证分层与测试入口

> **核心原则：审 Diff ≠ 发布验收。**
> 把验证拆成三档，让 Agent 改完代码几秒内拿到真实反馈，而不是每次小改或复查都跑几十分钟全量构建。

---

## 1. 三档验证节奏（与 `collar.yaml` `stage` 对齐）

| 档位 | `collar.yaml` stage | 跑什么 | 耗时目标 | 何时跑 |
|---|---|---|---|---|
| **快检（Fast）** | `fast` | 改动文件的 lint + 变更关联测试（`test:changed`） | 秒级 | **每次改码自检 / 代码复查（Review）** |
| **提交（Commit）** | `commit` | `collar-check` + `collar-boundary` + typecheck + unit | 数十秒内 | **`pre-commit` 自动拦截** |
| **发布（Release）** | `release` | 全量单测 + 集成 + 构建 + E2E（AI/Agent 项目加 Eval） | 分钟级 | **Major 架构改动 / 合并主干 / 发版前 / CI** |

**审 Diff（Code Review）防过度验证纪律**：
- 复查代码只读 diff 与直接调用方，最多跑 `fast` 档验证；**不默认跑全量单测和生产构建**（除非明确在做发布验收，或改动触及核心契约/权限/数据模型）。
- 只有某条 finding 的真假取决于底层实现时，才下钻读底层代码。

---

## 2. 测试分层词汇表

| 层级 | 测什么 | 速度 | 备注 |
|---|---|---|---|
| **unit** | 单个函数/模块的逻辑分支与边界值（无真实外部依赖） | ms 级 | 高频自测主力 |
| **integration** | 模块间协作、真实 DB / 中间件 | 秒级 | 覆盖核心链路 |
| **e2e** | 端到端用户旅程 | 分钟级 | CI / 预发 |
| **manual** | 无法自动化的视觉/交互/外部系统验收 | 人工 | 必须写明可复现步骤 |
| **eval**（可选） | AI / Agent 非确定性能力评测与回归集 | 分钟级 | 仅 AI/Agent 项目启用：区分能力 Eval 与回归 Eval，关注多 Trial 稳定性 |

---

## 3. 验收标准 `AC-N` 与测试的连接方式（不强制双写 `tests.md`）

为避免「写完测试代码再手抄一遍文档」，支持两种连接方式，按复杂度二选一：

1. **轻量内联模式（默认推荐）**：直接在 `spec.md` 的每条 `AC-N` 后标注验证命令或测试文件路径（也可在测试代码里写 `AC-1` 标识），**无需另建 `tests.md`**。
2. **独立伴生 `tests.md` 模式（复杂功能按需启用）**：当功能点有大量边界场景、复杂测试数据或手工验收清单时，用 `sh scripts/collar-new.sh feature <域> <名> --with-tests` 建立伴生 `tests.md`。一旦存在 `tests.md`，`collar-check` S3 会自动校验 `spec.md` ↔ `tests.md` 的 `AC-N` 双向对齐。

---

## 4. 新项目冷启冒烟清单（目标 ≤ 15 分钟）

| # | 步骤 | 通过标准 |
|---|---|---|
| 1 | 冷启与装配 | `sh scripts/collar-init.sh --yes` 无报错，`.agents/skills` 与 `git hooks` 就位 |
| 2 | 填核心配置 | `AGENTS.md` 仓库地图/命令与 `collar.yaml` `allow_write`/验证命令已填真实值 |
| 3 | 跑快检与门禁 | `sh scripts/collar-check.sh && sh scripts/collar-boundary.sh` 全绿；`fast` 命令可跑通 |
| 4 | 上下文冒烟 | 任意 Agent 读 `AGENTS.md` 后能准确复述「项目是什么、改码入口在哪、改完跑什么快检命令」 |

---

## 5. 测试核心红线

- **只测有价值的行为边界**：为真实回归、非平凡不变量与具体 bug 写测试，不为凑覆盖率写镜像实现细节的脆弱测试。
- **禁假修复**：不得通过删日志、吞异常、放宽断言或 `skip` 用例让测试变绿；修 bug 必附原失败用例回归。
- **报告随代码失效**：代码一旦再次修改，此前的验证通过记录即作废，须重新验证受影响范围。

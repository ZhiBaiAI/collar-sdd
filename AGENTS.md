# AGENTS.md — Agent 入口地图

> 本文件是 Agent 的入口地图（≤120 行）。**不放细节，只告诉你去哪里找。**
> 行数由 `collar-runbook` Skill 守卫：逼近 115 行时，把详情迁到 `docs/`，此处只留一行摘要 + 链接。

## 0. 铁律（动手前必读）

1. **只看本文件不够。** 按需打开下文的链接，禁止凭猜测改代码。
2. **看不到的知识等于不存在。** 任何结论必须落到仓库文件里，不留在会话里。
3. **Spec 是意图源，比代码更早期。** 代码偏离 Spec 不一定是错——可能编码时发现了更好的方案。提交时**只输出差异清单交人决策，禁止自动反向改 Spec**。
4. **任何导致上下文异常的架构变动都必须缝补。** 见 [上下文缝补协议](docs/runbook/context-stitching.md)。
5. **提交前必过门禁。** 见 [提交关卡](docs/runbook/commit-gate.md)。

## 1. 项目是什么

- **做什么**：Collar SDD——给 AI Agent 套「项圈」的开源项目脚手架（入口地图 + 六模块知识库 + 边界门禁 + 提交关卡），本仓库同时是模板本体与示例
- **服务谁**：用 AI Agent 做研发的团队与个人开发者；语言无关、AI 工具无关
- **当前阶段**：模板 v1 完成，开源准备中
- **北极星指标**：新项目冷启 ≤ 15 分钟即通过冒烟测试

## 2. 仓库地图

<!-- 占位：换成真实目录树。注释比树本身重要——它是 AI 唯一能读懂的「地形说明」。 -->
```
⟨repo-root⟩/
├── collar.yaml          # AI 项圈：Identity / Boundary / Validation 三层声明
├── AGENTS.md            # 本文件：入口地图
├── docs/                # 知识库六模块（详见第 5 节）
├── scripts/             # 门禁脚本：collar-check.sh（结构门禁，复制即生效）
└── src/                 # 源码（全部项目代码放这里）
```
**仓库地图必标三项**（AI 唯一能读懂的地形说明，漏标会让它改错地方）：
① 哪个是**唯一开发入口**；② 哪些是**已废弃、禁止改动**；③ 每个子应用的**端口**。
大型代码子模块可在其目录内就近放局部规则文件；多仓工作区每个子仓一行：路径 + 是什么 + 端口 + ①②标注。
约定：`⟨⟩` 表示模板占位符，落地时替换为真实值并删掉尖括号。

## 3. 快速命令

<!-- 占位：语言无关，按你的项目填。AI 不该去翻 README 猜命令。 -->
| 动作 | 命令 | 说明 |
|---|---|---|
| 结构门禁 | `sh scripts/collar-check.sh` | 知识库结构检查，复制即生效，提交前必过 |
| 变更操作 | `collar-new.sh` / `collar-status.sh` / `collar-converge.sh` / `collar-sync.sh`（均在 scripts/） | 建变更 / 在途导航 / patch 收敛 / 模板升级 |
| 装配关卡 | `sh scripts/collar-hooks.sh` | clone 后跑一次：git hooks（pre-commit 等 4 个）生效 |
| 安装依赖 | ⟨`make setup`⟩ | |
| 本地启动 | ⟨`make dev`⟩ | 端口 ⟨:3000⟩ |
| 构建 | ⟨`make build`⟩ | |
| 质量门禁 | ⟨`make lint` / `make typecheck` / `make test`⟩ | collar.yaml gates，按技术栈装配 |

## 4. 关键约定速查表

<!-- 只写「踩过坑才总结出来的强约定」，每条 = 一句话 + 详见链接。 -->
| 约定 | 一句话 | 详见 |
|---|---|---|
| 环境差异 | 预发与线上存在 ⟨差异点⟩，遇到无法解释的现象先怀疑环境 | [environments.md](docs/runbook/environments.md) |
| 外置逻辑 | 提示词/配置外置到平台时必须保留 `//!` 锚点注释 | [context-stitching.md](docs/runbook/context-stitching.md) |
| 分支策略 | 集成分支名 ⟨`releases/YYYYMMDD`⟩，个人分支不直接合主干 | [commit-gate.md](docs/runbook/commit-gate.md) |
| 事实缺口 | 缺事实就显式标记「待确认」并发起提问，禁止用猜测填充继续推进 | [conventions.md](docs/runbook/conventions.md) |
| 验收与测试 | spec §5 编号 `AC-N`，同目录 `tests.md` 测试点逐条回指；跨功能点知识去 testing.md | [testing.md](docs/runbook/testing.md) |
| 文档时态 | 现状文档只写现在时；历史叙述只进 changelog / ADR / sunset / 归档区 | [conventions.md](docs/runbook/conventions.md) |

完整表见 [关键约定](docs/runbook/conventions.md)。

## 5. 知识库六模块（去哪找答案）

| 我要找… | 去这里 | 谁维护 | 对应 Skill |
|---|---|---|---|
| 功能该怎么做（意图源） | [docs/specs/](docs/specs/README.md) | 人写 + AI 校验 | `collar-specs` |
| 什么时候改了什么 | [docs/changelog/](docs/changelog/README.md) | AI 自动 | `collar-changelog` |
| 系统现在怎样运转 + 为什么这么设计 | [docs/architecture/](docs/architecture/README.md) | AI 自动 + 人审 | `collar-architecture` |
| 踩过什么坑、有什么约定 | [docs/runbook/](docs/runbook/README.md) | AI 自动 | `collar-runbook` |
| 外部参考代码怎么用 | [docs/vendor/](docs/vendor/README.md) | 人放 + AI 提炼 | `collar-vendor` |
| 还没定型的想法 | [docs/wiki/](docs/wiki/README.md) | 人写 | `collar-wiki` |

## 6. 需求变更走哪条路（四种类型 + 提案通道）

| 场景 | 类型 | 落盘位置 | 模板 |
|---|---|---|---|
| 新功能 / 稳定功能迭代 | feature | `docs/specs/` | [feature.md](docs/specs/_templates/feature.md) |
| 小改动 / 多人并行改同一 feature | patch | `docs/specs/…/PATCH-xxx.md` | [patch.md](docs/specs/_templates/patch.md) |
| 旧功能下线 | sunset | `docs/specs/…/SUNSET-xxx.md` | [sunset.md](docs/specs/_templates/sunset.md) |
| 前期预研、未定型 | blueprint | `docs/wiki/blue-print/` | [blueprint.md](docs/wiki/blue-print/_template-blueprint.md) |
| **无 commit 权参与者 / AI 大改动** | proposal | `docs/specs/…/PROPOSAL-xxx.md`，审阅后落库 | [proposal.md](docs/specs/_templates/proposal.md) |

规则与成熟度阶梯见 [specs 站点地图](docs/specs/README.md)。

## 7. 提交关卡（git commit = 统一触发点）— **强制执行**

**Agent 每次 git commit 前必须依次完成下列 7 步，缺一项不得提交：**

1. 打开 [commit-checklist.md](docs/runbook/commit-checklist.md) 逐项勾选
2. `sh scripts/collar-check.sh` → 结构门禁全绿（技术拦截，缺一项直接失败）
3. `collar-changelog` → 记**做了什么**（时间线）
4. `collar-runbook` → 抽**学到了什么**（过程知识）
5. `collar-specs` → 检**代码是否偏离意图**（**只报不改**，交人决策）
6. 确认本文件 ≤ 115 行（超出先迁出详情再提交）
7. 确认本次没有「外置逻辑却未缝补」

**禁止**：以「改动很小 / 赶时间」为由跳过；用 `--no-verify` **静默**绕过。
**允许绕过**：仅 `WIP` 与纯 typo 修正，且必须在 commit message 写明原因，月度回顾会列出。

> 知识沉淀是**流程门禁**，不是自觉。一旦开始欠账，知识库很快就会烂掉。

详见 [commit-gate.md](docs/runbook/commit-gate.md)。

## 8. AI 的行为边界

由 [collar.yaml](collar.yaml) 声明：Identity 管知道什么、Boundary 管能改什么、Validation 管改得对不对。**Boundary 默认拒绝（deny-by-default）**。

Skill 清单见 [skills/](skills/README.md)（项目自带，与具体 AI 工具无关）。

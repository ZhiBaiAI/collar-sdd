# Collar SDD — 让每个 AI 会话都懂你项目的开源模板

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE) [![PRs Welcome](https://img.shields.io/badge/PRs%20welcome-brightgreen.svg)](CONTRIBUTING.md)

[English](README.en.md) ｜ 中文

> 给 AI Agent 套「项圈」的项目脚手架 —— 对 Agent 来说，看不到的知识等于不存在。
> Collar 把项目上下文**结构化、版本化、自动化**地写进仓库文件，AI 不再需要每次会话重新 briefing 上下文。

## 为什么需要它

AI 编码在真实项目里屡屡「局部正确、整体错误」：单个函数改对了，却破坏了别处的约定。根因不是模型不够聪明，而是上下文缺失与断裂——会话一结束，聊清楚的结论就蒸发；新会话重开，AI 对项目一无所知；多人多工具并行，没人说得准哪份知识是最新真相。

Collar 的解法是让仓库本身成为 AI 的记忆：知识按规范落盘成文件，入口地图告诉 Agent 去哪读，门禁保证这些文件不腐烂。

## 它是什么

| 组成 | 作用 |
|---|---|
| `AGENTS.md` 入口地图 | Agent 每次会话的唯一入口，≤120 行只做导航 |
| 六模块知识库 | specs（意图源）· changelog（时间线）· architecture（结构与决策）· runbook（坑与约定）· vendor（外部参考）· wiki（自由知识） |
| 六个配套 Skill | 与 AI 工具无关的模块维护规范，规定每个模块怎么读写 |
| `collar.yaml` 三层项圈 | Identity（知道什么）· Boundary（能改什么，默认拒绝）· Validation（改得对不对） |
| 提交关卡 | 一次 git commit = 结构门禁 + 知识沉淀 + Spec 差异检查，同时完成 |

以上全部**语言无关**：不绑定技术栈，也不绑定任何 AI 工具（Cursor / Claude Code / WorkBuddy / 任意 Agent）。

配套看板 [collar-board](https://github.com/ZhiBaiAI/collar-board) 把知识库解析成可视化面板，项目状态一眼可见（见下文）。

---

## 快速开始（新项目 15 分钟冷启）

1. **复制骨架**：把本目录拷到新项目根。下载压缩包得到的副本不带 `.git`，复制即干净；若是 `git clone` 下来的，先删掉 `.git`，避免把上游远端配置带进新项目。
2. **清理示范内容**：清单见下表；机械部分可用 `sh scripts/collar-init.sh --yes` 一并完成。
3. **填配置占位符**：只替换**活文档**里的 `⟨⟩` —— `AGENTS.md`（重点：项目是什么/仓库地图/快速命令三节，保持 ≤120 行）、`collar.yaml`、本文件标题、各 `docs/*/README.md` 与 `docs/runbook/*` 的默认值。  
   **不要动 `_templates/`、`_template-*` 和 `skills/*/SKILL.md` 里的占位符** —— 那些是模板本体，用到时才填。
4. **铺站点地图**：在 `docs/specs/` 下按业务地图建 `NN_[业务地图]XX域/`，见 [docs/specs/README.md](docs/specs/README.md)。
5. **git init**：越早越好——从第一个 commit 起，`collar-changelog` 就有东西可记。
6. **装配提交关卡**：`sh scripts/collar-hooks.sh`（hooks 随模板自带，详见 [docs/runbook/commit-gate.md](docs/runbook/commit-gate.md)）。
7. **跑一次冒烟**：让 AI 读 `AGENTS.md` 后复述「这个项目是什么、我负责哪个 spec」——答得上来，说明上下文链路已通。

### 跟进模板更新

复制之后上游仍在演进。`sh scripts/collar-sync.sh` 按「谁拥有这文件」分三层处理：
`scripts/`、`skills/`、`docs/specs/_templates/`、`VERSION` 属机械资产**直接覆盖**；
`docs/runbook/`、各 `docs/*/README.md` 属骨架文档**只出 diff 报告人工挑**；
`AGENTS.md` 已填内容、`collar.yaml`、`docs/specs/` 业务内容、`docs/changelog/` 属项目自有**不碰**。
版本号见根目录 `VERSION`，随上游发版更新。

### 落地清理清单（复制后删除 / 保留）

| 处置       | 内容                                                                                     |
| -------- | -------------------------------------------------------------------------------------- |
| 🗑 删     | `docs/specs/00_[业务地图]示例域/`、`docs/specs/01_[业务地图]示范域/`（示范数据，混进真实项目会污染站点地图）              |
| 🗑 删     | `docs/wiki/blue-print/[技术方案]核心循环V4-MVP.md`（示范蓝图）                                       |
| 🗑 清空示例段 | `docs/changelog/2026/2026-09.md` 只留标题与说明行；`docs/specs/README.md` 认领表的 ⟨示例域⟩ 行          |
| ✅ 留      | `docs/wiki/blue-print/[讨论稿]哨兵机.md`（预置的高阶升级蓝图，非示范）                                      |
| ✅ 留      | `docs/specs/_templates/`、`docs/architecture/ADR/0000`、`docs/runbook/_template-*`（模板本体） |
| ✂ 冷启后删 | 本文件的「快速开始」「落地清理清单」「随团队成长逐步启用」三节（模板使用说明，冷启后即失效；「快速开始」内的「跟进模板更新」小节属长期说明，保留）。**本文件可整体重写为项目说明**：其中的使用纪律与裁剪原则已双写进运行时文件（`collar.yaml` gates / `conventions.md` / `skills/README.md`），此处只是导读副本，改掉 README 不影响任何规则 |

---

## 目录结构

```
.
├── AGENTS.md                 # Agent 唯一入口地图（≤120 行，只导航）
├── collar.yaml               # Identity / Boundary / Validation 三层声明
├── scripts/                  # 门禁与操作脚本（语言无关，复制即生效）
│   ├── collar-check.sh       #   结构门禁：骨架 / 行数 / AC 对齐 / 双向指针+delta / 会话指代等 8 项
│   ├── collar-new.sh         #   从模板建 feature / patch / sunset（自动编号）
│   ├── collar-status.sh      #   在途导航：未收敛 patch / 缺口 / 超期项 + --specs 清单
│   ├── collar-converge.sh    #   patch 机械收敛：Delta 三段合并进 spec.md
│   ├── collar-init.sh        #   冷启执行体：清理示范内容 + 扫占位符 + 跑门禁
│   ├── collar-hooks.sh       #   装配 git hooks（core.hooksPath → scripts/hooks/）
│   ├── collar-sync.sh        #   模板升级：从上游 collar-sdd 拉取机械资产
│   └── hooks/                #   pre-commit / commit-msg / post-commit / pre-push 钩子本体
├── src/                      # 项目源码（全部代码放这里，含测试）
│                             #   新增顶层目录时需同步 AGENTS.md 仓库地图与 collar.yaml 的 allow_write
├── skills/                   # 六个 collar-* Skill（项目自带，与 AI 工具无关）
│   ├── collar-specs/         #   specs 模块：意图源 + 代码偏离检测
│   ├── collar-changelog/     #   changelog 模块：做了什么
│   ├── collar-architecture/  #   architecture 模块：现在怎样运转 + 为什么这么设计
│   ├── collar-runbook/       #   runbook 模块：踩了什么坑（兼守卫 AGENTS.md）
│   ├── collar-vendor/        #   vendor 模块：外部参考代码资产
│   └── collar-wiki/          #   wiki 模块：人工自由知识库
└── docs/                     # 知识库六模块（模块 ↔ Skill ↔ README 三位一体）
    ├── specs/                #   ① 站点地图 / 正式规格层（feature·patch·sunset）
    ├── changelog/            #   ② 时间线（AI 自动）
    ├── architecture/         #   ③ 架构：结构视图 + 工程原则 + ADR
    ├── runbook/              #   ④ 过程知识：约定·环境差异·提交关卡·上下文缝补
    ├── vendor/               #   ⑤ 外部参考代码（人放 + AI 提炼）
    └── wiki/                 #   ⑥ 人工知识库，含 blue-print 蓝图探索层
```

---

## 随团队成长逐步启用

这套体系按「出现什么症状、启用什么机制」渐进采用——
大多数机制复制即可用，少数是预置蓝图，等规模到了再落地：

| 什么时候 | 需要什么 | 模板里的对应物 |
|---|---|---|
| **复制即可用** | AI 每个会话都「懂」项目 | `AGENTS.md` 入口地图 + 六模块知识库 + 六个 Skill + `collar.yaml` 三层项圈 + commit 统一关卡（默认全启用） |
| **开始多人协作** | 冲突与上下文断裂 | specs 站点地图物理隔离 + 四种变更类型（feature/patch/sunset/blueprint）+ patch 双向指针 + sunset 状态机 + 上下文缝补协议（已内建，按规范用即可） |
| **预发并行分支变多**，出现「各自分支全绿、合并后才炸」 | 隐形冲突检测 | 哨兵机：预置蓝图（[讨论稿]哨兵机）+ 升级信号（[commit-gate.md](docs/runbook/commit-gate.md)）+ [ADR-0001](docs/architecture/ADR/0001-冲突检测介入时机.md) 介入时机决策。执行体（daemon 代码）按蓝图毕业 |
| **非研发角色参与**（产品/设计/测试） | 不懂 git 的人安全地基于代码表达意图 | 提案通道（[_templates/proposal.md](docs/specs/_templates/proposal.md)）+ 角色化 Boundary（`collar.yaml` `roles`）。平台执行体（沙箱、软硬双锁）按需自建 |

> 预置蓝图里的调研出处已在对应文件中标注。

---

## 可视化看板：collar-board

规范把知识结构化进了仓库，但要「一眼看清项目状态」，仍得逐个打开 Markdown。配套的
[collar-board](https://github.com/ZhiBaiAI/collar-board) 把遵循 Collar SDD 规范的项目解析成浏览器面板——
项目是什么、业务地图、在途变更、决策脉络、变更时间线、结构事实，
规范是否被遵守、哪些变更还没收敛，一眼可见。

```bash
git clone https://github.com/ZhiBaiAI/collar-board && cd collar-board
npm start          # 浏览器打开 http://localhost:5173，点「导入项目」选项目根目录
```

两条设计底线，与 Collar 同源：**只读**（不修改被查看项目的任何文件），
**不评分**（只呈现可机械核对的事实并标注依据出处，判断权交给人）。
需要 Chrome / Edge（目录读取能力目前仅 Chromium 内核支持）。

---

## 使用纪律（决定这套体系会不会烂掉）

1. **知识必须落盘**。会话里说清楚的结论不写进 `docs/`，等于没说。
2. **入口地图不许膨胀**。AGENTS.md 只导航，细节一律迁到 `docs/`。
3. **提交关卡不许绕过**。一次提交 = 结构门禁 + changelog + runbook + spec 差异四件事同时发生。
4. **Spec 不自动反向更新**。代码偏离 Spec 时输出差异清单，决策权在人。
5. **外置即缝补**。任何把逻辑挪出代码的优化，必须同步补上 MCP 通道或锚点注释。
6. **现状文档只写现在时**。历史叙述只进 changelog / ADR / sunset / 归档区（结构门禁 S7 拦截）。
7. **中心登记表只放低频信息**。责任认领可登记，进度/日期/路由等可推导信息不手抄——
   能由目录结构与结构门禁回答的，不建第二份副本（避免并行冲突热点）。

---

## 裁剪原则

- `collar.yaml` 的 boundary 列表**只会收紧、不会放宽**（deny-by-default）。
- 六个 Skill 可按需增减，但**模块 ↔ Skill ↔ README 三位一体**不允许破：有目录就得有 Skill，有 Skill 就得有 README 说明边界。
- 目录数字前缀（`00_`/`01_`）保证站点地图天然有序，不要改成字母排序。
- `skills/` 与 AI 工具无关，**不绑定任何产品**。换工具时只改软链或配置，  
  不要把 Skill 内容复制进各工具目录 —— 多份真相必然腐烂。

---

## 参与贡献 & 许可

欢迎 Issue 与 PR——本仓库自身也按 Collar SDD 纪律运转，提交流程见
[CONTRIBUTING.md](CONTRIBUTING.md)。项目基于 [MIT License](LICENSE) 开源。

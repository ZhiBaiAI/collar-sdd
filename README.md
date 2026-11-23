# Collar SDD — 让每个 AI 会话都懂你项目的通用启动模板

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE) [![PRs Welcome](https://img.shields.io/badge/PRs%20welcome-brightgreen.svg)](CONTRIBUTING.md)

[English](README.en.md) ｜ 中文

> 给 AI Agent 套「项圈」的通用项目脚手架 —— **让编码 Agent 改得更准、少返工，同时不为小改动背文档重税。**
> Collar 把项目关键上下文**结构化、轻量化、门禁化**地写进仓库，不绑定编程语言，也不绑定任何 AI 工具。

## 为什么需要它

AI 编码在真实项目里常出现两类极端：
1. **无约束**：会话结束结论蒸发，新会话对项目一无所知，容易假修复、改坏别处约定、留下死代码。
2. **过度文档**：每改一行都要写长篇 spec、抄测试表、补月报，开发节奏反而被流程拖慢。

Collar SDD 的解法是**轻文档 + 硬门禁 + 分级通道**：
- **Minor 小改零文档阻塞**：修 bug / 调局部逻辑直接改代码、跑快检、过自动门禁提交。
- **Standard / Major 才写精简文档**：核心 4 节 spec（~30 行），`tests.md` 按需可选，changelog 从 `git log` 自动生成。
- **把注意力留给真正提升改码质量的事**：清晰目录地图、真实拦截的写边界、三档验证命令（`fast` / `commit` / `release`）与高密度编码红线。

## 它是什么

| 组成 | 作用 |
|---|---|
| `AGENTS.md` 入口地图 | 所有 Agent 会话的唯一入口，只放导航、分级规则、验证命令与核心红线（S1 自动校验） |
| `collar.yaml` 三层项圈 | Identity（最小必读 + 按需加载）· Boundary（`default: deny` 真实拦截）· Validation（`fast`/`commit`/`release` 三档门禁） |
| 轻量化知识库 `docs/` | 核心 3 模块开箱（`specs` / `architecture` / `runbook`），其余 3 模块按需启用（`changelog` / `vendor` / `wiki`） |
| 配套 Skill `skills/` | 工具无关的模块维护规范，冷启自动软链至通用 `.agents/skills` |
| POSIX 门禁脚本与 Hooks | 零运行时依赖，跨 macOS / Linux，支持 `--json` 输出与清晰退出码 |

配套只读可视化看板：[collar-board](https://github.com/ZhiBaiAI/collar-board)。

---

## 快速开始（新项目 ≤ 15 分钟冷启）

1. **复制骨架**：把本目录拷到新项目根（若用 `git clone`，先删 `.git` 避免带入上游远端）。
2. **初始化仓库并一键冷启**：
   ```bash
   git init
   sh scripts/collar-init.sh --yes
   ```
   会自动完成：清理示范内容与示范时间线、建立跨工具通用软链 `.agents/skills -> ../skills`、装配 `git hooks`、列出剩余 `⟨⟩` 占位符并跑一次结构门禁。
3. **填关键占位符**：只替换活文档里的 `⟨⟩` —— 重点是 `AGENTS.md`（项目是什么 / 仓库地图 / 三档验证命令）与 `collar.yaml`（`allow_write` 补入你的项目配置文件如 `package.json`、`Makefile`，并填入 `fast` / `commit` / `release` 命令）。
   **不要动 `_templates/`、`_template-*` 和 `skills/*/SKILL.md` 里的占位符。**
4. **冒烟验证**：让任意 AI 工具读 `AGENTS.md` 后回答「这个项目是什么、修改代码后该跑什么快检命令」——答得上来即链路打通。

### 跟进模板更新

```bash
sh scripts/collar-sync.sh
```
按三层所有权升级：`scripts/`、`skills/`、`docs/specs/_templates/`、`VERSION` 直接覆盖；`docs/runbook/` 与各 `README.md` 出 diff 供人工挑；项目自有内容不碰。模板自身演进见根目录 [CHANGELOG.md](CHANGELOG.md)。

---

## 目录结构

```
.
├── AGENTS.md                 # Agent 唯一入口地图（只导航）
├── collar.yaml               # Identity / Boundary / Validation 三层声明
├── VERSION                   # 模板版本号（collar-sync.sh 对齐基准）
├── scripts/                  # POSIX 门禁与操作脚本（复制即生效，支持 --json）
│   ├── collar-check.sh       #   结构门禁（S0–S8）：骨架 / 入口结构 / AC 编号与可选对齐 / ADR 索引 / patch Delta / 卫生 / 指代词 / 锚点
│   ├── collar-boundary.sh    #   写边界真实拦截：执行 collar.yaml 的 default: deny + allow_write + deny_write
│   ├── collar-init.sh        #   一键冷启：清示范 + 建 .agents/skills 软链 + 装 hooks + 扫占位符
│   ├── collar-new.sh         #   自动编号建 feature / patch / sunset / proposal（可选 --with-tests）
│   ├── collar-status.sh      #   在途导航：未收敛/超期 patch、缺口 + --specs --json 清单
│   ├── collar-converge.sh    #   patch 收敛：把 §⑥ Delta 机械合并进 spec.md
│   ├── collar-changelog.sh   #   从 git log 自动生成分组变更摘要（替代手写月报）
│   ├── collar-anchors.sh     #   从代码 //! 注释自动生成锚点登记册
│   ├── collar-hooks.sh       #   装配 git hooks（core.hooksPath → scripts/hooks/）
│   ├── collar-sync.sh        #   模板升级：从上游拉取机械资产
│   └── hooks/                #   pre-commit / commit-msg / post-commit / pre-push
├── skills/                   # 六个 collar-* Skill（唯一真源，软链至 .agents/skills）
├── src/                      # 项目源码（含测试代码）
└── docs/                     # 知识库（核心：specs / architecture / runbook；按需：changelog / vendor / wiki）
```

---

## 随项目成长逐步启用

| 阶段 | 启用什么 | 文档成本 |
|---|---|---|
| **Day 1（个人 / 小团队冷启）** | `AGENTS.md` + `collar.yaml`（写边界 + 三档验证）+ `runbook/conventions.md` + `pre-commit` | **极低**：Minor 改动零文档，靠快检与自动门禁保质 |
| **功能迭代（Standard）** | `docs/specs/` 精简 4 节 `spec.md`（内联 AC 验证）+ `collar-specs` 差异检查 | **低**：30 行一页，免强制 `tests.md` 与手写 changelog |
| **多人并行 / 架构演进（Major）** | `PATCH-NNN`（双向指针 + Delta 收敛）+ `ADR` + 上下文缝补 + `handoff.md` 跨会话交接 | **按需**：只在复杂/跨人/跨会话任务触发 |
| **大团队治理（预置蓝图）** | `SUNSET` 下线状态机 + `PROPOSAL` 提案通道 + 哨兵机预置蓝图 | 等症状出现再启用 |

---

## 可视化看板：collar-board

配套的 [collar-board](https://github.com/ZhiBaiAI/collar-board) 以只读、不评分方式把 Collar 项目解析成浏览器面板：

```bash
git clone https://github.com/ZhiBaiAI/collar-board && cd collar-board
npm start          # 打开 http://localhost:5173 导入项目根目录
```

---

## 核心使用纪律

1. **分级做事**：Minor 小改走快通道，不为小改动写八股文；Standard / Major 再落精简 Spec / ADR。
2. **入口不膨胀**：`AGENTS.md` 只导航，细节下沉 `docs/`；`conventions.md` 只收反复踩坑的编码红线（>15 条告警合并退役）。
3. **验证分三档**：改后自检/审 diff 跑 `fast`，提交跑 `commit`，发版/大改跑 `release`。
4. **Spec 不自动反向改**：代码偏离 Spec 时只输出差异清单交人决策。
5. **外置即缝补**：把提示词/配置/脚本挪出代码，必须同步补 MCP 通道或 `//!` 锚点。
6. **现状只写现在时**：历史叙述进 git log / changelog / ADR / 归档区（S7 拦截会话指代词）。
7. **唯一真源**：Skill 只留在 `skills/`，跨工具只用软链（如 `.agents/skills`）不复制副本。

---

## 参与贡献 & 许可

欢迎 Issue 与 PR，贡献方式见 [CONTRIBUTING.md](CONTRIBUTING.md)。项目基于 [MIT License](LICENSE) 开源。

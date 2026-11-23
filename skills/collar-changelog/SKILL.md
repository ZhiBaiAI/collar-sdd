---
name: collar-changelog
description: 基于 git log 按需生成阶段/发版变更摘要（scripts/collar-changelog.sh），并在 BREAKING 破坏性变更或里程碑发版时整理 docs/changelog/ 与迁移说明。不适用于：日常 Minor/Standard 每次普通提交（日常只需写好 Conventional Commit 首行，禁止为了普通提交手写月报）。当用户说「生成发版说明」「这个月改了什么」「整理 changelog」「记录破坏性变更迁移方式」时使用。
agent_created: true
argument-hint: ⟨git range 或 --since YYYY-MM-DD⟩
---

# collar-changelog — 按需变更摘要与发版整理

## 定位

**Git log 就是日常时间线**，不重复手写。本 Skill 只在以下三个时机启用：
1. 生成发版说明或阶段回顾（运行 `sh scripts/collar-changelog.sh`）。
2. 记录 `BREAKING` 破坏性变更及迁移方式。
3. 阶段回顾时顺带触发知识库卫生检查（约定退役、ADR 归档）。

## 执行步骤

1. **提取提交事实**：优先跑确定性脚本 `sh scripts/collar-changelog.sh [range | --since YYYY-MM-DD]`，按 `BREAKING` / `feat` / `fix` / `refactor` / `sunset` / `chore` 分组输出。
2. **去噪润色（仅发版/里程碑时）**：合并零散 WIP/修 typo 提交，把 `BREAKING` 置顶并补齐迁移步骤；按需写入 `docs/changelog/YYYY/YYYY-MM.md` 或根目录 `CHANGELOG.md`。
3. **阶段卫生巡检（月度/发版回顾）**：
   - 检查 `conventions.md` 是否有长期未命中的条目可合并或退役。
   - 检查 `docs/architecture/ADR/` 是否有已失效决策应标 `deprecated` / `superseded`。

## 护栏

- ❌ 要求日常每次 commit 手动修改月度 changelog 文件
- ❌ 漏掉 `BREAKING` 变更的迁移方式
- ❌ 在现状文档里写会话指代词（S7 拦截）

Next: 需要沉淀重复踩坑转 `collar-runbook`；需要架构复盘转 `collar-architecture`。

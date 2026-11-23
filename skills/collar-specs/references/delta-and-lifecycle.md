# Patch Delta、收敛与 Sunset 细则（按需参考）

> 本文件由 `collar-specs` 按需加载：仅当需要写 `patch`、`sunset` 或执行收敛时读本文件。

---

## 1. Patch 双向指针与 Delta 四段（硬性）

单向指针会造成语义二义性，两个方向必须同时建：
- **Patch → 主文档**：开头写「① 覆盖范围（目标文件 + 章节 + 原状态 + 新状态）」，且 Patch 自身可独立阅读。
- **主文档 → Patch**：在被替代章节标注「本段已被 PATCH-NNN 取代 + 链接 + 生效日期」。

**Patch §⑥ 验收标准必须用 Delta 四段**（`collar-check` S5 机械校验、`collar-converge.sh` 机械合并）：
- `### ADDED`：新增验收标准，编号 `AC-P⟨NNN⟩-N`
- `### MODIFIED`：替代主文档既有 `AC-N`（编号必须在主文档存在）
- `### REMOVED`：作废主文档既有 `AC-N`（附原因）
- `### RENAMED`：只改编号不改正文，`- FROM: \`AC-旧号\`` 紧跟 `- TO: \`AC-PNNN-N\`` 成对写

规则：
- 没有对应类型的小节整节删除，不留空标题。
- 同一个 `AC-N` 不许跨多个小节出现。
- 若目录存在伴生 `tests.md`，改动验收标准后同步更新 `tests.md`。

### Patch 收敛

- **并存期**：以 patch 为准，主文档被取代章节仅作历史。
- **收敛时机**：合并后稳定 ⟨14⟩ 天无回滚，或同一 feature 下 patch 累积 ≥ ⟨3⟩ 个（`sh scripts/collar-status.sh` 自动提示）。
- **收敛动作**：跑 `sh scripts/collar-converge.sh <PATCH-文件>` 机械合并 §⑥ Delta 并标「已收敛」→ 按脚本末尾清单合入正文、移除取代标记、补记变更历史。**收敛不删除 patch 文件。**

---

## 2. Sunset 状态机（不是删除）

**禁止 `git rm` 旧 spec**——代码删了有 git 历史，意图删了就永久丢上下文。
Sunset 产出可执行迁移剧本：`评估 → 预告 → 双写/灰度 → 切流 → 观察 → 归档`（每步写进入条件、验证方式与回滚口径），完成后移入 `docs/specs/_archived/`。

---

## 3. Proposal 提案通道

无直接合库权限的角色或需要审阅的大改动先写 `PROPOSAL-NNN-简述.md`（使用 `docs/specs/_templates/proposal.md`），审阅通过后由本 Skill 转为 `feature` 或 `patch` 落库；驳回时保留理由。

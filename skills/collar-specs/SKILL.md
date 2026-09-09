---
name: collar-specs
description: 管理 docs/specs 站点地图（意图源）。两种模式——写 Spec（按 feature/patch/sunset/blueprint 四种变更类型落盘，强制 patch 双向指针）、校验 Spec（提交时做代码 ↔ Spec 差异检测，只输出差异清单交人决策，禁止自动反向改 Spec）。当用户说「写个 spec」「这个需求怎么做」「加个功能」「改一下 XX」「XX 下线」「提交前检查一下」时使用。
agent_created: true
---

# collar-specs — Spec 站点地图管理员

## 核心哲学（先记住这两条，它们决定了所有行为）

1. **Spec 是意图源，比代码更早期。**
   代码偏离 Spec **不一定是错误**——可能是编码过程中发现了更好的方案。
2. **因此提交时不自动反向更新 Spec。**
   只输出「差异清单」，把决策权交给人。把「文档变化」从静默忽略变成显式决策。

## 触发方式

| 类型 | 时机 | 行为 |
|---|---|---|
| 主动 | 用户描述新需求 / 说「写个 spec」「这个怎么做」「XX 下线」 | 进入**模式 A：写 Spec** |
| 被动 | git commit（提交关卡，强制） | 进入**模式 B：校验 Spec** |
| 被动 | 用户改完代码说「提交」「commit」 | 同模式 B |

---

## 模式 A：写 Spec

### Step 1 — 判定变更类型（这决定了文件放哪）

| 场景 | 类型 | 落盘位置 |
|---|---|---|
| 新功能；或稳定功能的正式迭代 | **feature** | `docs/specs/NN_[业务地图]域/NN_功能名/spec.md` |
| 小改动；或多人要并行改同一个 feature | **patch** | `docs/specs/…/PATCH-NNN-简述.md` |
| 旧功能下线 / 迁移 | **sunset** | `docs/specs/…/SUNSET-NNN-简述.md` |
| 前期预研、还没定型 | **blueprint** | `docs/wiki/blue-print/`（**不在 specs 里**） |
| 无 commit 权参与者 / AI 大改动 | **proposal** | `docs/specs/…/PROPOSAL-NNN-简述.md`（审阅通过后由本 Skill 转为 feature/patch 落库） |

判断口诀：**定型了才进 specs，没定型一律去 wiki 的 blue-print 里养。**

### Step 2 — 定位站点地图坐标

1. 打开 `docs/specs/README.md` 看业务地图划分与认领表。
2. 归属到已有业务域；**没有合适域就新建 `NN_[业务地图]XX域/`**，并同步更新站点地图与认领表。
3. 数字前缀保证有序，不要重排已有编号（重排 = 制造冲突）。

### Step 3 — 复制模板并填写

- feature → `docs/specs/_templates/feature.md`
- patch → `docs/specs/_templates/patch.md`
- sunset → `docs/specs/_templates/sunset.md`
- blueprint → `docs/wiki/blue-print/_template-blueprint.md`
- proposal → `docs/specs/_templates/proposal.md`（审阅通过 → 转对应变更类型并登记，驳回 → 保留理由）

> 新建 feature 前，先过模板 §1.1 的**准入四问**（问题-方案匹配 / 范围受控 / 复用优先 / 验收可逆）；
> 写不准的事实填进 §1.2 待确认表并标注，**禁止用猜测填充**（见 conventions C-004）。

### Step 4 — patch 必须建双向指针（硬性）

单向指针会造成语义二义性：只在 patch 说「我改了 X」，读主文档的人不知道；
只在主文档划掉 X，读 patch 的人不知来龙去脉。**两个方向都要建**：

- **Patch → 主文档**：patch 开头声明覆盖范围（目标文件 + 章节 + 原状态）。
- **主文档 → Patch**：在被替代的章节处标注「本段已被 PATCH-NNN 取代 + 链接 + 生效日期」。

并且：**Patch 自身必须可独立阅读**，不依赖读者先读主文档。
这对 AI 尤其友好——从任何文件切入都能拼出「当前生效的真相」，不被过期描述误导。

**Patch 的收敛**（满足条件时执行）：
- 并存期**以 patch 为准**——主文档被取代章节仅作历史
- 时机：合并后稳定 ⟨14⟩ 天无回滚，或同一 feature 下 patch 累积 ≥ ⟨3⟩ 个
- 动作：patch 合入主章节并移除取代标记 → patch 顶部标「已收敛（日期）」、文件保留 → changelog 记一条
- **收敛不是删除 patch 文件**

### Step 5 — sunset 是状态机，不是删除

**禁止 `git rm` 掉旧 spec。** 直接删 = 历史上下文永久丢失，未来排查灰度期线上问题会抓瞎。
sunset 产出的是一份**带状态机的可执行迁移剧本**：评估 → 预告 → 双写/灰度 → 切流 → 观察 → 归档。

### Step 6 — 引用 vendor 作为实证参考源

写技术方案前，扫描 `docs/vendor/` 里是否有相关参考实现：
提取代码模板、API 用法、架构模式，融入方案并**标注来源**。

> 「用户放进 vendor 的代码不一定完整阅读过，这一步帮用户『读』并提炼要点。」

### Step 7 — 自检清单（不通过不许落盘）

- [ ] 变更类型判定正确，文件放对了位置
- [ ] 坐标已登记进站点地图与认领表
- [ ] 验收标准可测试（能量化，不是「体验良好」）
- [ ] 影响面写清：动了哪些模块 / 接口 / 数据 / 配置
- [ ] patch 已建双向指针，且可独立阅读
- [ ] sunset 有状态机与回滚口径
- [ ] 引用了 vendor 的，已标注来源

---

## 模式 B：校验 Spec（提交时）

### 执行步骤

1. 取本次提交涉及的变更文件列表。
2. 反查每个文件在 `docs/specs/` 的归属坐标（查站点地图认领表）。
3. 分类判定：

| 差异类型 | 含义 | 处理 |
|---|---|---|
| 代码超集 | 代码做了 Spec 没写的事 | 提醒补 spec 或说明是临时代码 |
| Spec 超集 | Spec 写了但代码没做 | 提醒排期或降级 Spec |
| 语义冲突 | 两边描述的是同一件事但结论不同 | **重点报警**，交人决策 |
| 无对应 Spec | 改动落在未认领区域 | 提醒认领或归入 blueprint |

4. **输出差异清单，不改任何文件。** 格式：

```
### Git 提交触发：Spec-Code 差异检测（需求澄清）
- [语义冲突] ⟨文件⟩：Spec 说 ⟨A⟩，代码实际 ⟨B⟩
- [代码超集] ⟨文件⟩：新增了 ⟨C⟩，Spec 未覆盖
→ 以上请人工确认：更新 Spec / 回退代码 / 记录为有意偏离（附理由）
```

5. 若用户确认「这是更好的方案」→ 走模式 A 建立 patch 或更新 feature，并建双向指针。

### 禁止事项

- ❌ 自动把 Spec 改成和代码一致
- ❌ 因为「赶时间」跳过差异检测
- ❌ 把差异清单只写在对话里而不落盘（落 `docs/changelog/` 或对应 spec 的备注区）

---

## 与其他 Skill 的协作

- `collar-changelog`：差异清单的结论同步进时间线
- `collar-runbook`：反复出现的偏离类型沉淀成强约定
- `collar-vendor`：写技术方案时的实证参考源
- `collar-wiki`：blueprint 成熟后由本 Skill 接收「毕业」，迁入 specs 成为 feature

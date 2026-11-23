---
name: collar-specs
description: 管理 docs/specs 正式规格（意图源）与 Spec-Code 差异校验。适用于 Standard/Major 改动：新建精简 feature、并行写 patch（双向指针 + Delta）、下线 sunset，或在提交前检查代码是否偏离既有 Spec（只报不改）。不适用于：Minor 小改动/普通 bugfix/纯文案样式调整（直接改代码即可，无需建 spec）；也不要用于前期未定型调研（去 collar-wiki）。当用户说「写个 spec」「这个新功能怎么做」「建个 patch」「XX 下线」「检查 spec 差异」时使用。
agent_created: true
argument-hint: ⟨feature|patch|sunset|proposal⟩ ⟨功能名⟩
---

# collar-specs — Spec 意图源与差异校验

## 核心哲学

1. **轻文档、重契约**：Minor 小改动免写 spec；Standard / Major 改动只写核心 4 节精简 `spec.md`（~30 行），`tests.md` 按需可选。
2. **Spec 不自动反向更新**：代码偏离 Spec 可能是编码时发现了更优方案，提交时**只输出差异清单交人决策**。

## 触发与路由

| 场景 | 模式 | 说明 |
|---|---|---|
| 新功能 / 契约或接口改动 / 建 patch / 下线 | **模式 A：写 Spec** | 仅 Standard / Major 触发；Minor 跳过 |
| Standard / Major 提交前核对既有 Spec | **模式 B：校验 Spec** | 只输出差异清单，不改任何文件 |
| 需要写 `patch` / `sunset` / `proposal` 或执行收敛 | 按需读取 | 读 [references/delta-and-lifecycle.md](references/delta-and-lifecycle.md) |

---

## 模式 A：写 Spec（极简主流程）

1. **先查证再澄清**：先读相关代码、既有 spec 与 ADR；仅针对会实质改变范围/契约/验收的缺口提问（一次聚焦关键问题，附推荐项）；写不准的进待确认表，禁止猜测填充。
2. **选类型与建文件**：
   - 未定型预研 → 转 `collar-wiki`（`docs/wiki/blue-print/`），不进 specs。
   - 定型变更 → 优先跑脚本自动编号：
     `sh scripts/collar-new.sh <feature|patch|sunset|proposal> <目录> <名>`
     （默认只建 `spec.md`，复杂功能需独立测试表时加 `--with-tests`）。
3. **写精简正文（遵循 `collar.yaml` `authoring.rules`）**：
   - 简单 feature 只填核心 4 节：目标与不做边界 / 契约与影响面 / 编号验收标准 `AC-N`（直接附验证路径或命令）/ 待确认问题。不留空模板表。
   - 写 `patch`、`sunset` 或做收敛时，先读 [references/delta-and-lifecycle.md](references/delta-and-lifecycle.md)。
   - 若 `docs/vendor/` 有相关参考实现，提炼融入方案并标注来源。
4. **落盘自检**：编号 `AC-N` 可判定且不复用；跑 `sh scripts/collar-check.sh` 确认 S2/S3/S5 全绿。

Next: 跑 `sh scripts/collar-status.sh` 看全局在途变更；Standard/Major 提交前进入模式 B。

---

## 模式 B：校验 Spec（只报不改）

1. 获取本次变更文件，反查是否命中 `docs/specs/` 已有功能规格（未命中任何既有 spec 的 Minor 改动直接跳过）。
2. 输出精简差异清单（**不改任何文件**）：

```markdown
### Spec-Code 差异检测

| 维度 | 结果 |
|---|---|
| 语义冲突 (CRITICAL) | ⟨N⟩ 处 |
| 代码超集 / Spec 超集 (WARNING) | ⟨N⟩ 处 |
| 测试覆盖漂移 (WARNING) | ⟨N⟩ 处 |

- [CRITICAL] ⟨文件:行⟩：Spec 说 ⟨A⟩，代码实际 ⟨B⟩ → 建议：更新 Spec / 回退代码 / 记为有意偏离
- [WARNING]  ⟨文件:行⟩：⟨差异⟩ → 建议：⟨补 patch / 补测试 / 确认内部实现⟩
```

- 每条必须附 `文件:行` 与可执行建议；拿不准往轻了报；完全一致则显式输出「Spec-Code 一致，通过」。
- 用户确认「新方案更优」→ 回模式 A 建 `patch` 或更新 `spec.md`。

---

## 护栏

- ❌ 为 Minor 小改动/普通 bugfix 强行新建 spec 或强制建 `tests.md`
- ❌ 模式 B 自动反向修改 `spec.md` 或 `tests.md`
- ❌ 复用或重排已使用的 `AC-N` 编号
- ❌ 用猜测填充写不准的事实（须入待确认表）
- ❌ `git rm` 下线 spec（走 sunset 状态机移入 `_archived/`）

## 协作

- `collar-architecture`：不可逆技术选型转 ADR
- `collar-vendor`：参考实现实证源
- `collar-wiki`：接收成熟蓝图毕业

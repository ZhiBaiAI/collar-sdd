# docs/specs/ — 站点地图（正式规格层）

借鉴站点地图思路：把业务域横向切开，不同人认领不同功能目录物理隔离。
**核心纪律**：Minor 小改动（修 bug / 调文案 / 局部重构）直接改代码，**不必为小改动建 spec**；Standard / Major 改动再落精简规格。

---

## 目录约定

```
docs/specs/
├── README.md                       # 本文件：站点地图 + 规则
├── _templates/                     # 模板（feature / patch / sunset / proposal / tests）
├── _archived/                      # 日落归档区（只进不改，禁止删除）
├── 00_[业务地图]示范域/             # 【模板示范】展示 feature + patch + sunset + blueprint 并存
│   └── 01_核心循环/
│       ├── spec.md                 # feature 主文档
│       ├── tests.md                # 可选伴生测试文档（示范 AC-N 双向对齐）
│       ├── PATCH-001-超时重试.md    # patch（双向指针 + Delta 示范）
│       └── SUNSET-001-V1自建方案.md # sunset 状态机示范
└── NN_[业务地图]XX域/               # ← 你的真实业务域从 NN=⟨01⟩ 起
```

数字前缀保证目录天然有序，不要重排已有编号。冷启运行 `sh scripts/collar-init.sh --yes` 会自动清理 `00_[业务地图]示范域/`。

---

## 变更类型（四种正式类型 + 提案通道）

| 类型 | 什么时候用 | 落盘位置 | 模板 |
|---|---|---|---|
| **feature** | 新功能或稳定功能的正式迭代（Standard/Major） | `NN_[域]/NN_功能/spec.md` | [_templates/feature.md](_templates/feature.md) |
| **patch** | 多人并行改同一个 feature，或对既有 spec 做局部演进 | 同目录 `PATCH-NNN-简述.md` | [_templates/patch.md](_templates/patch.md) |
| **sunset** | 旧功能下线 / 迁移 | 同目录 `SUNSET-NNN-简述.md` | [_templates/sunset.md](_templates/sunset.md) |
| **blueprint** | 前期预研、还没定型 | `../wiki/blue-print/`（不在 specs 里） | [wiki/blue-print/_template-blueprint.md](../wiki/blue-print/_template-blueprint.md) |
| **proposal**（通道） | 无直接合库权限的角色（或大改动提案）提交意图 | 同目录 `PROPOSAL-NNN-简述.md` | [_templates/proposal.md](_templates/proposal.md) |

配套脚本（`scripts/`）：
- `collar-new.sh <feature|patch|sunset|proposal> <目录> <名>`（自动编号；加 `--with-tests` 才生成 `tests.md`）
- `collar-status.sh`（在途 patch/超期告警；`--specs --json` 机器清单）
- `collar-converge.sh <PATCH>`（把 patch §⑥ Delta 机械合并进 `spec.md`）

### `tests.md` 按需可选

- **默认（简单功能）**：直接在 `spec.md` 的每条 `AC-N` 后写验证路径/命令，免建 `tests.md`。
- **按需（复杂功能）**：需要详细测试点表、测试数据与手工验收步骤时，才建伴生 `tests.md`。一旦存在，`collar-check` S3 会自动校验 `spec.md` ↔ `tests.md` 的 `AC-N` 双向对齐。

---

## 认领表（仅记低频归属，不抄路由与进度）

| 业务域 | 模块 | 负责人 | Spec 路径 |
|---|---|---|---|
| ⟨示范域⟩ | ⟨核心循环⟩ | ⟨@谁⟩ | [01_核心循环](00_%5B业务地图%5D示范域/01_核心循环/spec.md) |

---

## 关键规格：Patch 双向指针与 Delta 收敛

1. **双向指针**：Patch 开头写「① 覆盖范围（Patch → 主文档）」，主文档对应章节加「本段已被 PATCH-NNN 取代」标注；Patch 自身可独立阅读。
2. **Delta 四段（§⑥）**：`### ADDED`（`AC-PNNN-N`）/ `### MODIFIED` / `### REMOVED` / `### RENAMED`（`FROM:` 紧跟 `TO: AC-PNNN-N`）。同一 `AC-N` 不跨小节，空小节整节删除（S5 机械校验）。
3. **收敛**：稳定 ⟨14⟩ 天或同 feature 累积 ≥ ⟨3⟩ 个 patch 时跑 `sh scripts/collar-converge.sh <PATCH>` 合并 Delta 并标「已收敛」（保留文件作历史，不删除）。

## 关键规格：Sunset 是状态机，不是删除

下线走 `评估 → 预告 → 双写/灰度 → 切流 → 观察 → 归档`（每步写清回滚口径），完成后将 spec 移入 [`_archived/`](_archived/README.md) 保留历史，禁止 `git rm`。

## 代码 ↔ Spec 差异检查

编码中发现更好方案导致代码偏离 Spec 时，**禁止自动反向修改 Spec**——由 `collar-specs` 输出差异清单交人决策（更新 Spec / 回退代码 / 建 Patch）。

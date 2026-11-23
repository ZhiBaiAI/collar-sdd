# 提交关卡：按改动分级把关

> **核心原则：流程重量匹配改动影响。**
> 小改动零文档阻塞，大改动有迹可循；能机械拦截的交脚本，需人判断的只报不代决。

---

## 1. 三档改动分级（快慢通道）

| 档位 | 适用范围 | 必须跑的技术门禁 | 语义 / 文档动作 |
|---|---|---|---|
| **Minor（小改）** | 修小 bug、调文案/样式、局部内部重构（不改外部契约） | `fast` 关联验证 + `pre-commit`（`collar-check` + `collar-boundary` + `commit` 档质量门禁） | **免写 spec、免写 changelog、免走 3-Skill 仪式**；写清规范 commit message 即可 |
| **Standard（常规）** | 新功能、改接口/数据字段/核心业务逻辑 | 同上 | 写精简 `spec.md`（或 `patch`）+ 对应测试；提交前做 Spec-Code 差异检查（只报不改） |
| **Major（架构）** | 改架构、数据模型、权限边界、跨模块协议或外置逻辑 | 同上 + 合并前跑 `release` 档全量验证 | 先评审 Spec / ADR 再动代码；确认外置逻辑已缝补；`BREAKING` 变更记录迁移方式 |

> 避免「一刀切」：如果日常改 1 行 bug 也要手填 7 步清单与月度 changelog，团队必然滑向 `--no-verify` 或机械打卡。

---

## 2. 技术拦截（自动执行，无需靠自觉）

`scripts/hooks/` 随模板自带，冷启跑 `sh scripts/collar-init.sh --yes` 或 `sh scripts/collar-hooks.sh` 即可装配（通过 `core.hooksPath` 版本化共享）：

| 钩子 | 执行内容 | 失败后果 |
|---|---|---|
| `scripts/hooks/pre-commit` | ① `collar-check.sh`（S0–S8 结构与卫生门禁）<br>② `collar-boundary.sh`（`collar.yaml` `default: deny` + `allow_write`/`deny_write` 真实拦截）<br>③ `collar.yaml` 中 `stage: commit` 的质量门禁（仍是 `⟨占位符⟩` 自动跳过） | **直接拦截提交** |
| `scripts/hooks/commit-msg` | 校验首行符合 `<类型>(<范围>): <说明>`（`WIP` 开头豁免），让 `git log` 直接充当准确的时间线 | **直接拦截提交** |
| `scripts/hooks/post-commit` | 仅检测到 `BREAKING`（如 `feat!:`）时提示记录迁移方式，不打扰日常提交 | 提示 |
| `scripts/hooks/pre-push` | 复跑 `collar-check.sh` + 提醒 Standard/Major 语义自查 | 门禁失败拦截 |

装配与检查命令：

```bash
sh scripts/collar-hooks.sh           # 装配
sh scripts/collar-hooks.sh --check   # 校验装配状态
sh scripts/collar-hooks.sh --remove  # 恢复默认 .git/hooks
```

CI 兜底：[.github/workflows/collar-check.yml](../../.github/workflows/collar-check.yml) 在 PR/push 时复跑 `collar-check.sh` 与 `collar-boundary.sh`。

---

## 3. Standard / Major 语义检查（Agent 协助、人做决策）

### 3.1 Spec-Code 差异清单（`collar-specs` 模式 B）

改动触及已有业务规格时输出，**禁止自动反向修改 Spec**：

```markdown
### Spec-Code 差异检测

- [语义冲突] ⟨文件:行⟩：Spec 说 ⟨A⟩，代码实际 ⟨B⟩ → 建议：更新 Spec / 回退代码 / 记为有意偏离
- [代码超集] ⟨文件:行⟩：新增了 ⟨C⟩，Spec 未覆盖 → 建议：补 patch 或确认属内部实现
- [Spec 超集] ⟨文件:行⟩：Spec 要求 ⟨D⟩，代码未实现 → 建议：补齐或调整排期
```

### 3.2 知识沉淀触发门槛（不强制每次写）

- **Changelog**：日常靠 `commit-msg` 规范，需要发版或阶段回顾时跑 `sh scripts/collar-changelog.sh` 一键生成；仅 `BREAKING` 或里程碑需手补迁移说明。
- **Runbook**：只在**重复踩坑**或**确立新工程红线**时写一条（单次偶发问题修完即可，不往 `conventions.md` 堆噪音）。
- **Context Stitching**：仅当把提示词/配置/脚本挪出代码时检查，见 [context-stitching.md](context-stitching.md)。

---

## 4. 绕过规则与升级信号

- **允许绕过（`--no-verify`）**：仅限 `WIP` 临时提交与纯文档 typo；涉及接口签名、数据字段、共享配置与安全边界禁止绕过。
- **升级为哨兵机信号**：多人并行分支变多、出现「各自分支全绿、合并预发后才炸」的隐形冲突时，参考 [[讨论稿]哨兵机](../wiki/blue-print/%5B讨论稿%5D哨兵机.md) 与 [ADR-0001](../architecture/ADR/0001-冲突检测介入时机.md)。

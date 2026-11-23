# docs/changelog/ — 变更时间线（按需模块）

**回答：这个项目在关键节点变成了什么样。**

> **轻量化原则**：日常提交只需遵守 `commit-msg` 的 Conventional Commits 格式（`<类型>(<范围>): <说明>`），
> **不再要求每次 commit 手写月度 Markdown 文件**。需要阶段回顾或发版说明时，运行脚本从 `git log` 一键提取：
>
> ```bash
> sh scripts/collar-changelog.sh                    # 最近 30 条分组摘要
> sh scripts/collar-changelog.sh --since 2026-11-01 # 指定起始日期
> sh scripts/collar-changelog.sh v1.0.0..HEAD       # 指定版本区间
> ```

---

## 何时显式落盘

- **发版里程碑**：把 `collar-changelog.sh` 生成的摘要整理进 `docs/changelog/YYYY/YYYY-MM.md` 或根目录 `CHANGELOG.md`。
- **`BREAKING` 破坏性变更**：在 commit message 加 `!`（如 `feat(api)!: ...`），并在变更记录里置顶写明迁移方式。
- **阶段回顾**：顺带做一次知识库卫生检查——合并/退役长期未命中的约定（保持 `conventions.md` ≤15 条）、归档已失效的 ADR。

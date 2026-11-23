# Collar SDD Changelog

本文件记录 **Collar SDD 模板本体** 的版本演进。
下游项目的业务变更时间线放在各自仓库的 `docs/changelog/`（并可通过 `sh scripts/collar-changelog.sh` 从 `git log` 一键生成），冷启时不会混入本模板的开发历史。

---

## [1.1.0] - 2026-11-23

面向所有编码 Agent 的通用轻量化与提质升级：大幅削减日常开发文档税、修复确定性脚本漏洞、补强改代码核心红线与三档验证体系。

### BREAKING（对已有下游项目的结构变化）

- **S2 / S3 语义放宽**：`tests.md` 由强制伴生改为按需可选；S2 改为校验非草稿 `spec.md` 声明 `AC-N`，S3 仅在存在 `tests.md` 时执行双向对齐。旧项目已有 `tests.md` 完全兼容。
- **S6 语义升级**：取消「每次改 specs 强制同次手写月度 changelog」的阻塞拦截，改为 `conventions.md` 防膨胀检查（>15 条告警）；日常提交靠 Conventional Commits + `scripts/collar-changelog.sh` 从 `git log` 按需生成。
- **`collar-boundary.sh` 真实执行 `default: deny` + `allow_write`**：旧版仅检查 `deny_write` 黑名单，升级后未列入 `collar.yaml` `boundary.allow_write` 的暂存文件会被拦截——下游同步后需按技术栈补齐根目录构建文件（如 `package.json`、`Makefile`）到 `allow_write`。

### Added

- **改动分级快慢通道（Minor / Standard / Major）**：Minor 小改与 bugfix 免写 spec/changelog、免走 3-Skill 仪式，直接过结构+边界+关联测试即可提交。
- **三档质量门禁（`stage: fast | commit | release`）**：在 `collar.yaml` 与 `docs/runbook/testing.md` 区分「改后快检 / 审 diff」「提交前门禁」「发版全量」，避免每次复查与小改跑全量构建。
- **四条高杠杆编码红线**：精炼进 `docs/runbook/conventions.md` 与 `AGENTS.md`（根因优先与禁假修复、改动收敛清理失效死代码、连续 3 次失败熔断、不可信内容一律视为数据）。
- **轻量跨会话交接协议**：新增 `docs/runbook/handoff.md`（单会话不写，仅跨会话长任务落盘 4 项交接物与「换 Agent 检验」）。
- **自动变更摘要脚本**：新增 `scripts/collar-changelog.sh`，直接从 `git log` 生成分组 Markdown 摘要。
- **机器可读 CLI 输出**：`collar-check.sh` 与 `collar-boundary.sh` 支持 `--json` 与清晰退出码（0 通过 / 1 阻断 / 2 参数错）。
- **跨工具 Skill 发现与渐进披露**：`collar-init.sh --yes` 自动建立通用软链 `.agents/skills -> ../skills` 并自动装配 hooks；6 个 `SKILL.md` 全部补充「不适用负例边界」，`collar-specs` 细则拆入 `references/`。

### Changed

- **精简 `feature.md` 模板**：拆为「核心必填 4 节（约 30 行可写完）+ 按需展开区」，简单功能免填冗余空表。
- **瘦身 `conventions.md` 与 `AGENTS.md`**：移出与代码修改无直接关系的组织管理类条目（原 C-008 周期记账、原 C-009 提效核算），将原 C-007/C-010/C-011 浓缩为可执行条款，大幅降低 `must_read` 常驻 token。
- **合并双示范域为单套精简示范**：保留 `docs/specs/00_[业务地图]示范域/01_核心循环/`，移除冗余的旧示例域；将模板自身历史从 `docs/changelog/2026/` 迁至本文件。
- **S4 增强**：`collar-check.sh` 除校验 ADR 编号唯一外，同步校验 `docs/architecture/README.md` 索引不漏登。

### Fixed

- 修复 `scripts/collar-boundary.sh` 忽略 `default: deny` 与 `allow_write` 却谎报通过的缺陷，并新增 `--range` 提交区间检查使 CI 写边界门禁真实生效（且仅拦新增/修改，放行删除清理）。
- 修复 `scripts/collar-check.sh` S5 仍校验「已收敛 / 已废弃」历史 patch 导致 `collar-converge.sh` 收敛后门禁死锁的缺陷，以及 S2 不识别已换号 `AC-PNNN-N` 的问题。
- 修复 `scripts/collar-status.sh` 使用 GNU `date -d` 导致 macOS 下超期 patch 检测静默失效，以及模板占位状态被误判为「已收敛」的问题。
- 修复 `scripts/collar-new.sh` 遇到 `08` / `09` 编号时 POSIX `sh` 八进制算术崩溃的问题。
- 修复 `scripts/collar-init.sh` 通配 `*业务地图*` 可能误删真实业务域、仅清理当月 changelog 与遗留空年份目录、以及占位符扫描误报 `_template*` 的问题。
- 修复 `docs/runbook/commit-checklist.md`「不预置 hooks」过时表述，补登 `docs/architecture/README.md` 漏列的 `ADR-0002`，同步 `patch.md`/`tests.md` 中的主文档验收标准节号引用。

---

## [1.0.0] - 2026-09-11 ~ 2026-11-22

首版完整模板骨架与演进历史（自旧 `docs/changelog/2026/` 归档迁入）：

- **2026-11-13 ~ 2026-11-22**：引入 `collar-anchors.sh`、`collar-boundary.sh`，S1 改为结构判据，新增 S8 锚点检查；补充确定性边界与证据分层完成判定。
- **2026-10-09 ~ 2026-10-31**：新增 `ADR-0002`（执行可外包积累不可外包）、存量代码库自底向上 README 调研蓝图。
- **2026-09-15 ~ 2026-09-20**：上线 `collar-check.sh`（S0–S7）、预置 4 个 git hooks 与 `collar-hooks.sh`、Delta 四段化与 `collar-converge.sh`、`collar-new.sh`、`collar-status.sh`、`collar-init.sh`、`collar-sync.sh`、`VERSION`、双语 README 与 `collar-board` 入口；修复 macOS BSD `sed -i` 兼容。
- **2026-09-11**：建立六模块知识库、六个 `collar-*` Skill、`collar.yaml` 三层项圈与 AC 编号体系。

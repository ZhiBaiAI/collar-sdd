# docs/runbook/ — 过程知识与工程红线

**回答：这个项目有哪些改代码必守的红线、验证怎么分层、踩过什么坑。**

---

## 内容分区

| 文件 | 装什么 | 加载方式 |
|---|---|---|
| [conventions.md](conventions.md) | **高密度编码红线**（严控 ≤15 条，超限 S6 告警） | `must_read`（每次必读） |
| [testing.md](testing.md) | **三档验证节奏**（`fast` / `commit` / `release`）与测试口径 | 按需 |
| [commit-gate.md](commit-gate.md) | **分级提交关卡**（Minor / Standard / Major 与 git hooks） | 按需 |
| [commit-checklist.md](commit-checklist.md) | **按档提交自查表** | 按需 |
| [handoff.md](handoff.md) | **跨会话长任务交接协议**（仅跨会话使用，单会话不写） | 按需 |
| [environments.md](environments.md) | **环境差异**（本地 / 预发 / 线上隐藏地形） | 按需 |
| [troubleshooting.md](troubleshooting.md) | **排障剧本**（现象 → 根因 → 解法） | 按需 |
| [context-stitching.md](context-stitching.md) | **上下文缝补协议**（外置逻辑必须补 MCP 或 `//!` 锚点） | 按需 |
| [anchor-registry.md](anchor-registry.md) | **锚点登记册**（由 `collar-anchors.sh` 自动生成，勿手填） | 自动产物 |
| [_template-stitching-skill.md](_template-stitching-skill.md) | **MCP 配套 Skill 模板** | 模板 |

---

## 沉淀纪律（防膨胀）

- **单次偶然踩坑不入规**：修完即可；只有**反复踩坑**或**保护关键边界**才写入 `conventions.md` 或 `troubleshooting.md`。
- **四段式条目**：现象 / 根因 / 结论 / 证据（缺「结论」不入库）。
- **定期退役**：超过 15 条约定触发 `collar-check` S6 告警，合并同类项或移除长期无命中条目。
- **守卫入口地图**：`AGENTS.md` 结构由 `collar-check` S1 自动校验，不堆长段落和大段命令。

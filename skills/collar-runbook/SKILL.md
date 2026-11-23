---
name: collar-runbook
description: 维护 docs/runbook 过程知识（编码红线 conventions.md、环境差异 environments.md、排障剧本 troubleshooting.md、三档验证 testing.md 与跨会话交接 handoff.md），兼守卫 AGENTS.md 入口精简。适用于反复踩过的坑、新确立的编码红线、环境差异排查或 AGENTS.md 瘦身。不适用于：单次偶发 bug（修完即可，不入规）、通用行业科普文章（不属本项目运行手册）或普通功能需求（去 collar-specs）。当用户说「记住这个坑」「立个约定」「预发和线上不一致」「AGENTS.md 太长了」时使用。
agent_created: true
argument-hint: ⟨主题 / 报错 / 约定⟩
---

# collar-runbook — 工程红线沉淀与入口守卫

## 定位

只沉淀**会改变后续改代码行为的高信号过程知识**。单次偶发问题先修复、不入规；重复踩坑或保护关键边界才入库。

## 落盘分流

| 类型 | 去哪 | 准入门槛 |
|---|---|---|
| **高密度编码红线** | `docs/runbook/conventions.md` | 重复踩坑或关键边界；全文件严控 ≤15 条（超限 S6 告警合并/退役） |
| **环境差异** | `docs/runbook/environments.md` | 本地 / 预发 / 线上的配置、缓存、开关差异 |
| **排障剧本** | `docs/runbook/troubleshooting.md` | 反复出现的故障（现象 → 根因 → 解法 → 证据） |
| **验证与测试口径** | `docs/runbook/testing.md` | 三档验证（`fast`/`commit`/`release`）与跨功能点测试规则 |
| **跨会话交接** | `docs/runbook/handoff.md` | 仅跨会话长任务按模板写临时书签，单会话不写 |

条目采用四段式（现象 / 根因 / 结论 / 证据），**无明确可执行结论不入库**。

## 入口守卫职责

1. `AGENTS.md` 只放导航、分级规则、快速命令与核心红线速查（一句话 + 链接），细节一律迁入 `docs/`。
2. 每次改完 `AGENTS.md` 或 `conventions.md`，跑 `sh scripts/collar-check.sh` 确认 S1（结构合规）、S6（约定数量 ≤15）、S7（无会话指代词）通过。

## 护栏

- ❌ 单次偶发坑直接加进全局 `conventions.md`（导致常驻上下文膨胀）
- ❌ 把行业科普或组织管理长文塞进 `conventions.md`
- ❌ 没有可执行结论的流水账入库
- ❌ 同类坑重复记录而不合并；现状文档写过去时或会话指代词

Next: 沉淀完跑 `sh scripts/collar-check.sh`；架构级决策转 `collar-architecture`。

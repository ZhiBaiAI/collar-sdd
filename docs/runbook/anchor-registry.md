# 上下文锚点登记册（自动生成）

> **凡是「逻辑离开了代码」的地方，都必须在代码里写 `//!` 锚点注释。**
> 登记册由 `sh scripts/collar-anchors.sh` 从这些注释**自动生成**——你写注释，表格自己长出来。
> 未写锚点 = 未缝补 = AI 的上下文有个洞，它会在关键决策上误判。

配套协议见 [context-stitching.md](context-stitching.md)。

**维护方式：** 不要手改下表。改脚本头部的 `//!` 注释，然后重跑 `sh scripts/collar-anchors.sh`；
`collar-check` 的 S8 会校验锚点字段是否齐全（name / risk / owner 必填）。

---

## 怎么写锚点（人和 AI 都只做这一步）

外置逻辑时，在脚本/源码**头部**加一段 `//!` 注释；其余由脚本生成：

```text
//! name: ⟨脚本名⟩
//! risk: ⟨low|medium|high⟩
//! params: ⟨参数名:类型:含义⟩
//! env: ⟨dev|pre|prod⟩
//! owner: ⟨@谁⟩
```

name / risk / owner 三项必填（S8 会拦），params 与 env 可留空。
在脚本引擎眼里这是普通注释，对平台是元数据 —— **代码即锚点**。

---

## 登记册

> 本表由 `sh scripts/collar-anchors.sh` 从代码中的 `//!` 锚点注释自动生成。
> **不要手改**——改代码里的锚点注释，然后重跑脚本。

| 脚本名 | 文件 | 风险 | 参数 | 环境 | 责任人 |
|---|---|---|---|---|---|
| （暂无） | | | | | |
---

## 缝补方式速查

| 场景 | 缝补方式 | 模板 |
|---|---|---|
| 动态提示词 / 动态配置外置到平台或 DB | 只读 MCP 通道 + 配套 Skill | [_template-stitching-skill.md](_template-stitching-skill.md) |
| 逻辑外置到脚本平台 | `//!` 声明式注释保留锚点 | 见下 |
| 预发 / 线上环境差异 | AGENTS.md 显式声明 + ADR | [environments.md](environments.md) |

### `//!` 锚点注释写法

```
//! name: ⟨脚本名⟩
//! risk: ⟨low|medium|high⟩
//! params: ⟨参数名:类型:含义⟩
//! env: ⟨可执行环境: dev|pre|prod⟩
//! owner: ⟨@谁⟩
```

在脚本引擎眼里是普通注释，对平台却是元数据 —— **代码即锚点**。
即便逻辑外置到了平台，AI 读脚本源码仍知道：叫什么、风险几何、参数是什么、能在哪跑。

---

## 审计

- `collar-check` S8 自动校验锚点字段齐全（name / risk / owner）
- `collar-anchors.sh` 重跑即刷新表格，因此「登记册与代码不一致」这种状态不会存在
- 内部基础设施脚本（collar-check / init / new / status / converge / sync / hooks）不要求锚点

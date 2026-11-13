#!/usr/bin/env sh
# collar-anchors.sh — 锚点登记册生成器（确定性，无人工维护）
#
# 契约声明在 collar.yaml 的 validation.gates；本脚本是执行体之一。
#
# 为什么需要它：
#   原先 anchor-registry.md 靠人手动追加表格行——人一忙就漏，漏了就等于
#   「外置了逻辑但没缝补」。更麻烦的是手填内容无法验证是否与代码一致。
#   本脚本改为从代码里的 `//!` 锚点注释反向生成登记册，做到：
#     ① 锚点是唯一事实来源（代码即锚点，与 P-001 原则一致）
#     ② 登记册是产出物，不是维护对象——人只写注释，不写表格
#     ③ 未写锚点的外置脚本会被识别为「疑似未缝补」并报出
#
# 用法：
#   sh scripts/collar-anchors.sh            # 生成/刷新 anchor-registry.md 的「登记册」表
#   sh scripts/collar-anchors.sh --check    # 只校验，不改文件（供门禁使用）
#
# 退出码：0 = 登记册与代码一致；1 = 存在未登记/格式错误（仅 --check）

set -u
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT" || exit 1

MODE="${1:-write}"
REG="docs/runbook/anchor-registry.md"

# 扫描范围：src/ 与 scripts/ 下所有文本类文件（锚点注释通常写在脚本/源码里）
# 跳过本脚本自身与 hooks（它们不是「外置逻辑」）
CANDIDATES=$(find src scripts -type f \
  \( -name '*.ts' -o -name '*.js' -o -name '*.py' -o -name '*.sh' -o -name '*.go' -o -name '*.java' -o -name '*.kt' -o -name '*.sql' \) \
  ! -name 'collar-anchors.sh' ! -path 'scripts/hooks/*' \
  ! -name 'collar-check.sh' ! -name 'collar-init.sh' ! -name 'collar-new.sh' \
  ! -name 'collar-status.sh' ! -name 'collar-converge.sh' ! -name 'collar-sync.sh' \
  ! -name 'collar-hooks.sh' 2>/dev/null | sort)

# 从文件头部（前 30 行）提取 //! 锚点块
extract_field() {
  # $1=file $2=field
  sed -n '1,30p' "$1" 2>/dev/null | sed -n "s|^[[:space:]]*//![[:space:]]*$2:[[:space:]]*||p" | head -1
}

HAS_ANCHOR=""
NO_ANCHOR=""
ROWS=""

while IFS= read -r F; do
  [ -n "$F" ] || continue
  NAME=$(extract_field "$F" "name")
  if [ -z "$NAME" ]; then
    # 不含锚点：可能是内部脚本（正常）或外置了逻辑却没锚点（问题）
    NO_ANCHOR="${NO_ANCHOR}${F}
"
    continue
  fi
  HAS_ANCHOR="${HAS_ANCHOR}${F}
"
  RISK=$(extract_field "$F" "risk")
  PARAMS=$(extract_field "$F" "params")
  ENVS=$(extract_field "$F" "env")
  OWNER=$(extract_field "$F" "owner")
  ROWS="${ROWS}| \`${NAME}\` | ${F} | risk=${RISK:--} | ${PARAMS:--} | ${ENVS:--} | ${OWNER:--} |
"
done <<EOF
${CANDIDATES}
EOF

# ---- --check：只比对，不改文件 ----
if [ "$MODE" = "--check" ]; then
  if [ -z "$ROWS" ] && [ -z "$NO_ANCHOR" ]; then
    echo "ok   anchor: 无可扫描的脚本（尚无外置逻辑）"
    exit 0
  fi
  # 校验：每个锚点块必须含 name/risk/owner 三个字段
  BAD=""
  while IFS= read -r F; do
    [ -n "$F" ] || continue
    for F2 in name risk owner; do
      [ -n "$(extract_field "$F" "$F2")" ] || BAD="${BAD} ${F}(${F2})"
    done
  done <<EOF
${HAS_ANCHOR}
EOF
  if [ -n "$BAD" ]; then
    echo "FAIL anchor: 锚点字段不全${BAD}"
    echo "  修法：补齐 //! name / risk / owner 三行（见 context-stitching.md）"
    exit 1
  fi
  CNT=$(printf '%s' "$HAS_ANCHOR" | grep -c '[^[:space:]]' 2>/dev/null || true)
  echo "ok   anchor: 登记表可由代码生成（${CNT:-0} 个带锚点文件）"
  exit 0
fi

# ---- write：重写 anchor-registry.md 的登记册区块 ----
[ -f "$REG" ] || { echo "FAIL 找不到 ${REG}"; exit 1; }

TMP=$(mktemp)
ROWFILE=$(mktemp)
trap 'rm -f "$TMP" "$ROWFILE"' EXIT
printf '%s' "$ROWS" > "$ROWFILE"

awk -v rowfile="$ROWFILE" '
  function emit_rows(   line, any) {
    any = 0
    while ((getline line < rowfile) > 0) {
      if (line ~ /[^[:space:]]/) { print line; any = 1 }
    }
    close(rowfile)
    if (!any) print "| （暂无） | | | | | |"
  }
  BEGIN { inreg=0 }
  /^## 登记册/ {
    print
    print ""
    print "> 本表由 `sh scripts/collar-anchors.sh` 从代码中的 `//!` 锚点注释自动生成。"
    print "> **不要手改**——改代码里的锚点注释，然后重跑脚本。"
    print ""
    print "| 脚本名 | 文件 | 风险 | 参数 | 环境 | 责任人 |"
    print "|---|---|---|---|---|---|"
    emit_rows()
    inreg=1
    next
  }
  inreg && /^## / { inreg=0 }
  inreg { next }
  { print }
' "$REG" > "$TMP"

mv "$TMP" "$REG"
trap - EXIT

N=$(printf '%s' "$HAS_ANCHOR" | grep -c '[^[:space:]]' 2>/dev/null || true)
N=${N:-0}
echo "ok   已刷新 ${REG} 登记册：${N} 个带锚点脚本"
if [ -n "$NO_ANCHOR" ]; then
  echo "warn 以下脚本无 //! 锚点（若其中有外置逻辑，需补锚点）："
  echo "$NO_ANCHOR" | sed 's/^/     /'
fi

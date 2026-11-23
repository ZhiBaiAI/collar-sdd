#!/usr/bin/env sh
# collar-check.sh — 结构门禁（语言无关，只依赖 POSIX sh + grep/find/sed/awk/wc）
#
# 契约声明在 collar.yaml 的 validation.gates；本脚本是结构门禁的执行体，
# 检查知识库与规范的机械不变量，复制模板即生效。
#
# 用法：
#   sh scripts/collar-check.sh          # 人类可读输出
#   sh scripts/collar-check.sh --json   # 机器可读 JSON 输出
#
# 退出码：0 = 全部通过；1 = 有失败项；2 = 参数错误

set -u

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT" || exit 1

JSON=0
for ARG in "$@"; do
  case "$ARG" in
    --json) JSON=1 ;;
    *)
      printf 'ERR  未知参数：%s（可选 --json）\n' "$ARG" >&2
      exit 2
      ;;
  esac
done

FAIL=0
CHECKS_JSON=""
FIRST_C=1

json_esc() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' '
}

record_json() {
  STATUS="$1"; ITEM="$2"; DETAIL="$3"
  [ "$FIRST_C" -eq 1 ] || CHECKS_JSON="${CHECKS_JSON},"
  FIRST_C=0
  CHECKS_JSON="${CHECKS_JSON}{\"status\":\"$(json_esc "$STATUS")\",\"item\":\"$(json_esc "$ITEM")\",\"detail\":\"$(json_esc "$DETAIL")\"}"
}

note() { [ "$JSON" -eq 1 ] || printf '  %s\n' "$1"; }
fail() {
  FAIL=1
  record_json "fail" "$1" "$2"
  if [ "$JSON" -eq 0 ]; then
    printf 'FAIL %s\n' "$1"
    note "修法：$2"
  fi
}
pass() {
  record_json "ok" "$1" ""
  [ "$JSON" -eq 1 ] || printf 'ok   %s\n' "$1"
}
warn() {
  record_json "warn" "$1" "$2"
  if [ "$JSON" -eq 0 ]; then
    printf 'warn %s\n' "$1"
    note "提示：$2"
  fi
}

if [ "$JSON" -eq 0 ]; then
  echo "collar-check — 结构门禁"
  echo "repo: $ROOT"
  echo
fi

# ---------------------------------------------------------------------------
# S0 核心结构存在性：骨架文件缺失时其余检查失去意义，先拦
#    changelog / vendor / wiki 属按需目录，不强制空项目建空壳
# ---------------------------------------------------------------------------
S0_BROKEN=0
for REQUIRED in AGENTS.md collar.yaml VERSION docs/README.md docs/specs/README.md \
                docs/runbook/commit-gate.md docs/runbook/conventions.md \
                docs/architecture/README.md scripts/collar-check.sh; do
  if [ ! -f "$REQUIRED" ]; then
    S0_BROKEN=1
    fail "S0 核心文件缺失" "${REQUIRED} 不存在——恢复该文件（模板原样或从 git 历史找回）"
  fi
done
for REQUIRED_DIR in docs/specs docs/runbook docs/architecture; do
  if [ ! -d "$REQUIRED_DIR" ]; then
    S0_BROKEN=1
    fail "S0 核心目录缺失" "${REQUIRED_DIR}/ 不存在——恢复该目录"
  fi
done
[ "$S0_BROKEN" -eq 0 ] && pass "S0 模板骨架完整（核心文件与目录齐全）"

# ---------------------------------------------------------------------------
# S1 入口地图结构：AGENTS.md 只做导航，不做解释
#    ① 必有「仓库地图」与「知识库」两节
#    ② 代码块总行数不得占全文一半以上
#    ③ 单行不超过 400 字符
#    行数 >150 仅提示告警，不硬失败
# ---------------------------------------------------------------------------
S1_BROKEN=0

for SEC in "仓库地图" "知识库"; do
  grep -q "^## .*${SEC}" AGENTS.md 2>/dev/null || {
    fail "S1 缺少入口必备小节：${SEC}" "入口必须包含该节（只放一行摘要 + 链接）"
    S1_BROKEN=1
  }
done

TOTAL_LINES=$(wc -l < AGENTS.md | tr -d ' ')
BLOCK_LINES=$(awk '/^```/{f=!f; next} f{n++} END{print n+0}' AGENTS.md)
if [ "$TOTAL_LINES" -gt 0 ]; then
  PCT=$((BLOCK_LINES * 100 / TOTAL_LINES))
  if [ "$PCT" -ge 50 ]; then
    fail "S1 代码块占比 ${PCT}% (≥50%)" \
         "入口是导航不是手册——命令只留一行、细节链接到 docs/"
    S1_BROKEN=1
  fi
fi

LONG_LINES=$(awk 'length($0) > 400 {c++} END{print c+0}' AGENTS.md)
if [ "$LONG_LINES" -gt 0 ]; then
  fail "S1 有 ${LONG_LINES} 行超过 400 字符" "长段落说明在写解释而非导航，迁到 docs/"
  S1_BROKEN=1
fi

if [ "$S1_BROKEN" -eq 0 ]; then
  pass "S1 入口结构合规（导航两节齐全 / 代码块 ${PCT:-0}% / 无超长行 / ${TOTAL_LINES} 行）"
  [ "$TOTAL_LINES" -gt 150 ] && \
    warn "S1 AGENTS.md 已 ${TOTAL_LINES} 行 (>150 提示线)" "考虑把细节下沉到 docs/，保持入口可一屏扫读"
fi

# ---------------------------------------------------------------------------
# S2 spec 验收标准编号：非草稿 spec.md 必须至少声明一条 AC-N
#    tests.md 改为可选伴生文档（不再强制一功能两文档，简单功能在 spec 内联验证映射即可）
# ---------------------------------------------------------------------------
S2_BROKEN=0
while IFS= read -r SPEC; do
  [ -n "${SPEC}" ] || continue
  # 草稿态允许尚未写全 AC
  if grep -qE '^\| *状态 *\| *草稿' "${SPEC}" 2>/dev/null; then
    continue
  fi
  if ! grep -qE '`AC-(P[0-9]+-)?[0-9]+`' "${SPEC}" 2>/dev/null; then
    S2_BROKEN=1
    fail "S2 ${SPEC}" "非草稿 spec 缺少编号验收标准 \`AC-N\`——至少声明一条可判定验收标准（或把状态标为草稿）"
  fi
done <<FINDLIST
$(find docs/specs -name spec.md -not -path '*/_templates/*' -not -path '*/_archived/*')
FINDLIST
[ "$S2_BROKEN" -eq 0 ] && pass "S2 所有非草稿 spec.md 均声明编号验收标准 AC-N（tests.md 按需可选）"

# ---------------------------------------------------------------------------
# S3 AC 双向对齐：当功能点目录存在 tests.md 时，spec 的 AC-N 与 tests/patch 必须互相对齐
# ---------------------------------------------------------------------------
S3_BROKEN=0
S3_CHECKED=0
while IFS= read -r PAIR_DIR; do
  [ -n "${PAIR_DIR}" ] || continue
  [ -f "${PAIR_DIR}/tests.md" ] || continue
  S3_CHECKED=$((S3_CHECKED + 1))
  SPEC_AC=$(grep -o 'AC-[0-9][0-9]*' "${PAIR_DIR}/spec.md" 2>/dev/null | sort -u | tr '\n' ' ')
  TESTS_AC=$(grep -oh 'AC-[0-9][0-9]*' "${PAIR_DIR}/tests.md" "${PAIR_DIR}"/PATCH-*.md 2>/dev/null | sort -u | tr '\n' ',')
  SPEC_AC_CSV=$(printf '%s' "${SPEC_AC}" | tr ' ' ',')
  for AC in ${SPEC_AC}; do
    case ",${TESTS_AC}," in
      *",${AC},"*) ;;
      *) S3_BROKEN=1; fail "S3 ${PAIR_DIR}" "spec 声明了 ${AC}，但 tests.md（含 patch）没有测试点回指它 → 补测试点或登记缺口" ;;
    esac
  done
  TESTS_AC_SP=$(printf '%s' "${TESTS_AC}" | tr ',' ' ')
  for AC in ${TESTS_AC_SP}; do
    [ -n "${AC}" ] || continue
    case ",${SPEC_AC_CSV}," in
      *",${AC},"*) ;;
      *) S3_BROKEN=1; fail "S3 ${PAIR_DIR}" "tests.md/patch 引用了 ${AC}，但 spec.md 没有这条编号 → 补 AC 或修正编号" ;;
    esac
  done
done <<FINDLIST
$(find docs/specs -name spec.md -not -path '*/_templates/*' -not -path '*/_archived/*' -exec dirname {} \;)
FINDLIST
if [ "$S3_BROKEN" -eq 0 ]; then
  if [ "$S3_CHECKED" -gt 0 ]; then
    pass "S3 AC-N 双向对齐（已校验 ${S3_CHECKED} 个含 tests.md 的功能点）"
  else
    pass "S3 AC-N 双向对齐（无伴生 tests.md，采用 spec 内联验证模式）"
  fi
fi

# ---------------------------------------------------------------------------
# S4 ADR 编号唯一 + ADR 索引不漏登
# ---------------------------------------------------------------------------
S4_BROKEN=0
DUP=$(ls docs/architecture/ADR 2>/dev/null | grep -o '^[0-9]\{4\}' | sort | uniq -d)
if [ -n "$DUP" ]; then
  S4_BROKEN=1
  fail "S4 ADR 编号重复" "重复前缀：$DUP —— 决策只增不改，新决策用下一个编号"
fi
if [ -d docs/architecture/ADR ] && [ -f docs/architecture/README.md ]; then
  while IFS= read -r ADRF; do
    [ -n "$ADRF" ] || continue
    BASE=$(basename "$ADRF")
    case "$BASE" in 0000-*) continue ;; esac
    if ! grep -q "$BASE" docs/architecture/README.md 2>/dev/null; then
      S4_BROKEN=1
      fail "S4 ADR 漏登索引" "${ADRF} 未在 docs/architecture/README.md 的 ADR 索引中登记"
    fi
  done <<ADRLIST
$(find docs/architecture/ADR -maxdepth 1 -name '[0-9][0-9][0-9][0-9]-*.md' 2>/dev/null | sort)
ADRLIST
fi
[ "$S4_BROKEN" -eq 0 ] && pass "S4 ADR 编号唯一且索引齐全"

# ---------------------------------------------------------------------------
# S5 patch 双向指针 + Delta 一致性
# ---------------------------------------------------------------------------
S5_BROKEN=0
while IFS= read -r PATCH; do
  [ -n "${PATCH}" ] || continue
  # 已收敛 / 已废弃的 patch 仅作历史保留（不再是并存态），跳过在途双向指针与 Delta 校验
  PATCH_ST=$(sed -n 's/^| *状态 *| *\([^|]*\)|.*/\1/p' "${PATCH}" 2>/dev/null | head -1 | sed 's/^ *//; s/ *$//')
  case "${PATCH_ST}" in
    *⟨*) ;;
    *已收敛*|*已废弃*) continue ;;
  esac
  DIR=$(dirname "${PATCH}")
  BASE=$(basename "${PATCH}" .md)
  NUM=$(printf '%s' "${BASE}" | sed 's/^PATCH-\([0-9]\{3\}\)-.*/\1/')
  if [ "${NUM}" = "${BASE}" ] || ! printf '%s' "${NUM}" | grep -q '^[0-9]\{3\}$'; then
    S5_BROKEN=1
    fail "S5 ${PATCH}" "patch 文件名不符合 PATCH-NNN-简述 约定（NNN 为三位数字）——改名为 PATCH-NNN-简述.md 后重查"
    continue
  fi
  grep -q '覆盖范围' "${PATCH}" || { S5_BROKEN=1; fail "S5 ${PATCH}" "缺少「① 覆盖范围」节——按 _templates/patch.md 补上 Patch → 主文档指针"; }
  if ! grep -q "已被.*PATCH-${NUM}" "$DIR/spec.md" 2>/dev/null; then
    S5_BROKEN=1
    fail "S5 ${DIR}/spec.md" "存在 ${BASE} 但主文档没有「已被 …PATCH-${NUM}…取代」反向指针——在主文档目标章节加取代标记（见 patch 模板 §⑤）"
  fi
  while IFS="$(printf '\t')" read -r KIND REST; do
    [ -n "${KIND}" ] || continue
    case "${KIND}" in
      CHK) grep -q "\`${REST}\`" "${DIR}/spec.md" 2>/dev/null || {
             S5_BROKEN=1
             fail "S5 ${PATCH}" "delta 引用的 ${REST} 在主文档不存在——核对编号（可能打错、已被移除或被 RENAMED 改名）"
           } ;;
      NEW) grep -q "\`${REST}\`" "${DIR}/spec.md" 2>/dev/null && {
             S5_BROKEN=1
             fail "S5 ${PATCH}" "RENAMED TO 的 ${REST} 在主文档已存在——TO 必须换新编号（通常用 AC-PNNN-N）"
           } ;;
      ERR) S5_BROKEN=1; fail "S5 ${PATCH}" "${REST}" ;;
    esac
  done <<DELTACHECK
$(awk '
  /^###[ ]+/ {
    if (sec=="RENAMED" && pend!="") { printf "ERR\t### RENAMED 里 FROM: `%s` 没有配对的 TO:（每条 FROM: 紧跟一条 TO:）\n", pend; pend="" }
    hdr=$0; sub(/^###[ ]+/,"",hdr); sub(/[ ]+$/,"",hdr)
    if (hdr=="ADDED"||hdr=="MODIFIED"||hdr=="REMOVED"||hdr=="RENAMED") { sec=hdr }
    else {
      sec=""; up=toupper(hdr)
      if (up ~ /^ADD|^MODI|^REMO|^RENA/) printf "ERR\t小节标题「### %s」疑似拼错——delta 小节只认 ADDED/MODIFIED/REMOVED/RENAMED（若非笔误请改标题或层级）\n", hdr
    }
    next
  }
  /^## / {
    if (sec=="RENAMED" && pend!="") { printf "ERR\t### RENAMED 里 FROM: `%s` 没有配对的 TO:（每条 FROM: 紧跟一条 TO:）\n", pend; pend="" }
    sec=""; next
  }
  sec=="RENAMED" && match($0,/^-[ ]*FROM:[ ]*`AC-[A-Za-z0-9-]+`/) {
    id=$0; sub(/^[^`]*`/,"",id); sub(/`.*/,"",id)
    if (pend!="") printf "ERR\t### RENAMED 里 FROM: `%s` 没有配对的 TO:（每条 FROM: 紧跟一条 TO:）\n", pend
    pend=id; mark(id,"RENAMED(FROM)"); printf "CHK\t%s\n", id; next
  }
  sec=="RENAMED" && match($0,/^-[ ]*TO:[ ]*`AC-[A-Za-z0-9-]+`/) {
    id=$0; sub(/^[^`]*`/,"",id); sub(/`.*/,"",id)
    if (pend=="") printf "ERR\t### RENAMED 里 TO: `%s` 没有配对的 FROM:\n", id
    else pend=""
    if (id !~ /^AC-P[0-9]+-[0-9]+$/) printf "ERR\tRENAMED TO 的 `%s` 必须是 AC-PNNN-N 形编号——普通 AC-N 会撞主文档编号体系\n", id
    mark(id,"RENAMED(TO)"); printf "NEW\t%s\n", id; next
  }
  sec!="" && sec!="RENAMED" && match($0,/^-[ ]*(\[[ xX]\][ ]*)?`AC-[A-Za-z0-9-]+`/) {
    id=$0; sub(/^[^`]*`/,"",id); sub(/`.*/,"",id)
    mark(id,sec); if (sec!="ADDED") printf "CHK\t%s\n", id
    next
  }
  sec=="" && match($0,/^-[ ]*(\[[ xX]\][ ]*)?`AC-[A-Za-z0-9-]+`/) {
    printf "ERR\tAC 条目不在 delta 小节内会被收敛忽略：%s（移进对应 ### 小节）\n", $0
  }
  sec=="" && match($0,/^-[ ]*(FROM|TO):[ ]*`AC-[A-Za-z0-9-]+`/) {
    printf "ERR\tFROM:/TO: 行不在 ### RENAMED 小节内会被忽略：%s\n", $0
  }
  function mark(ac, s) {
    if (++cnt[s,ac]>1) printf "ERR\t`%s` 在 %s 小节内重复——同一编号只留一条\n", ac, s
    if (index(seclist[ac], s)==0) seclist[ac]=(seclist[ac]==""?s:seclist[ac] "|" s)
  }
  END {
    if (pend!="") printf "ERR\t### RENAMED 里 FROM: `%s` 没有配对的 TO:（每条 FROM: 紧跟一条 TO:）\n", pend
    for (ac in seclist) {
      n=split(seclist[ac],p,"|")
      if (n>1) printf "ERR\t编号 `%s` 跨多个 delta 小节出现（%s）——一个 AC 只能属于一种操作\n", ac, seclist[ac]
    }
  }
' "${PATCH}")
DELTACHECK
done <<FINDLIST
$(find docs/specs -name 'PATCH-*.md' -not -path '*/_templates/*' -not -path '*/_archived/*')
FINDLIST
[ "$S5_BROKEN" -eq 0 ] && pass "S5 patch 双向指针 + Delta 一致性"

# ---------------------------------------------------------------------------
# S6 知识库卫生：约定防膨胀（>15 条告警）；日常提交不再强制手写月度 changelog
#    （changelog 改由 git log + scripts/collar-changelog.sh 按需生成）
# ---------------------------------------------------------------------------
CONV_COUNT=$(grep -c '^### C-' docs/runbook/conventions.md 2>/dev/null || echo 0)
if [ "$CONV_COUNT" -gt 15 ]; then
  warn "S6 conventions.md 已有 ${CONV_COUNT} 条约定 (>15 提示线)" \
       "约定过多会稀释常驻上下文——合并同类项或退役长期未命中的约定"
else
  pass "S6 知识库卫生合规（conventions ${CONV_COUNT} 条 ≤15；changelog 按需从 git log 生成）"
fi

# ---------------------------------------------------------------------------
# S7 现状文档只写现在时：禁用绑定「过去某次会话」的指代词
# ---------------------------------------------------------------------------
LEAK=$(grep -rn '本次新增\|本轮\|刚才\|上文提到\|上次提到\|本次调整\|本次引入' \
       AGENTS.md collar.yaml README.md README.en.md skills/ docs/specs/README.md \
       docs/architecture/README.md docs/runbook/*.md \
       2>/dev/null || true)
if [ -z "$LEAK" ]; then
  pass "S7 现状文档无会话指代词"
else
  fail "S7 现状文档出现会话指代（未来读者无法解析）" "改为指代具体文件/章节：$LEAK"
fi

# ---------------------------------------------------------------------------
# S8 锚点登记册可自动生成
# ---------------------------------------------------------------------------
if [ -x scripts/collar-anchors.sh ] || [ -f scripts/collar-anchors.sh ]; then
  if ANCHOR_OUT=$(sh scripts/collar-anchors.sh --check 2>&1); then
    pass "S8 锚点登记可自动生成（$(printf '%s' "$ANCHOR_OUT" | sed 's/^ok   anchor: //')）"
  else
    fail "S8 锚点登记不合法" "$ANCHOR_OUT"
  fi
else
  pass "S8 未启用锚点生成器（可选能力）"
fi

if [ "$JSON" -eq 1 ]; then
  if [ "$FAIL" -eq 0 ]; then
    printf '{"ok":true,"repo":"%s","checks":[%s]}\n' "$(json_esc "$ROOT")" "$CHECKS_JSON"
    exit 0
  else
    printf '{"ok":false,"repo":"%s","checks":[%s]}\n' "$(json_esc "$ROOT")" "$CHECKS_JSON"
    exit 1
  fi
fi

echo
if [ "$FAIL" -eq 0 ]; then
  echo "全部通过 ✓"
  echo "Next: 按改动分级（Minor / Standard / Major）完成对应验证后提交（见 docs/runbook/commit-gate.md）"
  exit 0
else
  echo "存在失败项，提交被拦截 ✗"
  echo "Next: 按上方逐条修复后重跑 sh scripts/collar-check.sh"
  exit 1
fi

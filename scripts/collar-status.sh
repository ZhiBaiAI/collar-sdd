#!/usr/bin/env sh
# collar-status.sh — 知识库状态导航器
#
# 不是门禁（不拦截），是导航器：回答「现在有哪些在途事项、下一步该干什么」。
# 输出末尾的 Next: 行给出一个可执行建议。
#
# 用法（在仓库根执行）：
#   sh scripts/collar-status.sh                  # 在途概览：未收敛 patch、缺口、超期项
#   sh scripts/collar-status.sh --specs          # 站点地图清单：域/功能/负责人/状态/路径
#   sh scripts/collar-status.sh --specs --json   # 机器可读（供 Agent 索引后按需读 spec）
#
# 退出码：0 = 成功；2 = 参数错误

set -u

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT" || exit 1

MODE=overview
JSON=0
for A in "$@"; do
  case "$A" in
    --specs) MODE=specs ;;
    --json)  JSON=1 ;;
    *) echo "未知参数：$A（可选 --specs / --json）" >&2; exit 2 ;;
  esac
done

field() { # 从 md 头部表取值：field <文件> <字段名>
  sed -n "s/^| *$2 *| *\([^|]*\)|.*/\1/p" "$1" 2>/dev/null | head -1 | sed 's/^ *//; s/ *$//'
}

today_s=$(date +%s)

age_days() { # $1=YYYY-MM-DD → 天数，同时兼容 GNU date (Linux) 与 BSD date (macOS)
  D=$(printf '%s' "$1" | sed -n 's/^\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\).*/\1/p')
  [ -n "$D" ] || return 0
  S=$(date -j -f "%Y-%m-%d" "$D" +%s 2>/dev/null || date -d "$D" +%s 2>/dev/null) || return 0
  echo $(( (today_s - S) / 86400 ))
}

# ---------------------------------------------------------------------------
if [ "$MODE" = specs ]; then
  if [ "$JSON" -eq 1 ]; then
    printf '['
    FIRST=1
    find docs/specs -name spec.md -not -path '*/_templates/*' -not -path '*/_archived/*' | sort | \
    while IFS= read -r SPEC; do
      DIR=$(dirname "$SPEC")
      DOM=$(basename "$(dirname "$DIR")")
      FEAT=$(basename "$DIR")
      OWNER=$(field "$SPEC" 负责人); OWNER=${OWNER:-—}
      ST=$(field "$SPEC" 状态); ST=${ST:-—}
      esc() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
      [ "$FIRST" -eq 1 ] || printf ','
      FIRST=0
      printf '{"domain":"%s","feature":"%s","owner":"%s","status":"%s","path":"%s"}' \
        "$(esc "$DOM")" "$(esc "$FEAT")" "$(esc "$OWNER")" "$(esc "$ST")" "$(esc "$SPEC")"
    done
    printf ']\n'
    exit 0
  else
    printf '%-30s %-30s %-12s %-10s %s\n' 业务域 功能 负责人 状态 路径
    find docs/specs -name spec.md -not -path '*/_templates/*' -not -path '*/_archived/*' | sort | \
    while IFS= read -r SPEC; do
      DIR=$(dirname "$SPEC")
      printf '%-30s %-30s %-12s %-10s %s\n' \
        "$(basename "$(dirname "$DIR")")" "$(basename "$DIR")" \
        "$(field "$SPEC" 负责人)" "$(field "$SPEC" 状态)" "$SPEC"
    done
  fi
  echo
  echo "Next: 按上表选定功能点后，只读对应的 spec.md（先索引后按需，不全读）"
  exit 0
fi

# ---------------------------------------------------------------------------
echo "collar-status — 在途概览"
echo

# 1) 未收敛 patch（状态不是 已收敛/已废弃）
echo "[在途 patch]"
FOUND_P=0
while IFS= read -r P; do
  [ -n "$P" ] || continue
  ST=$(field "$P" 状态)
  case "$ST" in
    *⟨*) ;;
    *已收敛*|*已废弃*) continue ;;
  esac
  FOUND_P=1
  EFF=$(field "$P" 生效日期)
  AGE=$(age_days "$EFF")
  AGES=${AGE:+"（生效 ${AGE} 天）"}
  FLAG=""
  if [ -n "$AGE" ] && [ "$AGE" -ge 14 ]; then
    FLAG=" ⚠ 已超收敛观察期（≥14 天），评估执行 collar-converge.sh"
  fi
  printf '  %-60s 状态=%s%s%s\n' "$P" "${ST:-?}" "$AGES" "$FLAG"
done <<PLIST
$(find docs/specs -name 'PATCH-*.md' -not -path '*/_templates/*' -not -path '*/_archived/*' | sort)
PLIST
[ "$FOUND_P" -eq 0 ] && echo "  （无）"

# 2) spec 缺口（tests.md 按需可选，不再报缺失）
echo
echo "[结构缺口]"
FOUND_G=0
while IFS= read -r SPEC; do
  [ -n "$SPEC" ] || continue
  OWNER=$(field "$SPEC" 负责人)
  case "$OWNER" in *⟨*⟩*|*@谁*|"") printf '  负责人未认领：%s\n' "$SPEC"; FOUND_G=1 ;; esac
  if grep -q '⟨' "$SPEC"; then
    printf '  仍有 ⟨⟩ 占位符未填：%s\n' "$SPEC"
    FOUND_G=1
  fi
done <<SLIST
$(find docs/specs -name spec.md -not -path '*/_templates/*' -not -path '*/_archived/*' | sort)
SLIST
[ "$FOUND_G" -eq 0 ] && echo "  （无）"

# 3) 日落进行中
echo
echo "[在途 sunset]"
FOUND_S=0
while IFS= read -r S; do
  [ -n "$S" ] || continue
  grep -q '已归档' "$S" && continue
  ROW=$(grep -E '\|[^|]*归档[^|]*\|' "$S" | grep -v '⟨' | grep -E '[0-9]{4}-[0-9]{2}-[0-9]{2}' || true)
  [ -n "$ROW" ] && continue
  printf '  %s\n' "$S"
  FOUND_S=1
done <<SUNLIST
$(find docs/specs -name 'SUNSET-*.md' -not -path '*/_templates/*' -not -path '*/_archived/*' | sort)
SUNLIST
[ "$FOUND_S" -eq 0 ] && echo "  （无）"

# 4) 模板示范残留提醒
if [ -d "docs/specs/00_[业务地图]示范域" ] || [ -d "docs/specs/00_[业务地图]示例域" ] || [ -d "docs/specs/01_[业务地图]示范域" ]; then
  echo
  echo "[模板残留]"
  echo "  示范域仍在——若是冷启后的真实项目，跑 sh scripts/collar-init.sh --yes 清理"
fi

echo
echo "Next: 处理完上列事项后，跑 sh scripts/collar-check.sh 过结构门禁再提交"
exit 0

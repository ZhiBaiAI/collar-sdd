#!/usr/bin/env sh
# collar-boundary.sh — 边界声明执行体（POSIX sh，零外部依赖）
#
# 契约声明在 collar.yaml 的 boundary 段；本脚本把文件写边界变成真实拦截：
#   ① deny_write：优先检查禁区（命中即拦截，即使同时命中 allow_write）
#   ② default: deny + allow_write：未命中任何 allow_write 白名单的新增/修改文件一律拦截
#   ③ 仅检查新增/修改/重命名文件（--diff-filter=ACMRT），允许合法删除冗余或越界旧文件
#   ④ deny_command / roles：属运行期策略声明，需由宿主工具/沙箱在执行前拦截
#
# 用法：
#   sh scripts/collar-boundary.sh                       # 检查暂存区文件（pre-commit 用）
#   sh scripts/collar-boundary.sh --staged              # 同上，显式
#   sh scripts/collar-boundary.sh --range <A..B|A...B>  # 检查指定 git 提交区间（CI 用）
#   sh scripts/collar-boundary.sh --json                # 机器可读 JSON 输出
#
# 退出码：0 = 通过；1 = 触碰禁区或越出白名单；2 = 参数错误

set -u
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT" || exit 1

JSON=0
RANGE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --staged) shift ;;
    --json)   JSON=1; shift ;;
    --range)
      RANGE="${2:-}"
      [ -n "$RANGE" ] || { printf 'ERR  --range 需传 git 提交区间（如 HEAD~1..HEAD）\n' >&2; exit 2; }
      shift 2
      ;;
    *)
      printf 'ERR  未知参数：%s（可选 --staged / --range <A..B> / --json）\n' "$1" >&2
      exit 2
      ;;
  esac
done

json_esc() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' '
}

# ---- 读取 boundary.default（默认 deny）----
DEFAULT_POLICY=$(awk '
  /^boundary:/ { in_b=1; next }
  in_b && /^[^[:space:]]/ { in_b=0 }
  in_b && /^[[:space:]]*default:[[:space:]]*/ {
    v=$0
    sub(/^[[:space:]]*default:[[:space:]]*/, "", v)
    sub(/[[:space:]]*#.*$/, "", v)
    gsub(/["'\''[:space:]]/, "", v)
    print v
    exit
  }
' collar.yaml 2>/dev/null || true)
[ -n "$DEFAULT_POLICY" ] || DEFAULT_POLICY="deny"

# ---- 从 collar.yaml 读取列表（只读顶层 boundary 下、未缩进到 roles 里的 allow_write/deny_write）----
read_yaml_list() {
  KEY="$1"
  awk -v key="$KEY" '
    /^boundary:/ { in_b=1; in_list=0; next }
    in_b && /^[^[:space:]]/ { in_b=0; in_list=0 }
    in_b && /^[[:space:]]{2}roles:/ { in_b=0; in_list=0 }
    in_b && $0 ~ ("^[[:space:]]{2}" key ":[[:space:]]*(#.*)?$") { in_list=1; next }
    in_b && in_list && /^[[:space:]]{4}-[[:space:]]*["'\'']/ {
      line=$0
      sub(/^[[:space:]]*-[[:space:]]*["'\'']/, "", line)
      sub(/["'\''].*$/, "", line)
      if (line !~ /⟨/ && line != "") print line
      next
    }
    in_b && in_list && /^[[:space:]]{2}[a-zA-Z_]/ { in_list=0 }
  ' collar.yaml 2>/dev/null || true
}

ALLOW_PATTERNS=$(read_yaml_list "allow_write")
DENY_PATTERNS=$(read_yaml_list "deny_write")

# 内置兜底禁区（即使 yaml 缺失也必须生效）
BUILTIN_DENY=".git/**
.env
.env.*
package-lock.json
pnpm-lock.yaml
yarn.lock
dist/**
out/**"

if [ -n "$DENY_PATTERNS" ]; then
  DENY_PATTERNS="${DENY_PATTERNS}
${BUILTIN_DENY}"
else
  DENY_PATTERNS="${BUILTIN_DENY}"
fi

# ---- glob 匹配：支持 dir/**、dir/、prefix*、精确路径 ----
match_pattern() {
  FILE="$1"
  PAT="$2"
  case "$PAT" in
    *"/**")
      PREFIX=${PAT%/**}
      case "$FILE" in
        "$PREFIX"/*) return 0 ;;
      esac
      ;;
    */)
      case "$FILE" in
        "$PAT"*) return 0 ;;
      esac
      ;;
    *)
      # shellcheck disable=SC2254
      case "$FILE" in
        $PAT) return 0 ;;
      esac
      ;;
  esac
  return 1
}

# ---- 取变更文件列表（仅查新增/修改/重命名，允许删除越界旧文件）----
TARGETS=""
if git rev-parse --git-dir >/dev/null 2>&1; then
  if [ -n "$RANGE" ]; then
    TARGETS=$(git -c core.quotePath=false diff --diff-filter=ACMRT --name-only "$RANGE" 2>/dev/null || true)
  else
    TARGETS=$(git -c core.quotePath=false diff --cached --diff-filter=ACMRT --name-only 2>/dev/null || true)
  fi
fi

if [ -z "$TARGETS" ]; then
  if [ "$JSON" -eq 1 ]; then
    printf '{"ok":true,"policy":"%s","checked":0,"violations":[]}\n' "$(json_esc "$DEFAULT_POLICY")"
  else
    if [ -n "$RANGE" ]; then
      echo "ok   boundary: 区间 ${RANGE} 无新增/修改文件，跳过写边界扫描"
    else
      echo "ok   boundary: 无暂存新增/修改文件（或非 git 环境），跳过写边界扫描"
    fi
  fi
  exit 0
fi

CHECKED=0
DENY_HITS=""
ALLOW_MISSES=""
VIOL_JSON=""
FIRST_V=1

add_violation_json() {
  VF="$1"; VK="$2"; VR="$3"
  [ "$FIRST_V" -eq 1 ] || VIOL_JSON="${VIOL_JSON},"
  FIRST_V=0
  VIOL_JSON="${VIOL_JSON}{\"file\":\"$(json_esc "$VF")\",\"kind\":\"$(json_esc "$VK")\",\"rule\":\"$(json_esc "$VR")\"}"
}

while IFS= read -r F; do
  [ -n "$F" ] || continue
  CHECKED=$((CHECKED + 1))

  # 1) deny_write 优先拦截
  MATCHED_DENY=""
  while IFS= read -r P; do
    [ -n "$P" ] || continue
    if match_pattern "$F" "$P"; then
      MATCHED_DENY="$P"
      break
    fi
  done <<DPAT
${DENY_PATTERNS}
DPAT
  if [ -n "$MATCHED_DENY" ]; then
    DENY_HITS="${DENY_HITS}  ${F}  ← 命中 deny_write: ${MATCHED_DENY}
"
    add_violation_json "$F" "deny_write" "$MATCHED_DENY"
    continue
  fi

  # 2) default: deny 时校验 allow_write 白名单
  if [ "$DEFAULT_POLICY" = "deny" ] && [ -n "$ALLOW_PATTERNS" ]; then
    ALLOWED=0
    while IFS= read -r AP; do
      [ -n "$AP" ] || continue
      if match_pattern "$F" "$AP"; then
        ALLOWED=1
        break
      fi
    done <<APAT
${ALLOW_PATTERNS}
APAT
    if [ "$ALLOWED" -eq 0 ]; then
      ALLOW_MISSES="${ALLOW_MISSES}  ${F}  ← 未命中 allow_write（default: deny）
"
      add_violation_json "$F" "outside_allow_write" "default: deny"
    fi
  fi
done <<FILES
${TARGETS}
FILES

if [ -n "$DENY_HITS" ] || [ -n "$ALLOW_MISSES" ]; then
  if [ "$JSON" -eq 1 ]; then
    printf '{"ok":false,"policy":"%s","checked":%d,"violations":[%s]}\n' \
      "$(json_esc "$DEFAULT_POLICY")" "$CHECKED" "$VIOL_JSON"
  else
    echo "FAIL boundary: 变更文件违反 collar.yaml 写边界"
    [ -n "$DENY_HITS" ] && printf '%s' "$DENY_HITS"
    [ -n "$ALLOW_MISSES" ] && printf '%s' "$ALLOW_MISSES"
    echo "  修法：不该提交的移出暂存区（git restore --staged <file>）；"
    echo "        确属合法项目路径的，先加入 collar.yaml 的 boundary.allow_write 再提交"
  fi
  exit 1
fi

if [ "$JSON" -eq 1 ]; then
  printf '{"ok":true,"policy":"%s","checked":%d,"violations":[]}\n' \
    "$(json_esc "$DEFAULT_POLICY")" "$CHECKED"
else
  echo "ok   boundary: ${CHECKED} 个变更文件均通过写边界检查（default: ${DEFAULT_POLICY}，0 违规）"
fi
exit 0

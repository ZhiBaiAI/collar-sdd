#!/usr/bin/env sh
# collar-changelog.sh — 从 git log 自动生成变更摘要（替代每次提交手写 changelog）
#
# 日常提交只需遵循 Conventional Commits（commit-msg 钩子已校验），
# 需要阶段回顾或发版说明时用本脚本一键提取，不再为每次 commit 手动改写 Markdown。
#
# 用法（在仓库根执行）：
#   sh scripts/collar-changelog.sh                  # 输出最近 30 条提交的分组摘要
#   sh scripts/collar-changelog.sh v1.0.0..HEAD     # 指定 git range
#   sh scripts/collar-changelog.sh --since 2026-11-01
#
# 退出码：0 = 成功；1 = 非 git 仓库或无提交；2 = 参数错误

set -u

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT" || exit 1

git rev-parse --verify HEAD >/dev/null 2>&1 || {
  echo "ERR  当前仓库尚无 git 提交历史" >&2
  exit 1
}

RANGE=""
SINCE=""
LIMIT=30

while [ $# -gt 0 ]; do
  case "$1" in
    --since)
      SINCE="${2:-}"
      [ -n "$SINCE" ] || { echo "ERR  --since 需传日期（如 2026-11-01）" >&2; exit 2; }
      shift 2
      ;;
    --limit)
      LIMIT="${2:-30}"
      shift 2
      ;;
    -*)
      echo "ERR  未知参数：$1（可选 [range] / --since YYYY-MM-DD / --limit N）" >&2
      exit 2
      ;;
    *)
      RANGE="$1"
      shift
      ;;
  esac
done

if [ -n "$SINCE" ]; then
  LOGS=$(git log --since="$SINCE" --pretty=format:'%ad|%h|%an|%s' --date=short 2>/dev/null || true)
elif [ -n "$RANGE" ]; then
  LOGS=$(git log "$RANGE" --pretty=format:'%ad|%h|%an|%s' --date=short 2>/dev/null || true)
else
  LOGS=$(git log -n "$LIMIT" --pretty=format:'%ad|%h|%an|%s' --date=short 2>/dev/null || true)
fi

if [ -z "$LOGS" ]; then
  echo "（指定范围内无提交记录）"
  exit 0
fi

printf '# 变更摘要（生成于 %s）\n\n' "$(date +%Y-%m-%d)"
printf '%s\n' "$LOGS" | awk -F'|' '
  {
    d=$1; h=$2; a=$3; s=$4
    if (s ~ /^[a-z]+(\([^)]*\))?!:/ || s ~ /BREAKING/) { brk[++nb] = "- **" s "** (`" h "`, " d ", @" a ")" }
    else if (s ~ /^(feat|feature)(\([^)]*\))?:/)         { feat[++nf] = "- " s " (`" h "`, " d ", @" a ")" }
    else if (s ~ /^(fix|patch)(\([^)]*\))?:/)            { fix[++nx]  = "- " s " (`" h "`, " d ", @" a ")" }
    else if (s ~ /^(refactor|perf)(\([^)]*\))?:/)        { ref[++nr]  = "- " s " (`" h "`, " d ", @" a ")" }
    else if (s ~ /^sunset(\([^)]*\))?:/)                 { sun[++ns]  = "- " s " (`" h "`, " d ", @" a ")" }
    else                                                 { oth[++no]  = "- " s " (`" h "`, " d ", @" a ")" }
  }
  function dump(title, arr, n,   i) {
    if (n==0) return
    print "## " title "\n"
    for (i=1; i<=n; i++) print arr[i]
    print ""
  }
  END {
    dump("BREAKING 破坏性变更", brk, nb)
    dump("新增与演进（feat）", feat, nf)
    dump("修复与补丁（fix / patch）", fix, nx)
    dump("重构与性能（refactor / perf）", ref, nr)
    dump("下线与归档（sunset）", sun, ns)
    dump("文档与杂项（docs / chore / other）", oth, no)
  }
'
exit 0

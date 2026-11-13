#!/usr/bin/env sh
# collar-boundary.sh — 边界声明执行体
#
# 契约声明在 collar.yaml 的 boundary 段；本脚本把声明变成真实拦截。
#
# 为什么需要它：
#   collar.yaml 里写了 deny_write / deny_command，但此前没有任何东西执行它们——
#   那只是「意图声明」，不是边界。凡是需要攻击者「不知道某条规则」才成立的边界，
#   都不构成边界。本脚本把它做成确定性检查。
#
# 检查两件事：
#   ① deny_write：本次暂存/变更的文件是否落在禁区（.git / .env / 锁文件 / 产物目录）
#   ② deny_command：从 collar.yaml 读取命令黑名单，供 hook 与 Agent 自查
#      （命令黑名单无法在提交时事后判定，因此它作用于 hook 的运行时守卫与
#        commit-msg 留痕，而不是 diff 扫描）
#
# 用法：
#   sh scripts/collar-boundary.sh           # 检查暂存区文件（pre-commit 用）
#   sh scripts/collar-boundary.sh --staged  # 同上，显式
#
# 退出码：0 = 通过；1 = 触碰禁区

set -u
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT" || exit 1

# ---- 从 collar.yaml 读取 deny_write 模式（去掉 ⟨⟩ 占位符与注释）----
DENY_PATTERNS=$(awk '
  /^[[:space:]]*deny_write:/ {ind=1; next}
  ind && /^[[:space:]]*-[[:space:]]*"/ {
    line=$0
    sub(/^[[:space:]]*-[[:space:]]*"/, "", line)
    sub(/".*$/, "", line)
    if (line !~ /⟨/) print line
    next
  }
  ind && !/^[[:space:]]*-/ && !/^[[:space:]]*$/ {ind=0}
' collar.yaml 2>/dev/null || true)

# 内置兜底禁区（即使 yaml 缺失也必须生效）
DENY_PATTERNS="${DENY_PATTERNS}
.git/
.env
.env.local
package-lock.json
pnpm-lock.yaml
yarn.lock
dist/
out/" 

# ---- 取本次暂存文件（无 git 时退化为空，不误报）----
if git rev-parse --git-dir >/dev/null 2>&1; then
  STAGED=$(git diff --cached --name-only 2>/dev/null || true)
else
  STAGED=""
fi

if [ -z "$STAGED" ]; then
  echo "ok   boundary: 无暂存文件（或非 git 环境），跳过禁区扫描"
  exit 0
fi

HIT=""
while IFS= read -r F; do
  [ -n "$F" ] || continue
  while IFS= read -r P; do
    [ -n "$P" ] || continue
    case "$F" in
      $P|$P*) HIT="${HIT}  ${F}  ← 命中禁区 ${P}
"; break ;;
    esac
  done <<PAT
${DENY_PATTERNS}
PAT
done <<FILES
${STAGED}
FILES

if [ -n "$HIT" ]; then
  echo "FAIL boundary: 暂存文件触碰 deny_write 禁区"
  printf '%s' "$HIT"
  echo "  修法：从暂存区移除这些文件（git restore --staged <file>），"
  echo "        确属需要的请在 collar.yaml 的 allow_write 显式放开并写明理由"
  exit 1
fi

echo "ok   boundary: 暂存文件均在 allow_write 范围内（命中 0 条禁区）"

# ---- 输出命令黑名单，供调用方展示（不做事后判定）----
CMDS=$(awk '
  /^[[:space:]]*deny_command:/ {ind=1; next}
  ind && /^[[:space:]]*-[[:space:]]*"/ {
    line=$0
    sub(/^[[:space:]]*-[[:space:]]*"/, "", line)
    sub(/".*$/, "", line)
    print line
    next
  }
  ind && !/^[[:space:]]*-/ && !/^[[:space:]]*$/ {ind=0}
' collar.yaml 2>/dev/null || true)
[ -n "$CMDS" ] && {
  echo "   deny_command（运行时禁止，Agent 自查）："
  printf '%s\n' "$CMDS" | sed 's/^/     /'
}
exit 0

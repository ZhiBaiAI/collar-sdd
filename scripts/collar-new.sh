#!/usr/bin/env sh
# collar-new.sh — 从模板新建变更（feature / patch / sunset / proposal）
#
# 契约声明在 collar.yaml 的 boundary（docs/specs/** 可写）；本脚本只复制模板并自动编号，
# 内容仍由人或 Agent 按模板填。默认不强制生成伴生 tests.md，需要时加 --with-tests。
#
# 用法（在仓库根执行）：
#   sh scripts/collar-new.sh feature  docs/specs/NN_[业务地图]域 功能名 [--with-tests]
#   sh scripts/collar-new.sh patch    docs/specs/NN_[业务地图]域/NN_功能 简述
#   sh scripts/collar-new.sh sunset   docs/specs/NN_[业务地图]域/NN_功能 简述
#   sh scripts/collar-new.sh proposal docs/specs/NN_[业务地图]域/NN_功能 简述
#
# 退出码：0 = 已创建；1 = 执行失败；2 = 参数或路径错误

set -u

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT" || exit 1

die() { printf 'ERR  %s\n' "$1" >&2; exit "${2:-1}"; }
note() { printf '  %s\n' "$1"; }

TYPE="${1:-}"
TARGET="${2:-}"
NAME="${3:-}"
EXTRA="${4:-}"

[ -n "$TYPE" ] && [ -n "$TARGET" ] && [ -n "$NAME" ] || {
  echo "用法：" >&2
  echo "  sh scripts/collar-new.sh feature  <域目录> <功能名> [--with-tests]" >&2
  echo "  sh scripts/collar-new.sh patch    <功能目录> <简述>" >&2
  echo "  sh scripts/collar-new.sh sunset   <功能目录> <简述>" >&2
  echo "  sh scripts/collar-new.sh proposal <功能目录> <简述>" >&2
  exit 2
}
[ -d "$TARGET" ] || die "目标目录不存在：$TARGET（feature 传域目录，patch/sunset/proposal 传功能目录）" 2
case "$TARGET" in docs/specs/*) ;; *) die "目标必须在 docs/specs/ 下：$TARGET" 2 ;; esac

# 去掉前导 0，防止 POSIX sh 把 08/09 当非法八进制数
strip_zeros() {
  VAL=$(printf '%s' "${1:-0}" | sed 's/^0*//')
  printf '%s' "${VAL:-0}"
}

case "$TYPE" in
  feature)
    LAST=$(ls "$TARGET" 2>/dev/null | grep -o '^[0-9][0-9]' | sort -n | tail -1)
    LAST_DEC=$(strip_zeros "${LAST:-0}")
    NN=$(printf '%02d' "$((LAST_DEC + 1))")
    DIR="$TARGET/${NN}_${NAME}"
    [ -e "$DIR" ] && die "已存在：$DIR" 1
    mkdir -p "$DIR"
    cp docs/specs/_templates/feature.md "$DIR/spec.md" || die "缺模板 docs/specs/_templates/feature.md" 1
    echo "created  $DIR/"
    note "  $DIR/spec.md"
    if [ "$EXTRA" = "--with-tests" ]; then
      cp docs/specs/_templates/tests.md "$DIR/tests.md" || die "缺模板 docs/specs/_templates/tests.md" 1
      note "  $DIR/tests.md"
    fi
    echo
    echo "Next: 填 spec.md 的核心 4 节（目标边界 / 契约影响面 / 编号 AC-N 含验证路径 / 待确认）；"
    echo "      简单功能无需另建 tests.md（复杂功能可用 --with-tests）"
    ;;
  patch|sunset|proposal)
    UP=$(printf '%s' "$TYPE" | tr 'a-z' 'A-Z')
    [ -f "$TARGET/spec.md" ] || note "warn: $TARGET/spec.md 不存在，确认传的是功能目录"
    LAST=$(ls "$TARGET" 2>/dev/null | sed -n "s/^${UP}-\([0-9][0-9][0-9]\)-.*/\1/p" | sort -n | tail -1)
    LAST_DEC=$(strip_zeros "${LAST:-0}")
    NNN=$(printf '%03d' "$((LAST_DEC + 1))")
    FILE="$TARGET/${UP}-${NNN}-${NAME}.md"
    [ -e "$FILE" ] && die "已存在：$FILE" 1
    cp "docs/specs/_templates/${TYPE}.md" "$FILE" || die "缺模板 docs/specs/_templates/${TYPE}.md" 1
    echo "created  $FILE"
    echo
    if [ "$TYPE" = patch ]; then
      echo "Next: 填 patch 的 ⟨⟩ 占位符（覆盖范围 / Delta 验收标准），"
      echo "      并回到 spec.md 对应章节加「已被 PATCH-${NNN} 取代」反向指针（结构门禁 S5 必查）"
    elif [ "$TYPE" = sunset ]; then
      echo "Next: 填 sunset 的状态机（评估→预告→双写/灰度→切流→观察→归档）与回滚口径"
    else
      echo "Next: 填 proposal 的 ⟨⟩ 占位符；审阅通过后由 collar-specs 转为 feature/patch 落库"
    fi
    ;;
  *)
    die "未知类型：$TYPE（可选 feature / patch / sunset / proposal）" 2
    ;;
esac

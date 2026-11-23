#!/usr/bin/env sh
# collar-init.sh — 模板冷启执行体：新项目复制骨架后跑一次
#
# 完成新项目冷启的全部机械动作：
#   1. 精确删除示范域（只删模板示范，不碰真实业务域）
#   2. 删除示范蓝图 docs/wiki/blue-print/[技术方案]核心循环V4-MVP.md
#   3. 清理模板自带的示范 changelog 文件
#   4. 清理 docs/specs/README.md 认领表里的示范行
#   5. 建立跨工具通用 Skill 软链 .agents/skills → ../skills（可用 --no-link-skills 跳过）
#   6. 若已 git init，自动装配 git hooks（可用 --no-hooks 跳过）
#   7. 扫描剩余 ⟨⟩ 占位符列成清单 + 跑 collar-check 收尾
#
# 默认是 dry-run（只列将做的事）；加 --yes 才真正执行。
#
# 用法（在仓库根执行）：
#   sh scripts/collar-init.sh                               # 预演
#   sh scripts/collar-init.sh --yes                         # 执行
#   sh scripts/collar-init.sh --yes --no-link-skills        # 不建 .agents/skills 软链
#
# 退出码：0 = 完成；1 = collar-check 失败；2 = 参数错误

set -u

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT" || exit 1

YES=0
LINK_SKILLS=1
INSTALL_HOOKS=1
for ARG in "$@"; do
  case "$ARG" in
    --yes)            YES=1 ;;
    --no-link-skills) LINK_SKILLS=0 ;;
    --no-hooks)       INSTALL_HOOKS=0 ;;
    *)
      printf 'ERR  未知参数：%s（可选 --yes / --no-link-skills / --no-hooks）\n' "$ARG" >&2
      exit 2
      ;;
  esac
done

# 精确列出模板示范目标（避免通配误删真实业务域）
TARGETS=""
for D in "docs/specs/00_[业务地图]示范域" "docs/specs/00_[业务地图]示例域" "docs/specs/01_[业务地图]示范域"; do
  [ -d "$D" ] && TARGETS="${TARGETS}${D}
"
done
DEMO_BP="docs/wiki/blue-print/[技术方案]核心循环V4-MVP.md"
[ -f "$DEMO_BP" ] && TARGETS="${TARGETS}${DEMO_BP}
"

# 收集模板自带的示范 changelog 文件（保留 README.md）
DEMO_LOGS=$(find docs/changelog -name '*.md' -not -name 'README.md' 2>/dev/null | sort || true)

echo "collar-init — 模板冷启"
echo

if [ "$YES" -eq 0 ]; then
  echo "[dry-run] 将执行："
  if [ -n "$TARGETS" ]; then
    printf '%s' "$TARGETS" | while IFS= read -r T; do
      [ -n "$T" ] && printf '  删除 %s\n' "$T"
    done
  else
    echo "  示范域与示范蓝图已清理（无删除项）"
  fi
  if [ -n "$DEMO_LOGS" ]; then
    printf '%s\n' "$DEMO_LOGS" | while IFS= read -r L; do
      [ -n "$L" ] && printf '  清空示范时间线 %s\n' "$L"
    done
  fi
  echo "  清理 docs/specs/README.md 认领表示范行"
  [ "$LINK_SKILLS" -eq 1 ] && echo "  建立通用 Skill 软链 .agents/skills → ../skills（若尚不存在）"
  [ "$INSTALL_HOOKS" -eq 1 ] && echo "  若已 git init，装配 git hooks（sh scripts/collar-hooks.sh）"
  echo "  扫描剩余 ⟨⟩ 占位符 + 跑 collar-check"
  echo
  echo "加 --yes 真正执行：sh scripts/collar-init.sh --yes"
  exit 0
fi

# 1-2) 精确删示范内容
if [ -n "$TARGETS" ]; then
  printf '%s' "$TARGETS" | while IFS= read -r T; do
    [ -n "$T" ] && rm -rf "$T" && echo "deleted  $T"
  done
else
  echo "示范内容不存在，跳过删除"
fi

# 3) 清掉模板自带示范时间线文件（空年份目录一并移除）
if [ -n "$DEMO_LOGS" ]; then
  printf '%s\n' "$DEMO_LOGS" | while IFS= read -r L; do
    [ -n "$L" ] && rm -f "$L" && echo "removed  $L（示范时间线已清理）"
  done
  find docs/changelog -mindepth 1 -type d -empty -delete 2>/dev/null || true
fi

# 4) 认领表示范行：删含 ⟨示例 或 示范域 的行
if grep -qE '⟨示例|示范域' docs/specs/README.md 2>/dev/null; then
  awk '!/⟨示例/ && !/示范域/' docs/specs/README.md > docs/specs/README.md.tmp \
    && mv docs/specs/README.md.tmp docs/specs/README.md
  echo "cleaned  docs/specs/README.md 认领表示范行"
fi

# 5) 建跨工具通用 Skill 软链 .agents/skills -> ../skills（不复制文件）
if [ "$LINK_SKILLS" -eq 1 ] && [ -d skills ]; then
  if [ ! -e ".agents/skills" ]; then
    mkdir -p .agents
    ln -s ../skills .agents/skills && echo "linked   .agents/skills → ../skills"
  else
    echo "ok       .agents/skills 已存在，跳过软链"
  fi
fi

# 6) 若在 git 仓库内，自动装配 hooks
if [ "$INSTALL_HOOKS" -eq 1 ] && git rev-parse --git-dir >/dev/null 2>&1; then
  sh scripts/collar-hooks.sh >/dev/null && echo "hooked   core.hooksPath = scripts/hooks"
fi

echo
# 7) 剩余 ⟨⟩ 占位符清单（只列不填）
echo "[待填占位符] 以下文件仍有 ⟨⟩，按项目实际情况替换："
grep -rln '⟨' AGENTS.md collar.yaml README.md docs/*/README.md docs/runbook/*.md 2>/dev/null | grep -v '/_template' | sort -u | \
  while IFS= read -r F; do
    N=$(grep -c '⟨' "$F")
    printf '  %-50s ×%s\n' "$F" "$N"
  done

# 8) 收尾门禁
echo
sh scripts/collar-check.sh
RC=$?

echo
if [ "$RC" -eq 0 ]; then
  echo "Next: ① 填完上方 ⟨⟩ 占位符（重点：AGENTS.md 仓库地图/命令 + collar.yaml allow_write 与验证命令）"
  echo "      ② 若尚未建仓：git init && sh scripts/collar-hooks.sh"
  echo "      ③ 让 AI 读 AGENTS.md 复述「项目是什么、快速验证命令是什么」——答得出来即冷启通过"
fi
exit "$RC"

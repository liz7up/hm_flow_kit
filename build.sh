#!/bin/sh
# ============================================================
#  build.sh — hm-flow-kit 编译桥接脚本 (POSIX sh)
#
#  用法：
#    sh build.sh             编译 HAR + HAP，全量输出写入 .bitfun/
#    sh build.sh --sync      仅 Sync 依赖（ohpm install）
#
#  产出：
#    .bitfun/build-latest.log  最后一次编译的完整日志
#    .bitfun/har.log           仅 HAR 编译输出（含时间戳版本）
#    .bitfun/hap.log           仅 HAP 编译输出（含时间戳版本）
# ============================================================

PROJECT_DIR="/storage/Users/currentUser/Documents/repo/hm_flow_kit"
cd "$PROJECT_DIR" || exit 1

# ---------- 路径 ----------
HVIGORW="/data/app/hvigor.org/hvigor_1.0.0/bin/hvigorw.js"
NODE="/data/app/bin/node"
OHPM="/data/app/ohpm.org/ohpm_1.1/bin/ohpm"

BITFUN_DIR="$PROJECT_DIR/.bitfun"
mkdir -p "$BITFUN_DIR"

LATEST_LOG="$BITFUN_DIR/build-latest.log"
HAR_LOG="$BITFUN_DIR/har.log"
HAP_LOG="$BITFUN_DIR/hap.log"
SYNC_LOG="$BITFUN_DIR/sync.log"

NOW="[$(date '+%H:%M:%S')]"
HAR_ERROR_COUNT=0
HAP_ERROR_COUNT=0

# ---------- 非严格模式（兼容所有 shell） ----------
set -e

# ---------- 找到 npx ----------
NPX=""
if command -v npx >/dev/null 2>&1; then
  NPX="npx"
elif command -v node >/dev/null 2>&1; then
  # 尝试直接用 node 跑 hvigor
  NPX=""
else
  echo "❌ 未找到 npx 或 node，无法编译"
  exit 1
fi

# ---------- Sync only ----------
if [ "$1" = "--sync" ]; then
  echo "$NOW 开始 ohpm install..."
  $OHPM install --all >"$SYNC_LOG" 2>&1
  echo "✅ Sync 完成，日志：$SYNC_LOG"
  exit 0
fi

# ---------- 清空 latest ----------
: > "$LATEST_LOG"

# ---------- Step 1: HAR ----------
echo "$NOW 编译 HAR (hmflowkit) ..."
echo "$NOW ======================================== HAR ========================================" >> "$LATEST_LOG"
if $NODE "$HVIGORW" \
  -p module=hmflowkit@default \
  -p product=default \
  -p buildMode=debug \
  assembleHar \
  --no-daemon \
  >> "$LATEST_LOG" 2>&1; then
  echo "   ✅ HAR 编译成功"
else
  echo "   ❌ HAR 编译失败"
  HAR_ERROR_COUNT=1
fi

# ---------- Step 2: HAP ----------
echo "$NOW 编译 HAP (entry) ..."
echo "" >> "$LATEST_LOG"
echo "$NOW ======================================== HAP ========================================" >> "$LATEST_LOG"
if $NODE "$HVIGORW" \
  -p module=entry@default \
  -p product=default \
  -p buildMode=debug \
  -p requiredDeviceType=2in1 \
  assembleHap \
  --no-daemon \
  >> "$LATEST_LOG" 2>&1; then
  echo "   ✅ HAP 编译成功"
else
  echo "   ❌ HAP 编译失败"
  HAP_ERROR_COUNT=1
fi

# ---------- 摘要 ----------
echo ""
echo "============================================"
echo "  编译摘要"
echo "============================================"
echo "  HAR: $([ "$HAR_ERROR_COUNT" -eq 0 ] && echo '✅ 成功' || echo '❌ 失败')"
echo "  HAP: $([ "$HAP_ERROR_COUNT" -eq 0 ] && echo '✅ 成功' || echo '❌ 失败')"
echo "  结束时间：$(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================"

# ---------- 提取错误到摘要日志 ----------
if [ "$HAR_ERROR_COUNT" -ne 0 ] || [ "$HAP_ERROR_COUNT" -ne 0 ]; then
  echo "❌ 编译失败，完整日志见：$LATEST_LOG"
  # 提取关键错误行（跨平台 grep）
  echo "" >> "$LATEST_LOG"
  echo "$NOW ======================================== 错误摘要 ========================================" >> "$LATEST_LOG"
  grep -n 'ERROR\|Error\|error' "$LATEST_LOG" >> "$LATEST_LOG" 2>/dev/null || true
  echo "$NOW ======================================== 结束 ========================================" >> "$LATEST_LOG"
else
  echo "✅ 编译全部通过" >> "$LATEST_LOG"
fi

# ---------- 返回状态 ----------
if [ "$HAR_ERROR_COUNT" -ne 0 ] || [ "$HAP_ERROR_COUNT" -ne 0 ]; then
  exit 1
fi
exit 0
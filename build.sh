#!/bin/sh
# ============================================================
#  build.sh — hm-flow-kit 编译桥接脚本 (POSIX sh)
#
#  用法：
#    sh build.sh             启动后台监听模式（轮询 .bitfun/build-flag）
#    sh build.sh --sync      仅 Sync 依赖（ohpm install）
#    sh build.sh --once      单次编译（不进入轮询循环）
#
#  后台监听模式：
#    脚本持续轮询 .bitfun/build-flag 文件内容。
#    当内容为 "1" 时触发编译流程：
#      Step 0: ohpm install --all （同步依赖 + 刷新项目文件）
#      Step 1: HAR 编译
#      Step 2: HAP 编译
#    编译完成后（无论成功失败）将 .bitfun/build-flag 重置为 "0"。
#
#  Claude 触发编译的方式：
#    echo "1" > .bitfun/build-flag
#    等待 .bitfun/build-flag 变回 "0" 后读取 .bitfun/build-latest.log
#
#  产出：
#    .bitfun/build-latest.log  最后一次编译的完整日志
#    .bitfun/har.log           仅 HAR 编译输出（含时间戳版本）
#    .bitfun/hap.log           仅 HAP 编译输出（含时间戳版本）
#    .bitfun/build-flag        编译触发标记（0=空闲, 1=请求编译）
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
BUILD_FLAG="$BITFUN_DIR/build-flag"

# ---------- 确保 build-flag 文件存在 ----------
if [ ! -f "$BUILD_FLAG" ]; then
  echo "0" > "$BUILD_FLAG"
fi

set -e

# ---------- 找到 npx ----------
NPX=""
if command -v npx >/dev/null 2>&1; then
  NPX="npx"
elif command -v node >/dev/null 2>&1; then
  NPX=""
else
  echo "❌ 未找到 npx 或 node，无法编译"
  exit 1
fi

# ============================================================
#  do_sync — Step 0: 同步依赖 + 刷新项目文件
# ============================================================
do_sync() {
  NOW="[$(date '+%H:%M:%S')]"
  echo "$NOW Step 0: ohpm install --all ..."
  $OHPM install --all >"$SYNC_LOG" 2>&1
  echo "   ✅ Sync 完成"
}

# ============================================================
#  do_build — Step 1+2: HAR + HAP 编译
# ============================================================
do_build() {
  NOW="[$(date '+%H:%M:%S')]"
  HAR_ERROR_COUNT=0
  HAP_ERROR_COUNT=0

  : > "$LATEST_LOG"

  # Step 0: always sync before build
  echo "$NOW Step 0: ohpm install --all ..." >> "$LATEST_LOG"
  $OHPM install --all >"$SYNC_LOG" 2>&1
  echo "   ✅ Sync 完成" >> "$LATEST_LOG"

  # Step 1: HAR
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

  # Step 2: HAP
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
    echo "" >> "$LATEST_LOG"
    echo "$NOW ======================================== 错误摘要 ========================================" >> "$LATEST_LOG"
    grep -n 'ERROR\|Error\|error' "$LATEST_LOG" >> "$LATEST_LOG" 2>/dev/null || true
    echo "$NOW ======================================== 结束 ========================================" >> "$LATEST_LOG"
  else
    echo "✅ 编译全部通过" >> "$LATEST_LOG"
  fi

  return $([ "$HAR_ERROR_COUNT" -eq 0 ] && [ "$HAP_ERROR_COUNT" -eq 0 ])
}

# ============================================================
#  Mode dispatch
# ============================================================

# --sync: 仅同步依赖
if [ "$1" = "--sync" ]; then
  do_sync
  echo "✅ Sync 完成，日志：$SYNC_LOG"
  exit 0
fi

# --once: 单次编译（不进入循环）
if [ "$1" = "--once" ]; then
  do_build
  EXIT_CODE=$?
  exit $EXIT_CODE
fi

# ============================================================
#  默认模式：后台监听
# ============================================================
echo "[$(date '+%H:%M:%S')] build.sh 后台监听模式启动，轮询 $BUILD_FLAG ..."
echo "   Claude 触发方式：echo '1' > $BUILD_FLAG"

while true; do
  IS_BUILD=$(cat "$BUILD_FLAG" 2>/dev/null || echo "0")

  if [ "$IS_BUILD" = "1" ]; then
    NOW="[$(date '+%H:%M:%S')]"
    echo "$NOW 检测到编译请求，开始编译..."
    do_build
    # 编译完成后（无论成功失败）重置标记
    echo "0" > "$BUILD_FLAG"
    NOW="[$(date '+%H:%M:%S')]"
    echo "$NOW 编译结束，标记已重置为 0"
  fi

  sleep 3
done
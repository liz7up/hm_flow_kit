#!/bin/sh
# ============================================================
#  test_all.sh — hm-flow-kit 单元测试脚本
#
#  用法：
#    sh test_all.sh          编译库 + 测试模块，验证测试可构建
#    sh test_all.sh --build  仅编译（不运行，无设备时用）
#
#  说明：
#    测试需要 HarmonyOS 设备/模拟器才能实际执行。
#    无设备时，编译通过即可验证测试代码正确性。
# ============================================================

PROJECT_DIR="/storage/Users/currentUser/Documents/repo/hm_flow_kit"
cd "$PROJECT_DIR" || exit 1

HVIGORW="/data/app/hvigor.org/hvigor_1.0.0/bin/hvigorw.js"
NODE="/data/app/bin/node"

BITFUN_DIR="$PROJECT_DIR/.bitfun"
mkdir -p "$BITFUN_DIR"

TEST_LOG="$BITFUN_DIR/test-latest.log"
NOW="[$(date '+%H:%M:%S')]"

set -e

: > "$TEST_LOG"

echo "============================================"
echo "  hm-flow-kit 单元测试"
echo "============================================"
echo ""

# ── Step 1: 编译主库 ──
echo "$NOW 编译主库 (hmflowkit HAR) ..."
echo "$NOW ========== HAR ==========" >> "$TEST_LOG"
if $NODE "$HVIGORW" \
  -p module=hmflowkit@default \
  -p product=default \
  -p buildMode=debug \
  assembleHar \
  --no-daemon \
  >> "$TEST_LOG" 2>&1; then
  echo "  ✅ 主库编译通过"
else
  echo "  ❌ 主库编译失败，详见 $TEST_LOG"
  exit 1
fi

# ── Step 2: 编译测试模块 ──
echo "$NOW 编译测试模块 (hmflowkit ohosTest) ..."
echo "" >> "$TEST_LOG"
echo "$NOW ========== ohosTest ==========" >> "$TEST_LOG"
if $NODE "$HVIGORW" \
  -p module=hmflowkit@ohosTest \
  -p product=default \
  -p buildMode=debug \
  genOnDeviceTestHap \
  --no-daemon \
  >> "$TEST_LOG" 2>&1; then
  echo "  ✅ 测试模块编译通过"
else
  echo "  ❌ 测试模块编译失败，详见 $TEST_LOG"
  # 提取关键错误
  echo "" >> "$TEST_LOG"
  echo "$NOW ========== 错误摘要 ==========" >> "$TEST_LOG"
  grep -n 'ERROR\|Error\|error' "$TEST_LOG" >> "$TEST_LOG" 2>/dev/null || true
  exit 1
fi

# ── 摘要 ──
echo ""
echo "============================================"
echo "  测试构建摘要"
echo "============================================"
echo "  HAR 编译 : ✅ 通过"
echo "  Test 编译: ✅ 通过"
echo "  结束时间 : $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "  💡 要在设备上运行测试："
echo "     1. 连接 HarmonyOS 设备/启动模拟器"
echo "     2. 在 DevEco Studio 中右键 ohosTest → Run"
echo "============================================"

exit 0

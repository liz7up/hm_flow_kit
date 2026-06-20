#!/bin/sh
# ============================================================
#  build_har.sh — 仅编译 hmflowkit HAR
#  用法: sh build_har.sh
# ============================================================

PROJECT_DIR="/storage/Users/currentUser/Documents/repo/hm_flow_kit"
cd "$PROJECT_DIR" || exit 1

HVIGORW="/data/app/hvigor.org/hvigor_1.0.0/bin/hvigorw.js"
NODE="/data/app/bin/node"
BITFUN_DIR="$PROJECT_DIR/.bitfun"
mkdir -p "$BITFUN_DIR"
HAR_LOG="$BITFUN_DIR/har.log"

NOW="[$(date '+%H:%M:%S')]"

echo "$NOW 编译 HAR (hmflowkit) ..."
: > "$HAR_LOG"

if $NODE "$HVIGORW" \
  -p module=hmflowkit@default \
  -p product=default \
  -p buildMode=debug \
  assembleHar \
  --no-daemon \
  >> "$HAR_LOG" 2>&1; then
  echo "✅ HAR 编译成功"
  exit 0
else
  echo "❌ HAR 编译失败，日志: $HAR_LOG"
  echo ""
  grep -n 'ERROR:' "$HAR_LOG" 2>/dev/null || true
  exit 1
fi

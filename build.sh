#!/usr/bin/env sh
# build.sh — hm-flow-kit 编译 + 守护桥接脚本
# 用法:
#   sh build.sh          尝试调用 hvigorw 编译（如果可访问）
#   sh build.sh --daemon 启动守护进程，监听 DevEco 编译产物

set -eu

PROJECT_ROOT=""
if [ -d "/storage/Users/currentUser/Documents/repo/hm_flow_kit" ]; then
  PROJECT_ROOT="/storage/Users/currentUser/Documents/repo/hm_flow_kit"
elif [ -f "./build-profile.json5" ]; then
  PROJECT_ROOT="$(pwd)"
else
  echo "❌ 请在项目根目录运行"
  exit 1
fi

cd "$PROJECT_ROOT"

BITFUN_DIR="$PROJECT_ROOT/.bitfun"
BUILD_LOG="$BITFUN_DIR/build-latest.log"
DEBUG_LOG="$BITFUN_DIR/debug.log"
SNAPSHOT="$BITFUN_DIR/build-snapshot.txt"
mkdir -p "$BITFUN_DIR"

log_debug() {
  echo "[$(date '+%H:%M:%S')] $1" >> "$DEBUG_LOG"
}

find_hvigorw() {
  # 尝试多个常见路径
  for path in \
    "$PROJECT_ROOT/hvigorw" \
    "/data/app/hvigor.org/hvigor_1.0.0/bin/hvigorw.js" \
    "/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw"; do
    if [ -f "$path" ] || [ "$(command -v "$path" 2>/dev/null)" != "" ]; then
      echo "$path"
      return 0
    fi
  done
  return 1
}

do_build() {
  HIVIGORW_PATH=$(find_hvigorw) || true
  NODE_PATH=$(command -v node 2>/dev/null) || true

  echo "" > "$BUILD_LOG"
  echo ">>> hm-flow-kit 编译日志" >> "$BUILD_LOG"
  echo ">>> 时间：$(date '+%Y-%m-%d %H:%M:%S')" >> "$BUILD_LOG"
  echo "" >> "$BUILD_LOG"

  if [ -z "${HIVIGORW_PATH:-}" ] || [ -z "${NODE_PATH:-}" ]; then
    echo "⚠️  hvigorw 或 node 不可用（DevEco 沙箱环境）" >> "$BUILD_LOG"
    echo "" >> "$BUILD_LOG"
    echo "请手动在 DevEco 中编译（Build → Make Project 或 Ctrl+F9）" >> "$BUILD_LOG"
    cat "$BUILD_LOG"
    return 0
  fi

  echo "[1/2] 编译 hmflowkit (HAR)..." >> "$BUILD_LOG"
  echo "命令：$NODE_PATH $HIVIGORW_PATH -p module=hmflowkit@default assembleHar --no-daemon" >> "$BUILD_LOG"
  echo "" >> "$BUILD_LOG"
  "$NODE_PATH" "$HIVIGORW_PATH" -p module=hmflowkit@default -p product=default -p buildMode=debug assembleHar --no-daemon 2>&1 | tee -a "$BUILD_LOG" || true
  echo "" >> "$BUILD_LOG"

  echo "[2/2] 编译 entry (Demo HAP)..." >> "$BUILD_LOG"
  echo "命令：$NODE_PATH $HIVIGORW_PATH -p module=entry@default assembleHap --no-daemon" >> "$BUILD_LOG"
  echo "" >> "$BUILD_LOG"
  "$NODE_PATH" "$HIVIGORW_PATH" -p module=entry@default -p product=default -p buildMode=debug -p requiredDeviceType=2in1 assembleHap --no-daemon 2>&1 | tee -a "$BUILD_LOG" || true
  echo "" >> "$BUILD_LOG"

  if grep -iq "BUILD SUCCESSFUL\|BUILD SUCCESS" "$BUILD_LOG" 2>/dev/null; then
    echo "✅ 编译成功" >> "$BUILD_LOG"
  elif grep -iq "ERROR\|FAIL" "$BUILD_LOG" 2>/dev/null; then
    echo "❌ 编译失败（见上方错误详情）" >> "$BUILD_LOG"
  fi

  echo "" >> "$BUILD_LOG"
  echo "日志已写入：$BUILD_LOG"
}

run_daemon() {
  echo ">>> 首次启动监控，建立基准快照（之后每次 DevEco 编译都会被捕获）"

  # 建立初始快照
  find "$PROJECT_ROOT/hmflowkit/build" "$PROJECT_ROOT/entry/build" \
    -name "*.ets" -o -name "*.json" -o -name "*.txt" -o -name "*.log" \
    -newer "$PROJECT_ROOT/build-profile.json5" 2>/dev/null > "$SNAPSHOT" || true
  log_debug "初始快照条目数: $(wc -l < "$SNAPSHOT" 2>/dev/null || echo 0)"

  # 记录第一次快照时间戳文件
  TS_FILE="$BITFUN_DIR/snapshot-time.txt"
  date '+%s' > "$TS_FILE"

  echo ">>> 守护已启动，监控中… 请在 DevEco 中点击编译（Build → Make Project 或 Ctrl+F9）"
  echo ""

  while true; do
    sleep 3

    # 找到最近修改的文件
    LATEST_FILE=""
    LATEST_TS=0

    for dir in "$PROJECT_ROOT/hmflowkit/build" "$PROJECT_ROOT/entry/build"; do
      if [ -d "$dir" ]; then
        FOUND=$(find "$dir" \( -name "*.ets" -o -name "*.json" -o -name "*.txt" \) -newer "$TS_FILE" -type f 2>/dev/null | head -1)
        if [ -n "$FOUND" ]; then
          LATEST_FILE="$FOUND"
          break
        fi
      fi
    done

    if [ -n "$LATEST_FILE" ]; then
      TS=$(date '+%H:%M:%S')
      log_debug "=== 检测到编译产物 ($TS) ==="
      log_debug "新文件: $LATEST_FILE"

      # 更新时间戳
      date '+%s' > "$TS_FILE"

      # 尝试从 build 目录找最近的错误输出
      FULL_OUTPUT=""

      # 方法1：查找 hvigor 输出文件
      for dir in "$PROJECT_ROOT/hmflowkit/build" "$PROJECT_ROOT/entry/build"; do
        if [ -d "$dir" ]; then
          RESULT=$(find "$dir" -name "hvigor_output*.log" -newer "$TS_FILE" 2>/dev/null | head -1)
          if [ -n "$RESULT" ]; then
            FULL_OUTPUT=$(cat "$RESULT" 2>/dev/null || true)
            log_debug "从 hvigor log 读取: $RESULT, $(echo "$FULL_OUTPUT" | wc -l) 行"
            break
          fi
        fi
      done

      # 方法2：找 build 目录下的 log 文件
      if [ -z "$FULL_OUTPUT" ]; then
        for dir in "$PROJECT_ROOT/hmflowkit/build" "$PROJECT_ROOT/entry/build"; do
          if [ -d "$dir" ]; then
            RESULT=$(find "$dir" -name "*.log" -type f 2>/dev/null | head -1)
            if [ -n "$RESULT" ]; then
              FULL_OUTPUT=$(cat "$RESULT" 2>/dev/null || true)
              log_debug "从 build log 读取: $RESULT, $(echo "$FULL_OUTPUT" | wc -l) 行"
              break
            fi
          fi
        done
      fi

      # 方法3：找 default 目录下最近修改的文件
      if [ -z "$FULL_OUTPUT" ]; then
        for dir in "$PROJECT_ROOT/hmflowkit/build/default" "$PROJECT_ROOT/entry/build/default"; do
          if [ -d "$dir" ]; then
            RESULT=$(find "$dir" -type f -newer "$TS_FILE" 2>/dev/null | head -3)
            if [ -n "$RESULT" ]; then
              log_debug "新产物列表: $RESULT"
            fi
          fi
        done
      fi

      # 提取错误并写出 clean log
      echo ">>> hm-flow-kit 编译日志" > "$BUILD_LOG"
      echo ">>> 时间：$(date '+%Y-%m-%d %H:%M:%S')" >> "$BUILD_LOG"
      echo ">>> 来源：守护进程自动捕获" >> "$BUILD_LOG"
      echo "" >> "$BUILD_LOG"

      if [ -n "$FULL_OUTPUT" ]; then
        # 去掉 ANSI 颜色码
        CLEAN=$(echo "$FULL_OUTPUT" | sed 's/\x1b\[[0-9;]*m//g')

        # 提取错误行（ERROR 前后各保留一行上下文）
        echo "$CLEAN" | grep -i -B1 -A1 "ERROR\|FAIL" 2>/dev/null >> "$BUILD_LOG" || true

        if grep -iq "ERROR" "$BUILD_LOG" 2>/dev/null; then
          echo "" >> "$BUILD_LOG"
          echo "❌ 编译失败" >> "$BUILD_LOG"
        elif grep -iq "SUCCESSFUL\|SUCCESS" "$BUILD_LOG" 2>/dev/null; then
          echo "" >> "$BUILD_LOG"
          echo "✅ 编译成功" >> "$BUILD_LOG"
        fi

        log_debug "clean log 写入 $(wc -l < "$BUILD_LOG") 行"
      else
        echo "⚠️  检测到构建产物变化，但未找到编译日志文件" >> "$BUILD_LOG"
        echo "  产物文件: $LATEST_FILE" >> "$BUILD_LOG"
        echo "" >> "$BUILD_LOG"
        echo "请手动将 DevEco 的编译输出粘贴给 BitFun" >> "$BUILD_LOG"
        log_debug "未找到编译日志，只检测到产物"
      fi

      log_debug "本轮处理完毕"
      echo ""
    fi
  done
}

# ===== 主入口 =====
case "${1:-}" in
  --daemon|-d)
    run_daemon
    ;;
  *)
    do_build
    ;;
esac
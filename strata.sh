#!/bin/zsh
# strata Q2_0 服务启停脚本（去审查版默认；官方版把 CONFIG 换成 strata-q2_0.json）
# 用法: ./strata.sh start | stop | restart | status

DIR="/Users/cafedead/workspace/flashnext-bench/01-strata-iq3xxs/code/Strata-Temp-MacPatchFork"
CONFIG="strata-abl-q2_0.json"      # 官方版: strata-q2_0.json
PORT=8080

start() {
  if curl -s -m 2 "http://127.0.0.1:$PORT/health" >/dev/null 2>&1; then
    echo "已在运行: http://127.0.0.1:$PORT/v1"
    return 0
  fi
  cd "$DIR" || exit 1
  nohup .venv/bin/python serve/server.py --engine strata --config "$CONFIG" --port "$PORT" \
    >> "strata-${CONFIG%.json}-server.log" 2>&1 & disown
  echo "启动中（加载约 40-60 秒）... PID $!"
  for i in {1..30}; do
    sleep 3
    if curl -s -m 2 "http://127.0.0.1:$PORT/health" >/dev/null 2>&1; then
      echo "就绪: http://127.0.0.1:$PORT/v1  (配置: $CONFIG)"
      return 0
    fi
  done
  echo "超时未就绪，看日志: $DIR/strata-${CONFIG%.json}-server.log"
  return 1
}

stop() {
  pkill -f "serve/server.py --engine strata --config .* --port $PORT" 2>/dev/null
  sleep 2
  pkill -f "build-metal/strata --serve" 2>/dev/null
  pkill -f "strata-vision --mmproj" 2>/dev/null
  sleep 2
  if curl -s -m 2 "http://127.0.0.1:$PORT/health" >/dev/null 2>&1; then
    echo "仍在响应，请检查进程"; return 1
  fi
  echo "已停止，端口 $PORT 已释放"
}

status() {
  if curl -s -m 2 "http://127.0.0.1:$PORT/health" 2>/dev/null; then
    echo
    ps aux | grep -v grep | grep -E "build-metal/strata|strata-vision" | awk '{print "PID", $2}'
  else
    echo "未运行"
  fi
}

case "$1" in
  start)   start ;;
  stop)    stop ;;
  restart) stop; sleep 1; start ;;
  status)  status ;;
  *) echo "用法: $0 {start|stop|restart|status}"; exit 1 ;;
esac

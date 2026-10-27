#!/bin/bash
# 小红书 MCP 服务守护：已活则复用（绝不启动第二个服务实例）；死则先清泄漏 Chrome 再按规范启动。
# 背景：服务异常退出/旧版重建会把 Chrome 留成程序坞孤儿；重复 nohup 会起多个服务。
# 用法: bash scripts/xhs_ensure.sh
set -u

MCP_URL="http://127.0.0.1:18060/mcp"
BIN="/Users/yu/go/bin/xiaohongshu-mcp-singleton"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
WORKDIR="/Users/yu/ZCode-Projects/网络资源爬虫"   # cookies.json（登录态）在服务启动时的 cwd
LOG="/tmp/xhs-mcp.log"

# 1) 探活：ping 通即复用——防止重复 nohup 起多实例
if curl -s --noproxy '*' -m 5 -X POST "$MCP_URL" -H 'Content-Type: application/json' \
     -d '{"jsonrpc":"2.0","id":1,"method":"ping"}' | grep -q '"result"'; then
  echo "alive: ${MCP_URL}（复用现有服务，不再启动）"
  exit 0
fi

# 2) 探活失败：服务已死，rod Chrome 全是孤儿，--all 全清（精确匹配 rod/user-data，不碰日常 Chrome）
DIR="$(cd "$(dirname "$0")" && pwd)"
bash "$DIR/xhs_cleanup_chrome.sh" --all >/dev/null 2>&1 || true

# 3) 规范启动：cwd 必须是 cookies.json 所在目录；必须 -headless=false（无头被风控掐死）
cd "$WORKDIR" || { echo "ERROR 工作目录不存在: $WORKDIR"; exit 1; }
nohup "$BIN" --bin "$CHROME" -headless=false > "$LOG" 2>&1 &
sleep 3

if curl -s --noproxy '*' -m 8 -X POST "$MCP_URL" -H 'Content-Type: application/json' \
     -d '{"jsonrpc":"2.0","id":1,"method":"ping"}' | grep -q '"result"'; then
  echo "started: pid $(pgrep -f xiaohongshu-mcp-singleton | head -1), log: $LOG"
  exit 0
fi
echo "ERROR 启动失败，查看 $LOG"
exit 1

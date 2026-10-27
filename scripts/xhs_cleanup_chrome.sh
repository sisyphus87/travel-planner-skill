#!/bin/bash
# 清理小红书 MCP 泄漏的 Chrome 实例与僵死服务进程。
# 精确匹配：命令行含 "rod/user-data"（rod 自动化专用临时 user-data-dir）；
# 用户日常 Chrome 不带该参数，绝不会被误杀。
#
# 用法:
#   bash scripts/xhs_cleanup_chrome.sh        # 只杀「孤儿」rod Chrome（父服务已死、被 launchd 收养的）
#   bash scripts/xhs_cleanup_chrome.sh --all  # 全部杀掉（服务已死或确认要连健康实例一起清时；活服务下次调用会自动重建）
set -u

ALL="${1:-}"
SVC_PIDS=$(pgrep -f "xiaohongshu-mcp" 2>/dev/null)

is_orphan() { # 父进程不在任何 MCP 服务进程里 = 孤儿（含被 launchd 收养 ppid=1）
  local ppid
  ppid=$(ps -o ppid= -p "$1" 2>/dev/null | tr -d ' ')
  [ -z "$ppid" ] && return 0
  [ -z "$SVC_PIDS" ] && return 0
  ! echo "$SVC_PIDS" | grep -qw "$ppid"
}

echo "== rod Chrome 实例:"
KILL_LIST=""
for p in $(pgrep -f "rod/user-data" 2>/dev/null); do
  ppid=$(ps -o ppid= -p "$p" 2>/dev/null | tr -d ' ')
  parent_cmd=$(ps -o command= -p "${ppid:-0}" 2>/dev/null)
  case "$parent_cmd" in
    *"rod/user-data"*) continue ;; # Chrome 的子进程：杀主进程即整组退出，跳过
  esac
  if [ "$ALL" = "--all" ] || is_orphan "$p"; then
    KILL_LIST="$KILL_LIST $p"
  fi
done

if [ -n "${KILL_LIST// /}" ]; then
  echo "  kill:$KILL_LIST"
  kill $KILL_LIST 2>/dev/null
  sleep 2
  for p in $KILL_LIST; do kill -0 "$p" 2>/dev/null && kill -9 "$p" 2>/dev/null; done
else
  echo "  无需清理（无孤儿实例）"
fi

echo "== MCP 服务进程（正常应 0 或 1 个）:"
pgrep -fl "xiaohongshu-mcp" || echo "  无"

echo "== 剩余 rod Chrome 孤儿组: $(ps ax -o ppid=,command | grep 'rod/user-data' | grep -v grep | awk '$1==1' | wc -l | tr -d ' ')（0 即干净）"

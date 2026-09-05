#!/usr/bin/env bash
# Claude Code 状态栏提示轮换器（ccstatusline custom-command 组件调用，statusline JSON 走 stdin，忽略）。
# 每次输出一条提示；按时间桶选择，同一轮对话内稳定，每 3 分钟换一条。
#
# 提示来源（一行一条，空行和 # 开头忽略）：
#   1. 本脚本同目录 tips/*.txt         —— 可迁移，随 chifig 仓库同步
#   2. ~/.claude/tips.local/*.txt      —— 机器专属，不入库
# 想让某类提示出现更频繁，就删掉或精简其他文件。

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tips=()
for f in "$here"/tips/*.txt ~/.claude/tips.local/*.txt; do
  [ -f "$f" ] || continue
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in ''|'#'*) continue ;; esac
    tips+=("$line")
  done < "$f"
done

n=${#tips[@]}
[ "$n" -eq 0 ] && exit 0
# 每 180s 一个桶；乘 7 让相邻桶跳跃而非顺序前进
idx=$(( ($(date +%s) / 180 * 7) % n ))
printf '\033[38;5;244m💡 %s\033[0m\n' "${tips[$idx]}"

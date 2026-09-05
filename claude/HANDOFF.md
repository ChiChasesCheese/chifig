# HANDOFF：给公司电脑上的 Claude Code

> 读者是另一台 Mac 上的 Claude。目标：把状态栏提示轮换器接进去，**不覆盖这台机器已有的任何 Claude 配置**。
> 这台机器的 `~/.claude/settings.json`、`~/.config/ccstatusline/settings.json` 等文件由你自己维护，本仓库的 `install.sh` 刻意不碰 `~/.claude`。

## 这是什么

`claude/cc-tips.sh` 每次被调用输出一条提示（带 💡 前缀），按时间桶每 180 秒轮换。提示来源：

| 位置 | 性质 |
|---|---|
| `claude/tips/*.txt`（仓库内） | 可迁移：Ghostty 快捷键、Claude Code 通用操作 |
| `~/.claude/tips.local/*.txt`（本机） | 机器专属：这台机器装的 skills、MCP、项目命令。不入库 |

一行一条，空行和 `#` 开头忽略。脚本从 stdin 读到的 statusline JSON 会被忽略。

## 接入步骤

前提：仓库已 clone 到 `~/chi_config` 并跑过 `install.sh`。

1. **先看这台机器现在用什么状态栏。** 读 `~/.claude/settings.json` 的 `statusLine` 字段。
   - 若是 `ccstatusline`：走第 2 步。
   - 若是别的脚本或没有状态栏：走第 3 步。
   - 任何情况下先备份要改的文件。

2. **ccstatusline 路线。** 在 `~/.config/ccstatusline/settings.json` 的 `lines` 数组里**追加**一行（不要替换已有行）：
   ```json
   [{"id":"tip","type":"custom-command","commandPath":"bash /Users/<用户名>/chi_config/claude/cc-tips.sh","preserveColors":true}]
   ```
   路径写绝对路径，ccstatusline 不展开 `~`。如果这台机器已经有一个 tips 组件，把它的 `commandPath` 指向本脚本即可，不要重复加。

3. **非 ccstatusline 路线。** 如果 `statusLine.command` 是一个自定义脚本，在该脚本末尾追加：
   ```bash
   bash ~/chi_config/claude/cc-tips.sh
   ```
   如果没有状态栏，在 `~/.claude/settings.json` 里加：
   ```json
   "statusLine": {"type": "command", "command": "bash ~/chi_config/claude/cc-tips.sh", "padding": 0}
   ```
   用 `jq` 合并写入，不要整文件覆盖。

4. **建本机专属提示。** `mkdir -p ~/.claude/tips.local`，按这台机器实际装的 skills / MCP / 项目写几个 `.txt`。参考家里机器的分法：`skills.txt`、`mcp.txt`、`<项目名>.txt`、`local.txt`。可以先运行 `ls ~/.claude/skills ~/.claude/plugins` 和读 `~/.claude.json` 的 `mcpServers` 来生成。

5. **验证。** 运行 `echo '{}' | bash ~/chi_config/claude/cc-tips.sh` 应输出一条带 💡 的提示。重启 Claude Code 后状态栏应出现该行。

## 边界

- 不要改 `claude/cc-tips.sh` 和 `claude/tips/*.txt` 以外的仓库文件来适配本机；本机差异全部放 `~/.claude/tips.local/`。
- 想给可迁移提示加条目（比如新学的 Ghostty 键位），改 `claude/tips/*.txt` 并 commit push，家里机器 `git pull` 即得。

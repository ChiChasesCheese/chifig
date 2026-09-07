# chifig

Chi 的 dotfiles，[chezmoi](https://www.chezmoi.io) 驱动，面向多台 macOS（Apple Silicon）。目标：**一条命令 → 可用的开发环境**，机器差异用模块开关表达，仓库公开且不含任何密钥。

## 新 Mac 一条命令

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ChiChasesCheese/chifig/main/bootstrap.sh)"
```

它依次装 Xcode CLT → Homebrew → chezmoi，然后 `chezmoi init --apply`。首次会问几个问题（git 身份、机器角色、模块开关），答案存在 `~/.config/chezmoi/chezmoi.toml`，不入库。

非交互（CI / 让 agent 跑）：

```sh
CHIFIG_INIT_ARGS='--promptString git.name=Chi --promptString git.email=me@example.com --promptChoice role=personal --promptBool modules.gui=true' \
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ChiChasesCheese/chifig/main/bootstrap.sh)"
```

已有环境更新：`chezmoi update`（等价 `git pull && chezmoi apply`）。

## 模块

| 模块 | 默认 | 内容 | 显式触发 |
|---|---|---|---|
| core | 总是 | zsh（antidote + starship + fzf-tab/autosuggestions/fast-syntax-highlighting）、git（XDG 配置 + delta + difftastic）、tmux、mise + uv、atuin、zoxide、`Brewfile.core`、JetBrains Mono Nerd Font | `just brew` |
| ghostty | 开 | `~/.config/ghostty/config` + `cask ghostty` | |
| claude | 开 | Claude Code 状态栏提示轮换器 `~/.claude/cc-tips.sh` + `tips/`（不碰 settings/skills） | |
| editor | 关 | Cursor 的 settings.json / keybindings.json / 扩展清单 | `just editor` |
| gui | 关 | GUI 应用清单 `Brewfile.gui`（Cursor、VS Code、Zed、Raycast、Karabiner、Obsidian、Docker、Claude） | `just gui` |
| fish | 关 | fish 配置 + `brew fish`（与 zsh 共用同一批工具） | |
| macos | 关 | `defaults write` 系统偏好脚本 | `just macos` |

改开关：`chezmoi edit-config` 改 `[data.modules]`，然后 `chezmoi apply`。关掉的模块文件不会落地。

## 给 Claude / agent

仓库内 `CLAUDE.md` 是给在本仓库里工作的 Claude 的规则；`HANDOFF.md` 是给另一台 Mac 上的 Claude 的接入步骤。

## 目录

```
bootstrap.sh   一键入口          justfile       任务入口（just 列出）
home/          chezmoi 源（映射到 ~）   tests/         bats 测试，渲染到临时 HOME
docs/          设计与调研         .github/       CI：macos-latest 端到端跑 bootstrap
```

`home/` 里的命名遵循 chezmoi：`dot_` = `.`，`executable_` = 可执行，`.tmpl` = 模板。

## 日常

```sh
chezmoi cd          # 进源目录
chezmoi edit ~/.config/zsh/conf.d/40-aliases.zsh   # 改配置
chezmoi diff        # 看差异
chezmoi apply       # 应用
just test           # 全部测试（不碰真实 ~）
just lint           # shellcheck + gitleaks
just backup         # 备份受管目标到 ~/.local/state/chifig-backup/<日期>/
just unmanaged      # 本机装了但仓库没记录的 brew 包（只列出，不卸载）
```

## ⚠️ 危险操作

| 操作 | 影响 | 先做什么 |
|---|---|---|
| `chezmoi apply` / `chezmoi update` / `just apply` | 覆盖所有受管文件（zsh、git、tmux、ghostty、Cursor 设置） | `chezmoi diff`；新机先 `just backup` |
| `just macos` | 改系统偏好，重启 Finder 与 Dock | 有交互确认；agent 用 `just --yes macos` |
| `just gui` | 装 8 个 GUI 应用，数 GB | 确认 `Brewfile.gui` 清单 |
| `just editor` | 往 Cursor 装 20 个扩展 | 确认 `cursor-extensions.txt` |
| `chezmoi purge` / `init --purge` | 删源目录与状态 | 别用 |
| `brew bundle cleanup` | 卸掉所有不在 Brewfile 里的包 | 别用，`just unmanaged` 只看不删 |

## 密钥与本机私有

- `~/.config/zsh/local.zsh`、`~/.config/fish/local.fish`、`~/.config/git/local`：chezmoi 永不管理，放 API key、内网地址、per-machine 覆盖。模板见 `local.zsh.example`。
- `~/.claude.json`、`~/.ssh`、`~/.config/gws*` 不纳管。
- `gitleaks` 在 `just lint` 与 CI 中扫描。

## Shell 结构

`~/.zshenv` 只设 `ZDOTDIR=~/.config/zsh`；`~/.config/zsh/.zshrc` 按序加载 `conf.d/`：

| 文件 | 内容 |
|---|---|
| 00-env | XDG、PATH、HISTFILE、brew shellenv |
| 10-options | setopt、按键 |
| 20-plugins | antidote 加载 `.zsh_plugins.txt` |
| 30-tools | starship、zoxide、atuin、fzf、mise、uv 补全 |
| 40-aliases | eza / bat / lazygit 等 |
| 50-conda | conda（不自动激活 base） |

## 运行时

- Node 等：mise（`~/.config/mise/config.toml`，全局 `node = "lts"`，项目内 `.node-version` / `mise.toml` 覆盖）。
- Python：uv（`uv python install 3.12 --default` 让 `python3` 指向 uv 管理的 3.12，`uv tool`、`uvx`）。conda 只保留一套给需要它的项目。
- npm 全局包：`~/.config/chifig/npm-globals.txt`，chezmoi 在文件变化时补装。

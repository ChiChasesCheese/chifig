# chifig v2 设计：chezmoi 驱动的多 Mac 模块化 dotfiles

日期：2026-09-06　状态：已与 Chi 逐题确认（见 docs/research-2026-09-06.md 的调研依据）

## 1. 目标与边界

- 目标：一条命令把任意一台 **macOS（Apple Silicon）** 配成 Chi 的开发环境，多台 Mac 共用一个公开仓库，机器差异用 chezmoi 模板与模块开关表达。
- 非目标（本版）：Linux；Claude Code 的 settings/skills/hooks 纳管（预留 `claude` 模块位，本版只放状态栏 tips 轮换器）；1Password / age；GUI 与系统偏好的自动安装（只做清单与显式触发）。
- 原则：精简（core 只装通用工具）、新 Mac 友好（默认不装 GUI）、安全（无密钥入库；本机清理先备份后删除，只删可恢复项）、可验证（bats + GitHub Actions macOS runner 端到端）。

## 2. 选型（均为 GitHub 主流、2026 活跃）

| 组件 | 选择 | 落选 |
|---|---|---|
| 引擎 | chezmoi 2.72 | nix-darwin（坑多）、stow（无模板） |
| 包 | Homebrew Brewfile（按模块拆分） | |
| Shell | zsh + antidote + starship；fast-syntax-highlighting、zsh-autosuggestions、zsh-completions、fzf-tab | oh-my-zsh + p10k（卸载）、fish（可选模块） |
| CLI | rg fd bat eza zoxide fzf delta difftastic atuin jq btop yazi lazygit gh tmux tealdeer hyperfine | autojump（换 zoxide） |
| 运行时 | mise（node 等）+ uv（python）；conda 仅保留 cask miniconda 给 qbot/quant | pyenv、nvm、brew node（卸载） |
| 终端 | Ghostty，字体 JetBrains Mono Nerd Font（brew cask） | 仓库内 ttf（删除） |
| 任务入口 | justfile | |
| 测试 | bats-core + shellcheck + gitleaks + chezmoi verify；CI macos-latest | |

## 3. 仓库结构

```
chifig/
├── .chezmoiroot                 # = home
├── bootstrap.sh                 # curl | sh 入口：CLT → Homebrew → chezmoi → init --apply
├── justfile                     # bootstrap / apply / update / diff / test / lint / brew / gui / macos / doctor
├── README.md  HANDOFF.md        # 人读 / 其他 Mac 上的 Claude 读
├── .github/workflows/ci.yml
├── docs/                        # 本设计、调研
├── tests/*.bats                 # 见 §7
└── home/                        # chezmoi 源目录根（映射到 ~）
    ├── .chezmoi.toml.tmpl       # init 时提问：git 身份、机器角色、模块开关
    ├── .chezmoiignore.tmpl      # 按模块开关排除文件
    ├── .chezmoiscripts/         # run_once_before_00-homebrew / run_onchange_after_10-brew-bundle / run_onchange_after_20-mise
    ├── dot_zshenv               # 只做 ZDOTDIR=~/.config/zsh
    ├── dot_condarc
    ├── dot_config/
    │   ├── zsh/  .zshrc .zprofile .zsh_plugins.txt conf.d/*.zsh local.zsh.example
    │   ├── git/  config.tmpl ignore
    │   ├── tmux/tmux.conf  starship.toml  mise/config.toml  atuin/config.toml
    │   ├── chifig/  Brewfile.core.tmpl Brewfile.gui macos-defaults.sh npm-globals.txt cursor-extensions.txt
    │   ├── ghostty/config          [模块 ghostty]
    │   └── fish/config.fish        [模块 fish]
    ├── dot_claude/cc-tips.sh tips/ [模块 claude]
    └── Library/Application Support/Cursor/User/{settings,keybindings}.json [模块 editor]
```

## 4. 机器差异模型

`chezmoi init` 首次运行时提问并写入 `~/.config/chezmoi/chezmoi.toml`（不入库）：

| 键 | 类型 | 默认 | 用途 |
|---|---|---|---|
| `git.name` / `git.email` | string | 空 | 渲染 `~/.config/git/config` 的 `[user]` |
| `role` | personal / work | personal | 未来按角色增减工具 |
| `modules.ghostty` | bool | true | 终端配置 |
| `modules.claude` | bool | true | 状态栏 tips |
| `modules.editor` | bool | false | Cursor 配置 + 扩展 Brewfile |
| `modules.gui` | bool | false | cask 清单 Brewfile.gui |
| `modules.fish` | bool | false | fish 配置与安装 |
| `modules.macos` | bool | false | 系统偏好脚本落盘（执行仍需 `just macos`） |

非交互（CI / 其他 Mac 上的 agent）：`chezmoi init --promptDefaults` 或逐项 `--promptString/--promptBool/--promptChoice`。改开关：编辑 chezmoi.toml 后 `chezmoi apply`。

## 5. 安装分层

1. `bootstrap.sh`：装 Xcode CLT、Homebrew、chezmoi，然后 `chezmoi init --apply ChiChasesCheese/chifig`。整个脚本包在 `main()` 内，`set -euo pipefail`，可用 `CHIFIG_REF` 固定分支。
2. chezmoi 脚本：`run_once_before` 确保 brew；`run_onchange_after` 在 `Brewfile.core` 或模块开关变化时 `brew bundle` core；`run_onchange_after` 在 mise 配置或 `npm-globals.txt` 变化时 `mise install`、`uv python install 3.12`、补装 npm 全局包。
3. 显式触发：`just gui`（brew bundle Brewfile.gui）、`just macos`（跑 defaults 脚本）、`just editor`（Cursor 装扩展清单）。永不自动执行。模块开关只决定清单文件是否落地。

## 6. Secrets

- 仓库不含任何密钥。`~/.config/zsh/local.zsh` 在 `.chezmoiignore` 中，zshrc 末尾 `[[ -f ... ]] && source`；仓库提供 `local.zsh.example`。
- `~/.claude.json`、`~/.config/gws*`、`~/.ssh` 不纳管。
- gitleaks 在测试与 CI 中扫描。

## 7. 测试策略（TDD）

| 测试 | 断言 |
|---|---|
| `tests/template.bats` | `.chezmoi.toml.tmpl` 用默认值可渲染；对 personal 与 work、模块全开 / 全关，`chezmoi apply` 到临时目录后文件集合正确（例如 fish 关闭时无 `.config/fish`） |
| `tests/zsh.bats` | 渲染后的每个 zsh 文件 `zsh -n` 通过；以临时 HOME 启动交互 zsh 退出码 0 且 stderr 无 `command not found` |
| `tests/scripts.bats` | 渲染后的 chezmoi 脚本与 bootstrap.sh、justfile 通过 shellcheck / `just --list` |
| `tests/brewfile.bats` | 每个 Brewfile `brew bundle list` 可解析 |
| `tests/secrets.bats` | gitleaks 无发现；无 `gho_` / `sk-` 字样 |
| CI（macos-latest） | `bootstrap.sh` 从零跑到 `chezmoi verify`，再跑全部 bats |

## 8. 本机迁移与清理顺序

1. 备份到 `~/.local/state/chifig-backup/<日期>/`：`.zshrc .zprofile .zshenv .p10k.zsh .gitconfig .tmux.conf .condarc`、`~/chi_config`、`~/.oh-my-zsh/custom` 清单、`~/.claude/settings.json`。
2. `chezmoi init --apply`，写 `local.zsh`（OPENAI_API_KEY 从旧 zshrc 迁入）。
3. mise 装 node LTS，重装 npm 全局包；uv 装 python 3.12；验证 conda `qbot` 可激活。
4. 验证：新 zsh 启动无错、starship 显示、`git config -l` 含新项、ghostty 配置可加载、`cc-tips.sh` 输出。
5. 仅在 4 通过后：卸 oh-my-zsh、p10k、pyenv、nvm、brew node；删除空的 `~/miniconda3` `~/miniforge3`；删 `.zshrcexport` 等垃圾；删 `~/chi_config`；从 `~/.claude/settings.json` 移除明文 token。每项可 `brew install` 或从备份目录恢复。
6. 未纳管的 brew 包不卸载，列入报告供人工决定。

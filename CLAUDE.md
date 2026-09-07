# CLAUDE.md — 给在这个仓库里工作的 Claude Code

这是 Chi 的 dotfiles（chezmoi 驱动，多台 macOS 共用，**公开仓库**）。改这里的文件会通过 `chezmoi apply` 直接覆盖用户家目录里的配置，所以每一步都要按下面的规矩来。

## 一分钟看懂

| 位置 | 作用 |
|---|---|
| `home/` | chezmoi 源，镜像到 `~`。`dot_x` = `~/.x`，`private_` = 权限 0700/0600，`executable_` = 可执行，`.tmpl` = Go 模板 |
| `home/.chezmoi.toml.tmpl` | `chezmoi init` 的提问：git 身份、`role`、`modules.*` 开关。答案存 `~/.config/chezmoi/chezmoi.toml`（不入库） |
| `home/.chezmoiignore.tmpl` | 模块关掉时排除哪些文件；`local.zsh` 等私有文件永久排除 |
| `home/.chezmoiscripts/` | `run_once_before_*` 装 Homebrew；`run_onchange_after_*` 在 Brewfile / mise 配置变化时自动跑 |
| `home/dot_config/chifig/` | `Brewfile.core.tmpl`（总是装）、`Brewfile.gui`（只落清单）、`macos-defaults.sh`、`npm-globals.txt`、`cursor-extensions.txt` |
| `tests/*.bats` | 把仓库渲染到临时 HOME 做断言，**不碰真实 `~`** |
| `justfile` | 任务入口，`just` 列出 |
| `docs/` | 设计文档与调研 |

## 工作流（每次改动都这样）

```sh
chezmoi cd                      # 进源目录（= 本仓库）
chezmoi edit ~/.config/zsh/conf.d/40-aliases.zsh   # 或直接改 home/ 下的源文件
just test                       # 23 项 bats，必须全绿
just lint                       # shellcheck + gitleaks + 渲染脚本检查
chezmoi diff                    # 看将对 ~ 做什么
chezmoi apply                   # 应用到本机
git commit && git push          # 其他机器 chezmoi update
```

- 改了 `.chezmoi.toml.tmpl` 后要 `chezmoi init` 重新生成配置（会沿用已答内容）。
- 新增目标文件时先想它属于哪个模块，属于可选模块的要在 `.chezmoiignore.tmpl` 里加对应排除，并在 `tests/template.bats` 的「全开 / 全关」两个用例里登记。
- 新增脚本必须过 shellcheck（`tests/scripts.bats` 会渲染后检查）。
- 直接改 `~/.config` 下的副本是无效的，下次 `chezmoi apply` 会覆盖。

## 绝对不做

- **不提交任何密钥、token、内网 IP、真实家目录绝对路径**。`tests/secrets.bats` 和 `just lint` 里的 gitleaks 会拦，但不要依赖它。私有内容的去处：`~/.config/zsh/local.zsh`、`~/.config/fish/local.fish`、`~/.config/git/local`、`~/.claude/tips.local/`。
- 不把 `~/.claude.json`、`~/.claude/settings.json`、`~/.ssh`、`~/.config/gws*` 纳入管理（`claude` 模块只管状态栏 tips）。
- 不在 `home/` 里放二进制（字体走 brew cask）。
- 不把项目专属的 brew 包塞进 `Brewfile.core`（`tests/brewfile.bats` 有黑名单）。
- 不在没有备份的情况下删除用户家目录里的东西（见下表）。

## ⚠️ 危险操作一览

| 操作 | 风险 | 要求 |
|---|---|---|
| `chezmoi apply` / `chezmoi update` | 覆盖所有受管目标（zsh、git、tmux、ghostty、Cursor 设置…） | 先 `chezmoi diff`；首次接管一台机器前先 `just backup` |
| `just macos` | 改系统偏好并重启 Finder / Dock；部分需注销生效 | 有交互确认；agent 只能在用户明确要求时用 `just --yes macos` |
| `just gui` | 下载安装 8 个 GUI 应用（含 Docker Desktop），数 GB | 仅用户要求时 |
| `just editor` | 往 Cursor 装 20 个扩展 | 仅用户要求时 |
| `chezmoi init --purge` / `chezmoi purge` | 删除源目录、配置与状态 | 不要用 |
| `brew bundle cleanup` | 卸载所有不在 Brewfile 里的包（本机有 30+ 个未纳管包） | 不要用；用 `just unmanaged` 看清单 |
| 删除 `~/.pyenv` | 本机 19 个项目 venv（含 quant）指向它，删了全坏 | 迁移到 uv 之前不动 |
| 卸载 brew 的 `node` | firebase-cli、gemini-cli 依赖它 | 不动；mise 的 node 已排在 PATH 前 |
| 删除 `~/.local/state/chifig-backup/` | 2026-09-06 迁移的全部备份与可逆 trash | 只有用户自己删 |
| `rm -rf` | 用户的 Claude 设置里已禁止 | 用 `mv` 到备份目录代替 |

## 模块开关与机器差异

`~/.config/chezmoi/chezmoi.toml` 的 `[data.modules]`：ghostty、claude 默认开；editor、gui、fish、macos 默认关。关掉的模块文件不落地。改开关：`chezmoi edit-config` 然后 `chezmoi apply`。`role`（personal / work）目前只是数据，留给以后按角色增减工具。

## 测试怎么写

看 `tests/helpers.bash`：`chifig_apply DEST key=value ...` 用给定答案把仓库渲染到 `DEST/home`。断言文件存在与否、内容片段、`zsh -n`、临时 HOME 里交互式 zsh 能启动。bats 跑在系统 bash 3.2 上，别用关联数组；测试名用英文。

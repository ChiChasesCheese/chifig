# HANDOFF：把另一台 Mac 配成 chifig 环境（给那台机器上的 Claude Code）

读者是**另一台 Mac 上的 Claude**。目标：用本仓库把这台机器配好，**不丢用户已有的私有配置**。整个过程里带 ⚠️ 的步骤要先备份、并只在用户明确要求时执行。

## 0. 先问用户三件事

1. git 的 `user.name` / `user.email`。
2. 机器角色：`personal` 还是 `work`。
3. 要开哪些模块（默认：ghostty ✅、claude ✅、editor ❌、gui ❌、fish ❌、macos ❌）。不确定就用默认。

## 1. 备份（必做）

```sh
mkdir -p ~/.local/state/chifig-backup/$(date +%F)
cd ~ && for f in .zshenv .zshrc .zprofile .gitconfig .tmux.conf .condarc; do [ -e "$f" ] && cp -p "$f" ~/.local/state/chifig-backup/$(date +%F)/; done
cp -R ~/.config/zsh ~/.config/git ~/.config/tmux ~/.config/ghostty ~/.config/starship.toml ~/.local/state/chifig-backup/$(date +%F)/ 2>/dev/null; true
```

如果仓库已在本机（`just` 可用），直接 `just backup`。

## 2. 把私有内容挪出将被覆盖的文件

- `~/.zshrc` 里的 API key、`export PATH=...`、各种 `source` → 写到 `~/.config/zsh/local.zsh`（chezmoi 永不管理；模板见仓库 `home/dot_config/zsh/local.zsh.example`）。
- `~/.gitconfig` 里 `[user]` 之外的本机项（credential、signing）→ `~/.config/git/local`。
- 装好后 `~/.gitconfig` 若还在，会**覆盖** `~/.config/git/config` 的同名项；确认它不再重复设置 pager / user，最好备份后删掉。

## 3. 一条命令安装 ⚠️（会覆盖第 1 步备份的那些文件）

```sh
CHIFIG_INIT_ARGS='--promptString git.name=<名字> --promptString git.email=<邮箱> --promptChoice role=personal --promptBool modules.ghostty=true --promptBool modules.claude=true --promptBool modules.editor=false --promptBool modules.gui=false --promptBool modules.fish=false --promptBool modules.macos=false' \
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ChiChasesCheese/chifig/main/bootstrap.sh)"
```

它做四件事：装 Xcode CLT（可能弹窗，装完重跑）→ 装 Homebrew → 装 chezmoi → `chezmoi init --apply`。apply 会自动：`brew bundle` core 清单、`mise install` node LTS、`uv python install 3.12 --default`、补装 `npm-globals.txt`。**不会**装 GUI 应用、不会改系统偏好、不会碰 `~/.claude/settings.json`。

## 4. 验证

```sh
chezmoi verify && chezmoi doctor
zsh -ic 'print READY; print -l $precmd_functions'     # 应含 prompt_starship_precmd、_atuin_precmd、_mise_hook_precmd
git config --show-origin user.name                    # 应来自 ~/.config/git/config
node -v && python3 -V                                 # mise 的 LTS；uv 的 3.12
echo '{}' | bash ~/.claude/cc-tips.sh                 # 应输出一条 💡
```

新开一个终端窗口确认 prompt 正常。若有 `command not found`，看 `~/.config/zsh/conf.d/` 哪一段报错，通常是 brew 没进 PATH。

## 5. Claude Code 状态栏提示（模块 claude）

`~/.claude/cc-tips.sh` 由 chezmoi 管理；提示来源：仓库内 `~/.claude/tips/*.txt` + 本机 `~/.claude/tips.local/*.txt`（不入库）。接入方式二选一：

- 用 ccstatusline：在 `~/.config/ccstatusline/settings.json` 的 `lines` 数组里**追加**一行
  `[{"id":"tip","type":"custom-command","commandPath":"bash /Users/<用户名>/.claude/cc-tips.sh","preserveColors":true}]`（要绝对路径）。
- 不用 ccstatusline：用 jq 往 `~/.claude/settings.json` 合并 `"statusLine": {"type":"command","command":"bash ~/.claude/cc-tips.sh","padding":0}`，**不要整文件覆盖**。

然后 `mkdir -p ~/.claude/tips.local`，按这台机器的 skills / MCP / 项目写几个 `.txt`。

## 6. 可选模块 ⚠️（只在用户要求时）

| 命令 | 做什么 | 风险 |
|---|---|---|
| `just gui` | 按 `Brewfile.gui` 装 Cursor、VS Code、Zed、Raycast、Karabiner、Obsidian、Docker Desktop、Claude | 数 GB 下载 |
| `just editor` | 给 Cursor 装 `cursor-extensions.txt` 里的 20 个扩展 | 覆盖不了已有扩展，安全但慢 |
| `just --yes macos` | 跑 `macos-defaults.sh`：Finder / 键盘重复 / Dock / 截图目录等，重启 Finder 与 Dock | 改系统偏好，部分需注销生效 |

开关模块：`chezmoi edit-config` 改 `[data.modules]`，再 `chezmoi apply`。

## 7. 回滚

- 单个文件：从第 1 步的备份目录拷回。
- 整体：`chezmoi purge`（⚠️ 删除源目录与状态）后把备份拷回；已装的 brew 包不会被卸载。

## 边界

- 本机差异只放 `local.zsh` / `git/local` / `tips.local`，不要为了适配本机改仓库文件。
- 想改公共配置：`chezmoi cd` → 改 → `just test` → commit → push；其他机器 `chezmoi update`。
- 仓库公开：不提交密钥、内网 IP、真实家目录路径。`just lint` 会用 gitleaks 拦。
- 不要 `rm -rf` 用户家目录里的东西；要清理就 `mv` 到备份目录。

# HANDOFF：给另一台 Mac 上的 Claude Code

> 读者是其他机器上的 Claude。目标：把这台 Mac 配成 chifig 环境，**不覆盖这台机器已有的密钥与私有配置**。

## 一步到位

```sh
CHIFIG_INIT_ARGS='--promptString git.name=<名字> --promptString git.email=<邮箱> --promptChoice role=<personal|work> --promptBool modules.ghostty=true --promptBool modules.claude=true --promptBool modules.editor=false --promptBool modules.gui=false --promptBool modules.fish=false --promptBool modules.macos=false' \
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ChiChasesCheese/chifig/main/bootstrap.sh)"
```

先问用户要 git 身份与角色，模块开关按用户需要改；不确定就用上面的默认（GUI/macos/editor 关）。

## 执行前必须做

1. 备份将被接管的文件到 `~/.local/state/chifig-backup/$(date +%F)/`：`~/.zshenv ~/.zshrc ~/.zprofile ~/.gitconfig ~/.tmux.conf ~/.condarc ~/.config/{zsh,git,tmux,starship.toml,mise,atuin,ghostty}`。chezmoi 会覆盖同名目标；不在仓库里的文件不会被删。
2. 如果这台机器的 `~/.zshrc` 里有 API key、PATH 补充或 `conda init` 之外的私货，把它们搬到 `~/.config/zsh/local.zsh`（chezmoi 永不管理）。
3. 如果 `~/.gitconfig` 有 `[user]` 以外的本机项（credential、signing），搬到 `~/.config/git/local`。
4. 旧的 `~/.gitconfig` 会与新的 `~/.config/git/config` 并存，`~/.gitconfig` 优先级更高：确认它不再重复设置 pager / user。

## 执行后验证

```sh
chezmoi verify && chezmoi doctor
zsh -ic 'print READY; whence -w starship_precmd __zoxide_z _atuin_precmd _mise_hook'
git config --show-origin user.name
echo '{}' | bash ~/.claude/cc-tips.sh     # 应输出一条 💡 提示
```

## Claude Code 状态栏提示（模块 claude）

`~/.claude/cc-tips.sh` 由 chezmoi 管理，提示来源：仓库内 `~/.claude/tips/*.txt`（可迁移）+ `~/.claude/tips.local/*.txt`（本机专属，不入库）。接入状态栏：

- 用 ccstatusline：在 `~/.config/ccstatusline/settings.json` 的 `lines` 里**追加**
  `[{"id":"tip","type":"custom-command","commandPath":"bash <绝对家目录>/.claude/cc-tips.sh","preserveColors":true}]`（ccstatusline 不展开 `~`）。
- 不用 ccstatusline：在 `~/.claude/settings.json` 用 jq 合并 `"statusLine": {"type":"command","command":"bash ~/.claude/cc-tips.sh","padding":0}`，不要整文件覆盖。

然后 `mkdir -p ~/.claude/tips.local` 并按这台机器实际装的 skills / MCP / 项目写几个 `.txt`。

## 边界

- 本机差异全部放 `local.zsh` / `git/local` / `tips.local`，不要为了适配本机改仓库文件。
- 想改公共配置：`chezmoi cd`，改，`just test`，commit，push；其他机器 `chezmoi update`。
- 不要提交任何密钥、内网 IP、真实用户名路径；`just lint` 会用 gitleaks 拦。

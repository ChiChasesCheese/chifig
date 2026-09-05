# chifig

Chi 的 dotfiles。新 Mac 上一条命令复现终端环境：

```
git clone https://github.com/ChiChasesCheese/chifig.git ~/chi_config && ~/chi_config/install.sh
```

`install.sh` 幂等，重复执行安全。之后更新配置只需 `cd ~/chi_config && git pull && ./install.sh`。

## 内容

| 路径 | 作用 | 安装方式 |
|---|---|---|
| `Brewfile` | Ghostty、fzf、rg、fd、bat、eza、jq、delta、btop、lazygit、yazi、tmux、gh、autojump | `brew bundle` |
| `ghostty/config` | Ghostty 配置，仅字体和 ssh-env 生效，其余常用选项已注释附默认值 | 软链到 `~/.config/ghostty/config` |
| `zsh/chi.zsh` | fzf 键位、可选别名 | `~/.zshrc` 末尾 source |
| `git/config` | delta 作 pager、默认分支 main | `git config --global include.path` |
| `fonts/` | MesloLGS NF 四个字重（p10k 推荐字体） | 复制到 `~/Library/Fonts` |

## 不在仓库里的

- `~/.zshrc` 本体（含各机器自己的 PATH、API key），仓库只追加一行 source。
- git 的 user.name / user.email，各机器自己设。
- oh-my-zsh 与 powerlevel10k 需按各自官方方式安装。

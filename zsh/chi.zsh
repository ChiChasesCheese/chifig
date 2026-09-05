# chi_config 的 zsh 补充，由 install.sh 在 ~/.zshrc 末尾 source
# 只放可迁移、无密钥的内容。API key 等留在各机器自己的 ~/.zshrc 里。

# fzf: Ctrl+R 搜历史 / Ctrl+T 搜文件 / Alt+C 跳目录
command -v fzf >/dev/null && source <(fzf --zsh)

# 可选别名，想用就取消注释
# alias ls='eza'
# alias ll='eza -l --git'
# alias cat='bat'
# alias lg='lazygit'

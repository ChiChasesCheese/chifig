#!/usr/bin/env bash
# 幂等：可重复执行。在新 Mac 上：
#   git clone https://github.com/ChiChasesCheese/chifig.git ~/chi_config && ~/chi_config/install.sh
set -euo pipefail
R="$(cd "$(dirname "$0")" && pwd)"
say() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }

# 1. Homebrew + 工具
if ! command -v brew >/dev/null; then
  say "安装 Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
say "brew bundle"
brew bundle --file="$R/Brewfile" --no-upgrade

# 2. 字体（p10k 用的 MesloLGS NF）
say "字体"
mkdir -p ~/Library/Fonts
cp -n "$R"/fonts/*.ttf ~/Library/Fonts/ 2>/dev/null || true

# 3. Ghostty 配置 → 软链
say "Ghostty 配置"
mkdir -p ~/.config/ghostty
if [ -e ~/.config/ghostty/config ] && [ ! -L ~/.config/ghostty/config ]; then
  mv ~/.config/ghostty/config ~/.config/ghostty/config.bak.$(date +%s)
fi
ln -sfn "$R/ghostty/config" ~/.config/ghostty/config

# 4. zsh：在 ~/.zshrc 末尾 source 一次
say "zsh"
LINE='[[ -f ~/chi_config/zsh/chi.zsh ]] && source ~/chi_config/zsh/chi.zsh'
touch ~/.zshrc
grep -qF 'chi_config/zsh/chi.zsh' ~/.zshrc || printf '\n# chi_config\n%s\n' "$LINE" >> ~/.zshrc

# 5. git：include 公共配置
say "git"
git config --global include.path "$R/git/config"

say "完成。新开一个终端生效；Ghostty 首次需从 /Applications 打开一次。"

# 环境变量与 PATH。只放与机器无关的内容；密钥进 local.zsh。
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# brew 与 ~/.local/bin 在 $ZDOTDIR/.zshenv（非交互 shell 也读）

typeset -U path
path=("$HOME/.local/bin" "$HOME/.cargo/bin" $path)

export EDITOR="${EDITOR:-vim}"
export LANG="${LANG:-en_US.UTF-8}"
export HISTFILE="$XDG_STATE_HOME/zsh/history"
export HISTSIZE=100000 SAVEHIST=100000
export ZSH_COMPDUMP="$XDG_CACHE_HOME/zsh/zcompdump"
mkdir -p "${HISTFILE:h}" "${ZSH_COMPDUMP:h}"

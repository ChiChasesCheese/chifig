# antidote：静态生成 ~/.config/zsh/.zsh_plugins.zsh，插件 clone 到 $XDG_CACHE_HOME/antidote
zstyle ':antidote:bundle' use-friendly-names 'yes'
export ANTIDOTE_HOME="$XDG_CACHE_HOME/antidote"
_antidote=""
for _c in /opt/homebrew/opt/antidote/share/antidote/antidote.zsh "$XDG_DATA_HOME/antidote/antidote.zsh"; do
  [[ -r "$_c" ]] && { _antidote="$_c"; break; }
done
if [[ -z "$_antidote" ]]; then
  git clone --depth=1 --quiet https://github.com/mattmc3/antidote "$XDG_DATA_HOME/antidote" 2>/dev/null \
    && _antidote="$XDG_DATA_HOME/antidote/antidote.zsh"
fi
if [[ -n "$_antidote" ]]; then
  source "$_antidote"
  antidote load
fi
unset _antidote _c

# fzf-tab / 补全样式
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath 2>/dev/null || ls $realpath'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

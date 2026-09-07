# 别名：现代替代品优先，缺则回退
if (( $+commands[eza] )); then
  alias ls='eza --group-directories-first'
  alias ll='eza -l --git --group-directories-first'
  alias la='eza -la --git --group-directories-first'
  alias lt='eza --tree --level=2'
else
  alias ll='ls -l' la='ls -la'
fi
(( $+commands[bat] ))     && alias cat='bat --paging=never'
(( $+commands[lazygit] )) && alias lg='lazygit'
(( $+commands[yazi] ))    && alias y='yazi'
(( $+commands[difft] ))   && alias gdt='git difftool'
alias g='git'
alias ..='cd ..' ...='cd ../..'
alias reload='exec zsh'

# 现代 CLI 接入：每个都有存在性判断，缺哪个都不报错
(( $+commands[starship] )) && eval "$(starship init zsh)"
(( $+commands[zoxide] ))   && eval "$(zoxide init zsh)"
(( $+commands[atuin] ))    && eval "$(atuin init zsh --disable-up-arrow)"
(( $+commands[fzf] ))      && source <(fzf --zsh)
(( $+commands[mise] ))     && eval "$(mise activate zsh)"
(( $+commands[uv] ))       && eval "$(uv generate-shell-completion zsh)"

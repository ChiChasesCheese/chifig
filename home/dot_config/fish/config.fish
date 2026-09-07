# chifig fish（可选模块）。与 zsh 共用同一批工具；本机私有内容放 ~/.config/fish/local.fish
if status is-interactive
    if test -x /opt/homebrew/bin/brew
        /opt/homebrew/bin/brew shellenv | source
    end
    fish_add_path -g $HOME/.local/bin $HOME/.cargo/bin
    set -gx EDITOR vim

    type -q starship; and starship init fish | source
    type -q zoxide;   and zoxide init fish | source
    type -q atuin;    and atuin init fish --disable-up-arrow | source
    type -q mise;     and mise activate fish | source
    type -q fzf;      and fzf --fish | source

    if type -q eza
        alias ls 'eza --group-directories-first'
        alias ll 'eza -l --git --group-directories-first'
        alias la 'eza -la --git --group-directories-first'
    end
    type -q bat;     and alias cat 'bat --paging=never'
    type -q lazygit; and alias lg 'lazygit'
    alias g git

    test -f $HOME/.config/fish/local.fish; and source $HOME/.config/fish/local.fish
end

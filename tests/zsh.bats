#!/usr/bin/env bats
load helpers

setup_file() {
  export DEST="$BATS_FILE_TMPDIR/d"
  chifig_apply "$DEST" modules.fish=true
}

@test "rendered zsh files pass zsh -n" {
  while IFS= read -r f; do
    run zsh -n "$f"
    [ "$status" -eq 0 ] || { echo "syntax error in $f: $output"; return 1; }
  done < <(find "$DEST/home/.config/zsh" "$DEST/home/.zshenv" -name '*.zsh' -o -name '.z*' -type f)
}

@test "zshenv only sets ZDOTDIR" {
  grep -q 'ZDOTDIR' "$DEST/home/.zshenv"
  run wc -l < "$DEST/home/.zshenv"
  [ "$output" -le 12 ]
}

@test "interactive zsh starts cleanly in temp HOME" {
  run env -i HOME="$DEST/home" ZDOTDIR="$DEST/home/.config/zsh" PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin" \
      TERM=xterm-256color LANG=en_US.UTF-8 XDG_CACHE_HOME="$BATS_FILE_TMPDIR/cache" \
      zsh -ic 'print CHIFIG_READY; exit 0'
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" == *CHIFIG_READY* ]]
  [[ "$output" != *"command not found"* ]]
  [[ "$output" != *"no such file"* ]]
  [[ "$output" != *"permission denied"* ]]
}

@test "interactive zsh wires starship zoxide atuin mise aliases" {
  run env -i HOME="$DEST/home" ZDOTDIR="$DEST/home/.config/zsh" PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin" \
      TERM=xterm-256color LANG=en_US.UTF-8 XDG_CACHE_HOME="$BATS_FILE_TMPDIR/cache" \
      zsh -ic 'print -l $precmd_functions | tr "\n" " "; whence -w __zoxide_z | tr "\n" " "; alias ls; alias cat'
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" == *"__zoxide_z: function"* ]]
  # starship 1.26+ 的 precmd 叫 prompt_starship_precmd，旧版叫 starship_precmd；都接受
  [[ "$output" == *"starship_precmd"* ]]
  [[ "$output" == *"_atuin_precmd"* ]]
  [[ "$output" == *"_mise_hook_precmd"* ]]
  [[ "$output" == *"eza"* ]]
  [[ "$output" == *"bat"* ]]
}

@test "fish config passes fish -n (skip if no fish)" {
  command -v fish >/dev/null || skip "fish not installed"
  run fish -n "$DEST/home/.config/fish/config.fish"
  [ "$status" -eq 0 ]
}

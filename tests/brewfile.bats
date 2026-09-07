#!/usr/bin/env bats
load helpers

setup_file() {
  export DEST="$BATS_FILE_TMPDIR/d"
  chifig_apply "$DEST" modules.gui=true modules.ghostty=true modules.fish=true
}

@test "every Brewfile parses with brew bundle list" {
  command -v brew >/dev/null || skip "brew not installed"
  for b in "$DEST"/home/.config/chifig/Brewfile.*; do
    run brew bundle list --file="$b" --all
    [ "$status" -eq 0 ] || { echo "$b: $output"; return 1; }
  done
}

@test "Brewfile.core excludes project-specific packages" {
  for bad in postgresql ta-lib kubo minikube mactex calibre opencode gemini-cli himalaya; do
    ! grep -q "$bad" "$DEST/home/.config/chifig/Brewfile.core" || { echo "core contains $bad"; return 1; }
  done
}

@test "Brewfile.core includes the 2026 mainstream CLI set" {
  for want in ripgrep fd bat eza zoxide fzf git-delta atuin jq btop yazi lazygit gh tmux mise uv starship antidote chezmoi just; do
    grep -q "\"$want\"" "$DEST/home/.config/chifig/Brewfile.core" || { echo "core missing $want"; return 1; }
  done
}

#!/usr/bin/env bats
load helpers

setup() { DEST="$BATS_TEST_TMPDIR/d"; }

@test "config renders with defaults: role and all module flags" {
  chifig_config "$DEST"
  run cat "$DEST/chezmoi.toml"
  [ "$status" -eq 0 ]
  [[ "$output" == *'role = "personal"'* ]]
  for m in ghostty claude editor gui fish macos keyboard; do
    [[ "$output" == *"$m = "* ]]
  done
}

@test "all modules off: only core files land" {
  chifig_apply "$DEST" modules.ghostty=false modules.claude=false modules.editor=false modules.gui=false modules.fish=false modules.macos=false modules.keyboard=false
  H="$DEST/home"
  for f in .zshenv .condarc .config/zsh/.zshrc .config/zsh/.zprofile .config/zsh/.zsh_plugins.txt \
           .config/zsh/local.zsh.example .config/git/config .config/git/ignore .config/starship.toml \
           .config/tmux/tmux.conf .config/mise/config.toml .config/atuin/config.toml \
           .config/chifig/Brewfile.core .config/chifig/npm-globals.txt; do
    [ -f "$H/$f" ] || { echo "missing $f"; return 1; }
  done
  for f in .config/ghostty .config/fish .claude Library .config/chifig/Brewfile.gui \
           .config/chifig/macos-defaults.sh .config/chifig/cursor-extensions.txt .config/chifig/keyboard-remap.sh; do
    [ ! -e "$H/$f" ] || { echo "unexpected $f"; return 1; }
  done
}

@test "all modules on: optional files land" {
  chifig_apply "$DEST" modules.ghostty=true modules.claude=true modules.editor=true modules.gui=true modules.fish=true modules.macos=true modules.keyboard=true
  H="$DEST/home"
  for f in .config/ghostty/config .config/fish/config.fish .claude/cc-tips.sh .claude/tips/ghostty.txt \
           "Library/Application Support/Cursor/User/settings.json" "Library/Application Support/Cursor/User/keybindings.json" \
           .config/chifig/Brewfile.gui .config/chifig/macos-defaults.sh .config/chifig/cursor-extensions.txt \
           .config/chifig/keyboard-remap.sh Library/LaunchAgents/com.chifig.keyboard-remap.plist; do
    [ -f "$H/$f" ] || { echo "missing $f"; return 1; }
  done
  [ -x "$H/.claude/cc-tips.sh" ]
  [ -x "$H/.config/chifig/macos-defaults.sh" ]
  [ -x "$H/.config/chifig/keyboard-remap.sh" ]
}

@test "keyboard on, editor off: LaunchAgent lands without Cursor settings" {
  chifig_apply "$DEST" modules.keyboard=true modules.editor=false
  H="$DEST/home"
  [ -f "$H/Library/LaunchAgents/com.chifig.keyboard-remap.plist" ]
  [ ! -e "$H/Library/Application Support" ]
  grep -q "/.config/chifig/keyboard-remap.sh</string>" "$H/Library/LaunchAgents/com.chifig.keyboard-remap.plist"
  grep -q '<key>RunAtLoad</key>' "$H/Library/LaunchAgents/com.chifig.keyboard-remap.plist"
}

@test "editor on, keyboard off: Cursor settings land without LaunchAgent" {
  chifig_apply "$DEST" modules.keyboard=false modules.editor=true
  H="$DEST/home"
  [ -f "$H/Library/Application Support/Cursor/User/settings.json" ]
  [ ! -e "$H/Library/LaunchAgents" ]
  [ ! -e "$H/.config/chifig/keyboard-remap.sh" ]
}

@test "git identity from init prompts renders into git config" {
  chifig_apply "$DEST" "git.name=Test User" "git.email=test@example.com"
  run cat "$DEST/home/.config/git/config"
  [[ "$output" == *"name = Test User"* ]]
  [[ "$output" == *"email = test@example.com"* ]]
}

@test "local.zsh is never managed" {
  chifig_apply "$DEST"
  run chifig_chezmoi "$DEST" managed
  [[ "$output" != *".config/zsh/local.zsh"$'\n'* ]]
  [[ "$output" != *".config/zsh/local.zsh" ]]
  [ ! -e "$DEST/home/.config/zsh/local.zsh" ]
}

@test "Brewfile.core includes ghostty and fish per module flags" {
  chifig_apply "$DEST" modules.ghostty=true modules.fish=true
  grep -q 'cask "ghostty"' "$DEST/home/.config/chifig/Brewfile.core"
  grep -q 'brew "fish"' "$DEST/home/.config/chifig/Brewfile.core"
  chifig_apply "$BATS_TEST_TMPDIR/e" modules.ghostty=false modules.fish=false
  ! grep -q 'ghostty' "$BATS_TEST_TMPDIR/e/home/.config/chifig/Brewfile.core"
  ! grep -q '"fish"' "$BATS_TEST_TMPDIR/e/home/.config/chifig/Brewfile.core"
}

@test "cc-tips.sh prints a tip from rendered HOME" {
  chifig_apply "$DEST" modules.claude=true
  run env HOME="$DEST/home" bash "$DEST/home/.claude/cc-tips.sh" <<< '{}'
  [ "$status" -eq 0 ]
  [[ "$output" == *"💡"* ]]
}

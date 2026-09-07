#!/usr/bin/env bats
load helpers

setup_file() {
  export DEST="$BATS_FILE_TMPDIR/d"
  chifig_config "$DEST" modules.macos=true modules.gui=true
}

@test "bootstrap.sh passes shellcheck and is wrapped in main" {
  run shellcheck -S warning "$REPO/bootstrap.sh"
  [ "$status" -eq 0 ]
  grep -q '^main()' "$REPO/bootstrap.sh"
  grep -q 'main "\$@"' "$REPO/bootstrap.sh"
}

@test "rendered chezmoi scripts pass shellcheck" {
  local n=0
  for t in "$REPO"/home/.chezmoiscripts/*; do
    n=$((n+1))
    out="$BATS_TEST_TMPDIR/$(basename "$t" .tmpl)"
    chezmoi --config "$DEST/chezmoi.toml" --source "$REPO" execute-template < "$t" > "$out"
    run shellcheck -S warning "$out"
    [ "$status" -eq 0 ] || { echo "$t: $output"; return 1; }
  done
  [ "$n" -ge 3 ]
}

@test "macos-defaults.sh passes shellcheck and uses no sudo" {
  run shellcheck -S warning "$REPO/home/dot_config/chifig/executable_macos-defaults.sh"
  [ "$status" -eq 0 ]
  ! grep -qE '(^|[;&| ])sudo ' "$REPO/home/dot_config/chifig/executable_macos-defaults.sh"
}

@test "justfile lists all recipes" {
  cd "$REPO"
  run just --list
  [ "$status" -eq 0 ]
  for r in bootstrap apply update diff test lint brew gui macos editor doctor backup unmanaged; do
    [[ "$output" == *"$r"* ]] || { echo "missing recipe $r"; return 1; }
  done
}

@test "brew bundle script hashes Brewfile.core for run_onchange" {
  grep -q 'Brewfile.core' "$REPO"/home/.chezmoiscripts/run_onchange_after_10-brew-bundle.sh.tmpl
  grep -q 'sha256sum' "$REPO"/home/.chezmoiscripts/run_onchange_after_10-brew-bundle.sh.tmpl
}

#!/usr/bin/env bats
load helpers

setup_file() {
  export DEST="$BATS_FILE_TMPDIR/d"
  chifig_config "$DEST" modules.macos=true modules.gui=true modules.keyboard=true
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
  for r in bootstrap apply update diff test lint brew gui macos editor keyboard doctor backup unmanaged; do
    [[ "$output" == *"$r"* ]] || { echo "missing recipe $r"; return 1; }
  done
}

@test "brew bundle script hashes Brewfile.core for run_onchange" {
  grep -q 'Brewfile.core' "$REPO"/home/.chezmoiscripts/run_onchange_after_10-brew-bundle.sh.tmpl
  grep -q 'sha256sum' "$REPO"/home/.chezmoiscripts/run_onchange_after_10-brew-bundle.sh.tmpl
}

# ---- keyboard-remap.sh：用假的 hidutil 记录参数，Linux / macOS 上都能跑 ----
kbd_setup() {
  KB="$BATS_TEST_TMPDIR/kb"; mkdir -p "$KB/bin" "$KB/home/.config/chifig"
  cat > "$KB/bin/hidutil" <<STUB
#!/bin/bash
if [ "\$1" = list ]; then printf 'VendorID ProductID Product\n0x5ac 0x281 %s\n' "\${FAKE_KBD:-USB Keyboard}"; exit 0; fi
printf '%s\n' "\$@" >> "$KB/calls"
STUB
  chmod +x "$KB/bin/hidutil"
}

@test "keyboard-remap.sh passes shellcheck and uses no sudo" {
  run shellcheck -S warning "$REPO/home/dot_config/chifig/executable_keyboard-remap.sh"
  [ "$status" -eq 0 ] || { echo "$output"; return 1; }
  ! grep -qE '(^|[;&| ])sudo ' "$REPO/home/dot_config/chifig/executable_keyboard-remap.sh"
}

@test "keyboard-remap apply maps Alt->Cmd and Win->Ctrl on both sides" {
  kbd_setup
  run env HOME="$KB/home" PATH="$KB/bin:$PATH" bash "$REPO/home/dot_config/chifig/executable_keyboard-remap.sh" apply
  [ "$status" -eq 0 ] || { echo "$output"; return 1; }
  json="$(grep UserKeyMapping "$KB/calls")"
  [[ "$json" == *'"HIDKeyboardModifierMappingSrc":0x7000000E2,"HIDKeyboardModifierMappingDst":0x7000000E3'* ]]
  [[ "$json" == *'"HIDKeyboardModifierMappingSrc":0x7000000E3,"HIDKeyboardModifierMappingDst":0x7000000E0'* ]]
  [[ "$json" == *'"HIDKeyboardModifierMappingSrc":0x7000000E6,"HIDKeyboardModifierMappingDst":0x7000000E7'* ]]
  [[ "$json" == *'"HIDKeyboardModifierMappingSrc":0x7000000E7,"HIDKeyboardModifierMappingDst":0x7000000E4'* ]]
  ! grep -q -- '--matching' "$KB/calls"
}

@test "keyboard-remap refuses global mapping when an internal keyboard exists" {
  kbd_setup
  run env HOME="$KB/home" PATH="$KB/bin:$PATH" FAKE_KBD="Apple Internal Keyboard / Trackpad" \
    bash "$REPO/home/dot_config/chifig/executable_keyboard-remap.sh" apply
  [ "$status" -ne 0 ]
  [ ! -f "$KB/calls" ]
}

@test "keyboard-remap scopes to one keyboard when keyboard.local sets IDs" {
  kbd_setup
  printf 'KBD_VENDOR_ID=0x046d\nKBD_PRODUCT_ID=0xc52b\nCTRL_TO_OPTION=1\n' > "$KB/home/.config/chifig/keyboard.local"
  run env HOME="$KB/home" PATH="$KB/bin:$PATH" FAKE_KBD="Apple Internal Keyboard" \
    bash "$REPO/home/dot_config/chifig/executable_keyboard-remap.sh" apply
  [ "$status" -eq 0 ] || { echo "$output"; return 1; }
  grep -qx -- '--matching' "$KB/calls"
  grep -q '"VendorID":0x046d,"ProductID":0xc52b' "$KB/calls"
  grep -q '"HIDKeyboardModifierMappingSrc":0x7000000E0,"HIDKeyboardModifierMappingDst":0x7000000E2' "$KB/calls"
}

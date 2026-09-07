#!/usr/bin/env bats
load helpers

@test "gitleaks finds nothing in the repo" {
  command -v gitleaks >/dev/null || skip "gitleaks not installed"
  cd "$REPO"
  run gitleaks dir . --no-banner --redact
  [ "$status" -eq 0 ]
}

@test "repo has no token prefixes, absolute home paths or internal hosts" {
  cd "$REPO"
  run git grep -nE 'gho_[A-Za-z0-9]{10,}|ghp_[A-Za-z0-9]{10,}|sk-[A-Za-z0-9]{20,}|/Users/chizhang|ec2-[0-9]+-[0-9]+|152\.136\.' -- ':!docs/*'
  [ "$status" -ne 0 ] || { echo "$output"; return 1; }
}

@test "rendered Cursor settings contain no ec2 hostnames" {
  DEST="$BATS_TEST_TMPDIR/d"
  chifig_apply "$DEST" modules.editor=true
  ! grep -q 'ec2-' "$DEST/home/Library/Application Support/Cursor/User/settings.json"
}

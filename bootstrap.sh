#!/bin/bash
# chifig bootstrap：裸 Mac → 一条命令 → 开发环境。
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/ChiChasesCheese/chifig/main/bootstrap.sh)"
# 可选环境变量：
#   CHIFIG_REPO   仓库（默认 ChiChasesCheese/chifig，可为本地路径）
#   CHIFIG_REF    分支/标签（默认 main）
#   CHIFIG_INIT_ARGS  传给 chezmoi init 的额外参数，例如 --promptDefaults 或 --promptBool modules.gui=true
# 整个脚本包在 main() 里：下载不完整时不会执行半截。
set -euo pipefail

say() { printf '\033[1;32m==> chifig:\033[0m %s\n' "$*"; }

need_macos() {
  [ "$(uname -s)" = "Darwin" ] || { echo "chifig 目前只支持 macOS" >&2; exit 1; }
}

ensure_clt() {
  if ! xcode-select -p >/dev/null 2>&1; then
    say "安装 Xcode Command Line Tools（会弹窗，完成后重跑本脚本）"
    xcode-select --install || true
    exit 1
  fi
}

ensure_brew() {
  if [ ! -x /opt/homebrew/bin/brew ]; then
    say "安装 Homebrew"
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  eval "$(/opt/homebrew/bin/brew shellenv)"
}

ensure_chezmoi() {
  command -v chezmoi >/dev/null 2>&1 || { say "安装 chezmoi"; brew install chezmoi; }
}

run_init() {
  local repo="${CHIFIG_REPO:-ChiChasesCheese/chifig}"
  local ref="${CHIFIG_REF:-main}"
  # shellcheck disable=SC2086
  set -- ${CHIFIG_INIT_ARGS:-}
  if [ -d "$repo/.git" ]; then
    say "chezmoi init --apply 本地仓库 $repo"
    chezmoi init --apply --source "$repo" "$@"
  else
    say "chezmoi init --apply $repo@$ref"
    chezmoi init --apply --branch "$ref" "$repo" "$@"
  fi
}

main() {
  need_macos
  ensure_clt
  ensure_brew
  ensure_chezmoi
  run_init
  say "完成。新开一个终端生效；可选模块用 'just gui' / 'just macos' / 'just editor' 触发。"
}

main "$@"

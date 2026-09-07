# 共享测试助手（bats）。所有测试都把仓库渲染到一个临时 HOME，绝不碰真实家目录。
REPO="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"
export REPO

# 用给定的 prompt 答案生成 chezmoi.toml。用法：chifig_config DEST key=value ...
# bool 值走 --promptBool，personal/work 走 --promptChoice，其余走 --promptString；未给的键取默认值。
chifig_config() {
  local dest="$1"; shift
  # 默认值（与 .chezmoi.toml.tmpl 一致），后面的参数覆盖前面的（bash 3.2 兼容，不用关联数组）
  local defaults="git.name= git.email= role=personal modules.ghostty=true modules.claude=true modules.editor=false modules.gui=false modules.fish=false modules.macos=false"
  local args=() d k v kv found
  for d in $defaults; do
    k="${d%%=*}"; v="${d#*=}"
    for kv in "$@"; do
      [ "${kv%%=*}" = "$k" ] && v="${kv#*=}"
    done
    case "$k" in
      modules.*) args+=(--promptBool "$k=$v") ;;
      role) args+=(--promptChoice "$k=$v") ;;
      *) args+=(--promptString "$k=$v") ;;
    esac
  done
  mkdir -p "$dest"
  chezmoi execute-template --init "${args[@]}" \
    < "$REPO/home/.chezmoi.toml.tmpl" > "$dest/chezmoi.toml"
}

# 在临时目录里跑 chezmoi 子命令：chifig_chezmoi DEST <subcommand...>
chifig_chezmoi() {
  local dest="$1"; shift
  mkdir -p "$dest/home" "$dest/cache"
  chezmoi --source "$REPO" --destination "$dest/home" --config "$dest/chezmoi.toml" \
    --persistent-state "$dest/state.boltdb" --cache "$dest/cache" --no-tty "$@"
}

# 渲染到 DEST/home（不执行脚本）。用法：chifig_apply DEST key=value ...
chifig_apply() {
  local dest="$1"; shift
  chifig_config "$dest" "$@"
  chifig_chezmoi "$dest" apply --force --exclude scripts
}

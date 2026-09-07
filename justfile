# chifig 任务入口。`just` 列出全部。
set shell := ["bash", "-euo", "pipefail", "-c"]

default:
    @just --list

# 裸机一键：CLT → Homebrew → chezmoi → init --apply（本地仓库）
bootstrap *ARGS:
    CHIFIG_REPO="{{justfile_directory()}}" CHIFIG_INIT_ARGS="{{ARGS}}" ./bootstrap.sh

# 把仓库应用到 ~（含 run_onchange 脚本）
apply *ARGS:
    chezmoi apply {{ARGS}}

# 拉取远端并应用
update:
    chezmoi update

# 查看将要发生的变更
diff:
    chezmoi diff

# 健康检查
doctor:
    chezmoi doctor
    chezmoi verify && echo "verify: ok"

# 全部测试（bats，渲染到临时目录，不碰真实 ~）
test *ARGS="tests":
    bats {{ARGS}}

# 静态检查：shellcheck + gitleaks + chezmoi 模板渲染
lint:
    shellcheck -S warning bootstrap.sh home/dot_config/chifig/executable_macos-defaults.sh
    gitleaks dir . --no-banner --redact
    just test tests/scripts.bats

# 只跑 core Brewfile
brew:
    brew bundle --file ~/.config/chifig/Brewfile.core --no-upgrade

# 安装 GUI 应用清单（需要 modules.gui = true）
gui:
    test -f ~/.config/chifig/Brewfile.gui || { echo "modules.gui 未开启：chezmoi edit-config 后 chezmoi apply"; exit 1; }
    brew bundle --file ~/.config/chifig/Brewfile.gui --no-upgrade

# 应用 macOS 系统偏好（需要 modules.macos = true）
macos:
    test -x ~/.config/chifig/macos-defaults.sh || { echo "modules.macos 未开启"; exit 1; }
    ~/.config/chifig/macos-defaults.sh

# 给 Cursor 装扩展清单（需要 modules.editor = true 且已装 cursor CLI）
editor:
    test -f ~/.config/chifig/cursor-extensions.txt || { echo "modules.editor 未开启"; exit 1; }
    command -v cursor >/dev/null || { echo "cursor CLI 不在 PATH（Cursor → Shell Command: Install）"; exit 1; }
    grep -vE '^(#|$)' ~/.config/chifig/cursor-extensions.txt | xargs -n1 cursor --install-extension

# 列出本机已装但未纳管的 brew 包（供人工决定去留）
unmanaged:
    @comm -23 <(brew leaves | sort) <(grep -hoE '^brew "[^"]+"' ~/.config/chifig/Brewfile.* | cut -d'"' -f2 | sort)

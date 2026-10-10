#!/bin/bash
# Windows 键盘在 Mac 上的修饰键重映射（模块 keyboard）。用系统自带的 hidutil，不装驱动、不要 sudo。
#
# macOS 默认把 Windows 键盘的 Win 键当 Command、Alt 当 Option（按 HID 码一一对应，不是“映射错了”）。
# 这里改成：
#   Alt → Command    （拇指位置按 Cmd，和 Mac 键盘一样顺手）
#   Win → Control
#   右侧同理：Right Alt → Right Command，Right Win → Right Control
#   物理 Ctrl 保持 Control。代价：没有键是 Option 了（需要的话在 keyboard.local 里设 CTRL_TO_OPTION=1）
#
# 用法：keyboard-remap.sh [apply|reset|status|list|uninstall]
#   apply      应用映射（LaunchAgent 登录时和每 60 秒跑一次，键盘拔插后自动恢复）
#   reset      清除映射（恢复系统默认）
#   status     查看当前映射
#   list       列出键盘及其 VendorID / ProductID
#   uninstall  卸载 LaunchAgent 并清除映射（关掉模块后用）
#
# 本机配置（不入库）：~/.config/chifig/keyboard.local
#   KBD_VENDOR_ID=0x046d     只对这把键盘生效（chifig 的 MacBook 内置键盘不受影响）
#   KBD_PRODUCT_ID=0xc52b
#   CTRL_TO_OPTION=1         可选：物理 Ctrl → Option
# 没配 VendorID/ProductID 时对所有键盘生效；如果检测到 Mac 内置键盘会拒绝执行，免得把笔记本键盘也改乱。
#
# 注意：别同时在「系统设置 → 键盘 → 键盘快捷键 → 修饰键」里改同一把键盘，两层映射叠加会很混乱。
set -euo pipefail

LCTRL=0x7000000E0 LALT=0x7000000E2 LGUI=0x7000000E3
RCTRL=0x7000000E4 RALT=0x7000000E6 RGUI=0x7000000E7
LABEL=com.chifig.keyboard-remap
CONF="$HOME/.config/chifig/keyboard.local"

KBD_VENDOR_ID="" KBD_PRODUCT_ID="" CTRL_TO_OPTION=0
# shellcheck disable=SC1090
[ -f "$CONF" ] && . "$CONF"

pair() { printf '{"HIDKeyboardModifierMappingSrc":%s,"HIDKeyboardModifierMappingDst":%s}' "$1" "$2"; }

mapping_json() {
  local m
  m="$(pair "$LALT" "$LGUI"),$(pair "$LGUI" "$LCTRL"),$(pair "$RALT" "$RGUI"),$(pair "$RGUI" "$RCTRL")"
  if [ "$CTRL_TO_OPTION" = 1 ]; then
    m="$m,$(pair "$LCTRL" "$LALT"),$(pair "$RCTRL" "$RALT")"
  fi
  printf '{"UserKeyMapping":[%s]}' "$m"
}

# 有配置就只匹配那把键盘；输出给 hidutil 的参数（每行一个）
matching_args() {
  if [ -n "$KBD_VENDOR_ID" ] && [ -n "$KBD_PRODUCT_ID" ]; then
    printf '%s\n' --matching "{\"VendorID\":$KBD_VENDOR_ID,\"ProductID\":$KBD_PRODUCT_ID}"
  fi
}

hid() {
  local args=()
  while IFS= read -r a; do [ -n "$a" ] && args+=("$a"); done < <(matching_args)
  hidutil property ${args[@]+"${args[@]}"} "$@"
}

has_internal_keyboard() { hidutil list 2>/dev/null | grep -qi 'internal keyboard'; }

case "${1:-apply}" in
  apply)
    if [ -z "$KBD_VENDOR_ID" ] && has_internal_keyboard; then
      echo "检测到 Mac 内置键盘：请先在 $CONF 里设 KBD_VENDOR_ID / KBD_PRODUCT_ID（$0 list 查看），否则内置键盘也会被改。" >&2
      exit 1
    fi
    hid --set "$(mapping_json)" >/dev/null
    ;;
  reset)
    hid --set '{"UserKeyMapping":[]}' >/dev/null
    echo "已清除映射"
    ;;
  status)
    hid --get UserKeyMapping
    ;;
  list)
    hidutil list | awk 'NR <= 2 || tolower($0) ~ /keyboard/'
    ;;
  uninstall)
    launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
    mv "$HOME/Library/LaunchAgents/$LABEL.plist" "$HOME/.local/state/" 2>/dev/null || true
    hid --set '{"UserKeyMapping":[]}' >/dev/null
    echo "已卸载 LaunchAgent（plist 挪到 ~/.local/state/）并清除映射"
    ;;
  *)
    sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'
    exit 1
    ;;
esac

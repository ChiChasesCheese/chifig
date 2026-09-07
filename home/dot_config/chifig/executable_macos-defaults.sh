#!/bin/bash
# chifig macOS 系统偏好。幂等，无 sudo，只改用户级 defaults。执行：just macos
# 每条的 key 与取值参考 https://macos-defaults.com（2026 Tahoe 上验证过的条目）。
set -euo pipefail

echo "==> Finder"
defaults write NSGlobalDomain AppleShowAllExtensions -bool true        # 显示所有扩展名
defaults write com.apple.finder ShowPathbar -bool true                  # 路径栏
defaults write com.apple.finder ShowStatusBar -bool true                # 状态栏
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"     # 默认列表视图
defaults write com.apple.finder _FXSortFoldersFirst -bool true          # 文件夹置顶
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"     # 搜索当前文件夹
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true  # 网络盘不写 .DS_Store

echo "==> Keyboard"
defaults write NSGlobalDomain KeyRepeat -int 2                          # 按键重复最快
defaults write NSGlobalDomain InitialKeyRepeat -int 15                  # 重复延迟最短
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false      # 长按出重复而非重音菜单
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

echo "==> Dock"
defaults write com.apple.dock show-recents -bool false                  # 不显示最近应用
defaults write com.apple.dock autohide-delay -float 0                   # 自动隐藏无延迟

echo "==> Screenshots"
mkdir -p "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture disable-shadow -bool true

echo "==> Dialogs"
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true   # 保存面板默认展开
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false   # 新文档默认存本地

echo "==> Applying (restart Finder/Dock/SystemUIServer)"
for app in Finder Dock SystemUIServer; do killall "$app" >/dev/null 2>&1 || true; done
echo "done. 部分键盘设置需注销后生效。"

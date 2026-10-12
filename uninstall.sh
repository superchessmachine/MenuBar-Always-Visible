#!/bin/bash
# Removes MenuBar-Always-Visible and restores your previous menu bar setting.
set -uo pipefail
APP="$HOME/Library/Application Support/MenuBarAlwaysVisible"
BIN="$APP/menubar-always-visible"
PLIST="$HOME/Library/LaunchAgents/com.menubar-always-visible.plist"

launchctl unload "$PLIST" 2>/dev/null; rm -f "$PLIST"
orig=$(cat "$APP/original-pref" 2>/dev/null || echo unset)
if [ "$orig" = unset ]; then defaults delete com.apple.controlcenter AutoHideMenuBarOption 2>/dev/null
else defaults write com.apple.controlcenter AutoHideMenuBarOption -int "$orig"; fi
if [ -x "$BIN" ]; then
  "$BIN" --reset 2>/dev/null
  # if the original setting showed the bar on the desktop, show it everywhere right now
  case "$orig" in 2|3|unset) "$BIN" --show-all 2>/dev/null ;; esac
fi
rm -rf "$APP" "$HOME/Library/Logs/menubar-always-visible.log"
echo "Uninstalled. Your previous menu bar setting is restored (fully applied after your next login)."

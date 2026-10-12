#!/bin/bash
# Installs MenuBar-Always-Visible for the current user (no sudo).
set -euo pipefail
cd "$(dirname "$0")"
APP="$HOME/Library/Application Support/MenuBarAlwaysVisible"
BIN="$APP/menubar-always-visible"
LABEL="com.menubar-always-visible"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
LOG="$HOME/Library/Logs/menubar-always-visible.log"

if ! xcrun -f swiftc >/dev/null 2>&1; then
  echo "Needs the Swift compiler. Install Xcode Command Line Tools first:  xcode-select --install" >&2
  exit 1
fi

mkdir -p "$APP" "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
echo "Compiling..."
xcrun swiftc -O MenuBarAlwaysVisible.swift -o "$BIN"

# remember the user's original setting so uninstall can restore it
if [ ! -f "$APP/original-pref" ]; then
  defaults read com.apple.controlcenter AutoHideMenuBarOption 2>/dev/null > "$APP/original-pref" || echo unset > "$APP/original-pref"
fi

cat > "$PLIST" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key><array><string>$BIN</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardErrorPath</key><string>$LOG</string>
  <key>StandardOutPath</key><string>$LOG</string>
</dict></plist>
PL
launchctl unload "$PLIST" 2>/dev/null || true
launchctl load "$PLIST"

echo
echo "Installed and running. One last step (macOS only applies this setting live from System Settings):"
echo "  In the window that just opened, set 'Automatically hide and show the menu bar' to: Always"
echo "  (If it already says Always, pick anything else and then Always again.)"
echo "After that your laptop screen keeps its menu bar and external monitors auto-hide theirs."
echo "Skipping this step is fine too; it takes effect on its own after your next login."
open "x-apple.systempreferences:com.apple.ControlCenter-Settings.extension" 2>/dev/null || true

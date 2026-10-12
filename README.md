# MenuBar-Always-Visible

Keep the macOS menu bar **always visible on your MacBook's built-in screen** while it
**auto-hides on external monitors** — at the same time, with nothing to toggle when you
dock or undock.

macOS only offers one global "Automatically hide and show the menu bar" setting. This tool
keeps that setting on *Always* and pins the built-in display's menu bar visible using a
per-display override in the system window server, re-applied automatically at login and
whenever your displays change.

## Install

Requires the Xcode Command Line Tools (`xcode-select --install`) for the Swift compiler.
No sudo, nothing outside your home folder.

```sh
git clone https://github.com/superchessmachine/MenuBar-Always-Visible.git
cd MenuBar-Always-Visible
./install.sh
```

The installer opens **System Settings → Menu Bar**. Set *Automatically hide and show the
menu bar* to **Always** there once (macOS only applies this setting live from System
Settings; if you skip it, it simply takes effect after your next login).

That's it. It runs as a user LaunchAgent and starts automatically at login.

## Uninstall

```sh
./uninstall.sh
```

Restores whatever menu bar setting you had before.

## How it works

- `MenuBarAlwaysVisible.swift` is a tiny background program. Every 10 seconds it checks
  which displays are connected (one cheap system call, negligible battery) and, when the set
  changes — or once a minute as a safety net for sleep/wake — pins the built-in display's
  menu bar visible via SkyLight's `SLSSetMenuBarVisibilityOverrideOnDisplay`.
- With the global setting on *Always*, every other display auto-hides its menu bar as usual.
- Logs: `~/Library/Logs/menubar-always-visible.log`.

## Caveats

- Uses a **private Apple API**. Tested on macOS 26 (Tahoe) on Apple Silicon. A future macOS
  update could change it; the failure mode is just the laptop's bar hiding like the others.
- The per-display override can only force a bar *visible*, not hidden — which is why the
  global setting must be *Always*.

## License

MIT

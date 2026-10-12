import Foundation
import CoreGraphics

// MenuBar-Always-Visible
// Keeps the macOS menu bar always visible on the built-in (laptop) display while it
// auto-hides on external monitors.
//
// How: macOS's "Automatically hide and show the menu bar" is global, so we set it to
// "Always" (hides everywhere) and then pin the BUILT-IN display visible using a private
// SkyLight per-display override. WindowServer forgets the override at login, so this runs
// as a LaunchAgent and re-applies it at launch, whenever the set of displays changes, and
// once a minute as a safety net (sleep/wake). A 10s poll is used because display
// reconfiguration callbacks are not delivered to a launchd agent.
//
// Usage: menubar-always-visible            (run forever; what the LaunchAgent does)
//        menubar-always-visible --reset    (clear the override; used by uninstall)
//        menubar-always-visible --show-all (force the bar visible on every display now)

let sl = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_NOW)!
typealias CID = @convention(c) () -> Int32
typealias SetOvr = @convention(c) (Int32, UInt32, Int32) -> Int32
let cid = unsafeBitCast(dlsym(sl, "SLSMainConnectionID"), to: CID.self)()
let setOverride = unsafeBitCast(dlsym(sl, "SLSSetMenuBarVisibilityOverrideOnDisplay"), to: SetOvr.self)

func onlineDisplays() -> [CGDirectDisplayID] {
    var n: UInt32 = 0; CGGetOnlineDisplayList(0, nil, &n)
    var ids = [CGDirectDisplayID](repeating: 0, count: Int(n)); CGGetOnlineDisplayList(n, &ids, &n)
    return Array(ids.prefix(Int(n)))
}
func log(_ s: String) { FileHandle.standardError.write((s + "\n").data(using: .utf8)!) }

let args = CommandLine.arguments.dropFirst()
if args.contains("--reset") {
    for d in onlineDisplays() { _ = setOverride(cid, d, 0) }
    log("override cleared on all displays"); exit(0)
}
if args.contains("--show-all") {
    for d in onlineDisplays() { _ = setOverride(cid, d, 1) }
    log("menu bar forced visible on all displays"); exit(0)
}

func apply(_ ids: [CGDirectDisplayID]) {
    // Global mode must be "Always" (0) so external displays auto-hide. Writing it here only
    // guarantees the state after the next login; System Settings is what applies it live.
    UserDefaults(suiteName: "com.apple.controlcenter")?.set(0, forKey: "AutoHideMenuBarOption")
    for d in ids where CGDisplayIsBuiltin(d) != 0 {
        let err = setOverride(cid, d, 1)  // 1 = force visible on this display, 0 = clear
        log("pinned built-in display \(d) visible (err \(err)); \(ids.count) display(s) online")
    }
}

var last: [CGDirectDisplayID] = []
var tick = 0
while true {
    let now = onlineDisplays()
    if now != last || tick % 6 == 0 { apply(now); last = now }
    tick += 1
    Thread.sleep(forTimeInterval: 10)
}

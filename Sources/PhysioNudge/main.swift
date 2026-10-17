import AppKit

// Entry point: run as a pure background/menu-bar app
// (.accessory = no Dock icon, not activatable via the menu bar).

// NSApplication.delegate is a *weak* reference. Keeping the delegate in a
// global (not a local in the top-level statements below) guarantees it
// stays alive for the whole process lifetime — otherwise menu targets
// can dangle and menu items silently stop working.
var appDelegate: AppDelegate?

let app = NSApplication.shared
appDelegate = AppDelegate()
app.delegate = appDelegate
app.setActivationPolicy(.accessory)
app.run()

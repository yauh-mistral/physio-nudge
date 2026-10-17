import AppKit

// Einstiegspunkt: als reines Hintergrund-/Menüleisten-Programm starten
// (.accessory = kein Dock-Icon, keine Aktivierung über die Menüleiste).
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()

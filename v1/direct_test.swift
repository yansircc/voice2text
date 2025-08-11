import Cocoa

print("🚀 Direct test starting...")

// Test creating a status bar item directly
let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

if let button = statusItem.button {
    button.title = "DIRECT"
    print("✅ Status bar item created with title 'DIRECT'")
    
    // Create a simple menu
    let menu = NSMenu()
    menu.addItem(NSMenuItem(title: "Direct Test", action: nil, keyEquivalent: ""))
    menu.addItem(NSMenuItem.separator())
    menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    statusItem.menu = menu
    
    print("✅ Menu created")
    print("📱 Look for 'DIRECT' in your menu bar")
    
    // Run the app loop
    NSApp.setActivationPolicy(.accessory)
    NSApp.run()
} else {
    print("❌ Failed to create status bar item")
}
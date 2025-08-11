import Cocoa

class TestApp: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 Test app starting...")
        
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if statusItem == nil {
            print("❌ Could not create status item")
            return
        } else {
            print("✅ Status item created successfully")
        }
        
        if let button = statusItem?.button {
            button.title = "TEST"
            button.action = #selector(statusBarButtonClicked)
            button.target = self
            print("✅ Button title set to 'TEST'")
        } else {
            print("❌ Could not get status item button")
        }
        
        // Create menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Test App", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Click me", action: #selector(testAction), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem?.menu = menu
        
        print("✅ Status bar item created")
        print("📱 Look for 🎤 in your menu bar!")
        
        // Keep app running
        NSApp.setActivationPolicy(.accessory)
    }
    
    @objc func statusBarButtonClicked() {
        print("Status bar clicked!")
    }
    
    @objc func testAction() {
        print("Test action triggered!")
        
        let alert = NSAlert()
        alert.messageText = "Test Successful!"
        alert.informativeText = "The app is working. Check console for debug output."
        alert.runModal()
    }
}

// Run the app
let app = NSApplication.shared
let delegate = TestApp()
app.delegate = delegate
app.run()
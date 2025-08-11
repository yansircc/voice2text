import Cocoa

protocol StatusBarControllerDelegate: AnyObject {
    func statusBarControllerDidSelectPreferences(_ controller: StatusBarController)
    func statusBarControllerDidSelectAbout(_ controller: StatusBarController)
    func statusBarControllerDidSelectQuit(_ controller: StatusBarController)
}

class StatusBarController {
    weak var delegate: StatusBarControllerDelegate?
    
    private var statusItem: NSStatusItem?
    private var statusMenuItem: NSMenuItem?
    
    init() {
        setupStatusBar()
    }
    
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "Voice2Text")
            button.toolTip = "Voice2Text - Hold Fn to record"
        }
        
        setupMenu()
    }
    
    private func setupMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Voice2Text v1.0", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        statusMenuItem = NSMenuItem(title: "Ready", action: nil, keyEquivalent: "")
        statusMenuItem?.tag = 1001
        menu.addItem(statusMenuItem!)
        
        menu.addItem(NSMenuItem.separator())
        
        let preferencesItem = NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ",")
        preferencesItem.target = self
        menu.addItem(preferencesItem)
        
        let aboutItem = NSMenuItem(title: "About", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    func updateStatus(_ state: RecordingState) {
        DispatchQueue.main.async {
            self.statusMenuItem?.title = state.statusText
            
            // Update icon based on state
            if let button = self.statusItem?.button {
                button.image = NSImage(
                    systemSymbolName: state.iconName,
                    accessibilityDescription: state.statusText
                )
            }
        }
    }
    
    func updateStatusText(_ text: String) {
        DispatchQueue.main.async {
            self.statusMenuItem?.title = text
        }
    }
    
    @objc private func showPreferences() {
        delegate?.statusBarControllerDidSelectPreferences(self)
    }
    
    @objc private func showAbout() {
        delegate?.statusBarControllerDidSelectAbout(self)
    }
    
    @objc private func quit() {
        delegate?.statusBarControllerDidSelectQuit(self)
    }
}
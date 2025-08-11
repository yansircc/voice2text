import Cocoa
import AVFoundation

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var keyboardMonitor: GlobalKeyboardMonitor?
    private var audioEngine: AudioEngine?
    private var whisperService: WhisperService?
    private var isRecording = false
    private var preferencesWindowController: PreferencesWindowController?
    private var lastInsertedText: String = ""
    private var undoManager = UndoManager()
    private var placeholderRemoved = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon for menu bar app
        NSApp.setActivationPolicy(.accessory)
        
        // Setup hidden Edit menu for copy/paste support
        setupEditMenu()
        
        // Check for required permissions
        checkPermissions()
        
        // Initialize services
        setupServices()
        
        // Setup status bar
        setupStatusBar()
        
        // Start monitoring keyboard
        startKeyboardMonitoring()
        
        // Listen for preference changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(preferencesDidChange),
            name: .preferencesDidChange,
            object: nil
        )
    }
    
    private func checkPermissions() {
        // Check microphone permission
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            if !granted {
                DispatchQueue.main.async {
                    self.showPermissionAlert(for: "Microphone")
                }
            }
        }
        
        // Check accessibility permission
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        
        if !accessEnabled {
            showPermissionAlert(for: "Accessibility")
        }
    }
    
    private func setupServices() {
        // Load configuration
        DotEnv.load(from: "../.env")
        
        let configuration = WhisperConfiguration()
        whisperService = WhisperService(configuration: configuration)
        audioEngine = AudioEngine()
        audioEngine?.delegate = self
    }
    
    private func setupEditMenu() {
        // Create a hidden Edit menu to enable copy/paste shortcuts
        let mainMenu = NSMenu()
        NSApp.mainMenu = mainMenu
        
        let editMenuItem = NSMenuItem()
        editMenuItem.title = "Edit"
        mainMenu.addItem(editMenuItem)
        
        let editMenu = NSMenu(title: "Edit")
        editMenuItem.submenu = editMenu
        
        // Add standard edit menu items
        editMenu.addItem(withTitle: "Undo", action: #selector(UndoManager.undo), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: #selector(UndoManager.redo), keyEquivalent: "Z")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        
        // The menu is hidden but still functional for keyboard shortcuts
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
        
        let statusMenuItem = NSMenuItem(title: "Ready", action: nil, keyEquivalent: "")
        statusMenuItem.tag = 1001
        menu.addItem(statusMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "About", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    private func startKeyboardMonitoring() {
        keyboardMonitor = GlobalKeyboardMonitor()
        keyboardMonitor?.delegate = self
        keyboardMonitor?.start()
    }
    
    private func showPermissionAlert(for permission: String) {
        let alert = NSAlert()
        alert.messageText = "\(permission) Permission Required"
        alert.informativeText = "Voice2Text needs \(permission) permission to work. Please grant access in System Settings."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            if permission == "Accessibility" {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            } else {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")!)
            }
        }
    }
    
    @objc private func showPreferences() {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController()
        }
        preferencesWindowController?.showWindow(nil)
    }
    
    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Voice2Text v1.0"
        alert.informativeText = "A global voice-to-text tool powered by Whisper AI.\n\nPress and hold Fn to record, release to transcribe."
        alert.alertStyle = .informational
        alert.runModal()
    }
    
    @objc private func preferencesDidChange() {
        // Reload configuration and reinitialize WhisperService
        let configuration = WhisperConfiguration()
        whisperService = WhisperService(configuration: configuration)
        updateStatus("Configuration updated")
        
        // Reset to ready after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.updateStatus("Ready")
        }
    }
    
    private func updateStatus(_ text: String) {
        DispatchQueue.main.async {
            if let menu = self.statusItem?.menu,
               let statusItem = menu.item(withTag: 1001) {
                statusItem.title = text
            }
            
            // Update icon based on status
            if text.contains("Recording") {
                self.statusItem?.button?.image = NSImage(systemSymbolName: "mic.circle.fill", accessibilityDescription: "Recording")
            } else {
                self.statusItem?.button?.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "Ready")
            }
        }
    }
}

// MARK: - GlobalKeyboardMonitorDelegate
extension AppDelegate: GlobalKeyboardMonitorDelegate {
    func keyboardMonitor(_ monitor: GlobalKeyboardMonitor, fnKeyPressed: Bool) {
        if fnKeyPressed && !isRecording {
            startRecording()
        } else if !fnKeyPressed && isRecording {
            stopRecording()
        }
    }
}

// MARK: - WhisperServiceDelegate
extension AppDelegate: WhisperServiceDelegate {
    func whisperService(_ service: WhisperService, didReceivePartialTranscription text: String) {
        // print("DEBUG AppDelegate: Received partial transcription: \(text)")
        // Remove placeholder on first chunk only
        DispatchQueue.main.async {
            if !self.placeholderRemoved && !text.isEmpty {
                // print("DEBUG AppDelegate: Removing placeholder")
                self.placeholderRemoved = true
                self.removePlaceholderText()
            }
            
            // Insert the partial transcription immediately
            // print("DEBUG AppDelegate: Inserting text: \(text)")
            self.insertTextAtCursor(text)
        }
    }
    
    func whisperService(_ service: WhisperService, didCompleteTranscription text: String) {
        print("DEBUG AppDelegate: Transcription completed: \(text)")
        DispatchQueue.main.async {
            // If we haven't removed placeholder yet, do it now
            if !self.placeholderRemoved {
                self.placeholderRemoved = true
                self.removePlaceholderText()
            }
            
            // Insert text directly without streaming effect
            if !text.isEmpty {
                self.insertTextAtCursor(text)
            }
            
            self.updateStatus("Transcription completed")
            
            // Reset to ready after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.updateStatus("Ready")
            }
        }
    }
    
    func whisperService(_ service: WhisperService, didFailWithError error: Error) {
        print("DEBUG AppDelegate: Transcription failed: \(error)")
        DispatchQueue.main.async {
            // Remove placeholder on error
            if !self.placeholderRemoved {
                self.placeholderRemoved = true
                self.removePlaceholderText()
            }
            self.updateStatus("Error: \(error.localizedDescription)")
            
            // Reset to ready after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.updateStatus("Ready")
            }
        }
    }
}

// MARK: - AudioEngineDelegate
extension AppDelegate: AudioEngineDelegate {
    func audioEngine(_ engine: AudioEngine, didCaptureBuffer buffer: AVAudioPCMBuffer) {
        // Buffer is handled internally by AudioEngine
    }
    
    func audioEngineDidStartRecording(_ engine: AudioEngine) {
        isRecording = true
        updateStatus("Recording...")
        
        // Haptic feedback
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
    }
    
    func audioEngineDidStopRecording(_ engine: AudioEngine) {
        isRecording = false
        updateStatus("Processing...")
    }
    
    private func startRecording() {
        do {
            try audioEngine?.startRecording()
            // Insert recording indicator text
            DispatchQueue.main.async {
                self.insertPlaceholderText("[正在录音...]")
            }
        } catch {
            print("Failed to start recording: \(error)")
            updateStatus("Error: \(error.localizedDescription)")
        }
    }
    
    private func stopRecording() {
        guard let audioData = audioEngine?.stopRecording() else {
            updateStatus("Ready")
            return
        }
        
        // First remove the recording indicator
        DispatchQueue.main.async {
            self.removePlaceholderText("[正在录音...]")
            
            // Then insert the processing indicator
            self.insertPlaceholderText("[转录中...]")
        }
        
        // Reset placeholder flag
        placeholderRemoved = false
        
        // Set self as delegate to receive streaming updates
        whisperService?.delegate = self
        
        // Use streaming transcription
        whisperService?.transcribeStreaming(audioData: audioData)
    }
    
    @MainActor
    private func insertPlaceholderText(_ placeholder: String) {
        // Insert placeholder text at cursor
        let source = CGEventSource(stateID: .combinedSessionState)
        
        for character in placeholder {
            if let event = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true) {
                let utf16Chars = Array(String(character).utf16)
                event.keyboardSetUnicodeString(stringLength: utf16Chars.count, unicodeString: utf16Chars)
                event.post(tap: .cgAnnotatedSessionEventTap)
            }
        }
    }
    
    @MainActor
    private func removePlaceholderText(_ text: String = "[转录中...]") {
        // Delete exactly the number of characters we inserted
        let placeholderLength = text.count
        let source = CGEventSource(stateID: .combinedSessionState)
        
        // Use backspace to delete the placeholder text
        let deleteKey: CGKeyCode = 0x33 // Delete/Backspace key
        
        for _ in 0..<placeholderLength {
            if let deleteEvent = CGEvent(keyboardEventSource: source, virtualKey: deleteKey, keyDown: true) {
                deleteEvent.post(tap: .cgAnnotatedSessionEventTap)
            }
            if let deleteEventUp = CGEvent(keyboardEventSource: source, virtualKey: deleteKey, keyDown: false) {
                deleteEventUp.post(tap: .cgAnnotatedSessionEventTap)
            }
            // Small delay between deletions
            Thread.sleep(forTimeInterval: 0.01)
        }
    }
    
    @MainActor
    private func insertTextAtCursor(_ text: String) {
        // Store for undo support
        lastInsertedText = text
        
        // Use pasteboard method for better undo support
        let source = CGEventSource(stateID: .combinedSessionState)
        
        // Save current pasteboard content
        let previousContent = NSPasteboard.general.string(forType: .string)
        
        // Set new content
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        
        // Simulate Cmd+V
        let vKey: CGKeyCode = 0x09
        if let pasteEvent = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: true) {
            pasteEvent.flags = .maskCommand
            pasteEvent.post(tap: .cgAnnotatedSessionEventTap)
        }
        
        if let pasteEventUp = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: false) {
            pasteEventUp.flags = .maskCommand
            pasteEventUp.post(tap: .cgAnnotatedSessionEventTap)
        }
        
        // Restore previous pasteboard content after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let previousContent = previousContent {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(previousContent, forType: .string)
            }
        }
    }
}
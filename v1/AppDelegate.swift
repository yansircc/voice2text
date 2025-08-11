import Cocoa
import AVFoundation

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var keyboardMonitor: GlobalKeyboardMonitor?
    private var audioEngine: AudioEngine?
    private var whisperService: WhisperService?
    private var isRecording = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 Voice2Text starting...")
        
        // Hide dock icon for menu bar app
        NSApp.setActivationPolicy(.accessory)
        print("✅ Set as menu bar app")
        
        // Check for required permissions
        checkPermissions()
        
        // Initialize services
        setupServices()
        
        // Setup status bar
        setupStatusBar()
        print("✅ Status bar setup complete")
        
        // Start monitoring keyboard
        startKeyboardMonitoring()
        print("✅ Keyboard monitoring started")
        print("📱 App is ready! Look for the microphone icon in your menu bar")
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
        print("📂 Loading configuration...")
        DotEnv.load(from: "../.env")
        
        let configuration = WhisperConfiguration()
        print("🔑 API Key: \(configuration.apiKey.isEmpty ? "❌ NOT SET" : "✅ SET")")
        print("🌐 Base URL: \(configuration.baseURL)")
        print("🤖 Model: \(configuration.modelId)")
        
        whisperService = WhisperService(configuration: configuration)
        audioEngine = AudioEngine()
        audioEngine?.delegate = self
        print("✅ Services initialized")
    }
    
    private func setupStatusBar() {
        print("📍 Setting up status bar...")
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if statusItem == nil {
            print("❌ Could not create status item")
            return
        } else {
            print("✅ Status item created successfully")
        }
        
        if let button = statusItem?.button {
            // Try text first instead of SF Symbol
            button.title = "V2T"
            button.toolTip = "Voice2Text - Press Fn to record"
            print("✅ Status bar button configured with text 'V2T'")
        } else {
            print("❌ Could not get status item button")
        }
        
        setupMenu()
    }
    
    private func setupMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Voice2Text v1.0", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        let statusMenuItem = NSMenuItem(title: "Status: Ready", action: nil, keyEquivalent: "")
        statusMenuItem.tag = 1001  // Use tag instead of identifier for simpler access
        menu.addItem(statusMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let hotkeyMenuItem = NSMenuItem(title: "Hotkey: Fn (hold to record)", action: nil, keyEquivalent: "")
        menu.addItem(hotkeyMenuItem)
        
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
        // TODO: Implement preferences window
        print("Preferences window not yet implemented")
    }
    
    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Voice2Text v1.0"
        alert.informativeText = "A global voice-to-text tool powered by Whisper AI.\n\nPress and hold Fn to record, release to transcribe."
        alert.alertStyle = .informational
        alert.runModal()
    }
    
    private func updateStatus(_ text: String) {
        DispatchQueue.main.async {
            if let menu = self.statusItem?.menu,
               let statusItem = menu.item(withTag: 1001) {
                statusItem.title = "Status: \(text)"
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
        
        // Process audio with Whisper
        Task {
            do {
                let transcription = try await whisperService?.transcribe(audioData: audioData) ?? ""
                
                if !transcription.isEmpty {
                    await insertTextAtCursor(transcription)
                    updateStatus("Transcribed: \(transcription.prefix(30))...")
                } else {
                    updateStatus("No speech detected")
                }
                
                // Reset to ready after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.updateStatus("Ready")
                }
            } catch {
                print("Transcription error: \(error)")
                updateStatus("Error: \(error.localizedDescription)")
            }
        }
    }
    
    @MainActor
    private func insertTextAtCursor(_ text: String) {
        // Method 1: Simulate typing
        let source = CGEventSource(stateID: .combinedSessionState)
        
        for character in text {
            if let event = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true) {
                let utf16Chars = Array(String(character).utf16)
                event.keyboardSetUnicodeString(stringLength: utf16Chars.count, unicodeString: utf16Chars)
                event.post(tap: .cgAnnotatedSessionEventTap)
            }
        }
        
        // Alternative Method 2: Use pasteboard
        // NSPasteboard.general.clearContents()
        // NSPasteboard.general.setString(text, forType: .string)
        // // Simulate Cmd+V
        // let vKey: CGKeyCode = 0x09
        // let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: true)
        // cmdDown?.flags = .maskCommand
        // cmdDown?.post(tap: .cgAnnotatedSessionEventTap)
    }
}
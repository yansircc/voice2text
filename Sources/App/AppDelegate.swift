import Cocoa
import AVFoundation

class AppDelegate: NSObject, NSApplicationDelegate {
    // UI Components
    private var statusBarController: StatusBarController?
    private var preferencesWindowController: PreferencesWindowController?
    
    // Core Services
    private var recordingCoordinator: RecordingCoordinator?
    private var keyboardMonitor: GlobalKeyboardMonitor?
    
    // Services
    private var audioEngine: AudioEngine?
    private var whisperService: WhisperService?
    private var textInsertionService: TextInsertionService?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon for menu bar app
        NSApp.setActivationPolicy(.accessory)
        
        // Setup hidden Edit menu for copy/paste support
        setupEditMenu()
        
        // Initialize configuration
        _ = ConfigurationManager.shared
        
        // Check for required permissions
        checkPermissions()
        
        // Initialize services
        setupServices()
        
        // Setup UI
        setupUI()
        
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
        PermissionManager.shared.checkAndRequestPermissions { [weak self] allGranted in
            if !allGranted {
                print("Not all permissions granted. Some features may not work.")
            }
        }
    }
    
    private func setupServices() {
        // Initialize core services
        audioEngine = AudioEngine()
        
        let configuration = ConfigurationManager.shared.loadWhisperConfiguration()
        whisperService = WhisperService(configuration: configuration)
        
        textInsertionService = TextInsertionService()
        
        // Initialize coordinator
        recordingCoordinator = RecordingCoordinator(
            audioEngine: audioEngine!,
            whisperService: whisperService!,
            textInsertion: textInsertionService!
        )
        recordingCoordinator?.delegate = self
    }
    
    private func setupUI() {
        // Setup status bar
        statusBarController = StatusBarController()
        statusBarController?.delegate = self
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
    }
    
    private func startKeyboardMonitoring() {
        keyboardMonitor = GlobalKeyboardMonitor()
        keyboardMonitor?.delegate = self
        keyboardMonitor?.start()
    }
    
    @objc private func preferencesDidChange() {
        // Reload configuration and reinitialize WhisperService
        let configuration = ConfigurationManager.shared.loadWhisperConfiguration()
        whisperService = WhisperService(configuration: configuration)
        
        // Update coordinator with new service
        if let audioEngine = audioEngine,
           let whisperService = whisperService,
           let textInsertionService = textInsertionService {
            recordingCoordinator = RecordingCoordinator(
                audioEngine: audioEngine,
                whisperService: whisperService,
                textInsertion: textInsertionService
            )
            recordingCoordinator?.delegate = self
        }
        
        statusBarController?.updateStatusText("Configuration updated")
        
        // Reset to ready after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.statusBarController?.updateStatus(.idle)
        }
    }
}

// MARK: - GlobalKeyboardMonitorDelegate
extension AppDelegate: GlobalKeyboardMonitorDelegate {
    func keyboardMonitor(_ monitor: GlobalKeyboardMonitor, fnKeyPressed: Bool) {
        if fnKeyPressed {
            recordingCoordinator?.startRecording()
        } else {
            recordingCoordinator?.stopRecording()
        }
    }
}

// MARK: - RecordingCoordinatorDelegate
extension AppDelegate: RecordingCoordinatorDelegate {
    func recordingCoordinator(_ coordinator: RecordingCoordinator, didChangeState state: RecordingState) {
        statusBarController?.updateStatus(state)
    }
    
    func recordingCoordinator(_ coordinator: RecordingCoordinator, didReceiveTranscription text: String) {
        // Handle completed transcription if needed
        print("Transcription completed: \(text)")
    }
}

// MARK: - StatusBarControllerDelegate
extension AppDelegate: StatusBarControllerDelegate {
    func statusBarControllerDidSelectPreferences(_ controller: StatusBarController) {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController()
        }
        preferencesWindowController?.showWindow(nil)
    }
    
    func statusBarControllerDidSelectAbout(_ controller: StatusBarController) {
        let alert = NSAlert()
        alert.messageText = "Voice2Text v2.0"
        alert.informativeText = """
            A modular voice-to-text tool powered by Whisper AI.
            
            Press and hold Fn to record, release to transcribe.
            
            New modular architecture for better maintainability and extensibility.
            """
        alert.alertStyle = .informational
        alert.runModal()
    }
    
    func statusBarControllerDidSelectQuit(_ controller: StatusBarController) {
        NSApplication.shared.terminate(nil)
    }
}
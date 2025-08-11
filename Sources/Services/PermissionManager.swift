import Cocoa
import AVFoundation

enum Permission {
    case microphone
    case accessibility
    
    var name: String {
        switch self {
        case .microphone:
            return "Microphone"
        case .accessibility:
            return "Accessibility"
        }
    }
    
    var settingsURL: URL? {
        switch self {
        case .microphone:
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")
        case .accessibility:
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        }
    }
}

class PermissionManager {
    static let shared = PermissionManager()
    
    private init() {}
    
    func checkAndRequestPermissions(completion: @escaping (Bool) -> Void) {
        var allPermissionsGranted = true
        let group = DispatchGroup()
        
        // Check microphone permission
        group.enter()
        checkMicrophonePermission { granted in
            if !granted {
                allPermissionsGranted = false
                DispatchQueue.main.async {
                    self.showPermissionAlert(for: .microphone)
                }
            }
            group.leave()
        }
        
        // Check accessibility permission
        if !checkAccessibilityPermission() {
            allPermissionsGranted = false
            showPermissionAlert(for: .accessibility)
        }
        
        group.notify(queue: .main) {
            completion(allPermissionsGranted)
        }
    }
    
    func checkMicrophonePermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                completion(granted)
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    
    func checkAccessibilityPermission() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(options)
    }
    
    private func showPermissionAlert(for permission: Permission) {
        let alert = NSAlert()
        alert.messageText = "\(permission.name) Permission Required"
        alert.informativeText = "Voice2Text needs \(permission.name) permission to work. Please grant access in System Settings."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            if let url = permission.settingsURL {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    func hasMicrophonePermission() -> Bool {
        return AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    }
    
    func hasAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }
}
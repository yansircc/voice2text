import Foundation

class ConfigurationManager {
    static let shared = ConfigurationManager()
    
    private init() {
        // Load .env file on initialization
        DotEnv.load(from: "../.env")
    }
    
    func loadWhisperConfiguration() -> WhisperConfiguration {
        return WhisperConfiguration()
    }
    
    func saveWhisperConfiguration(_ config: WhisperConfiguration) {
        let userDefaults = UserDefaults.standard
        
        // Save configuration to UserDefaults
        userDefaults.set(config.baseURL, forKey: "whisper_base_url")
        userDefaults.set(config.apiKey, forKey: "whisper_api_key")
        userDefaults.set(config.modelId, forKey: "whisper_model")
        userDefaults.set(config.language, forKey: "whisper_language")
        userDefaults.set(config.temperature, forKey: "whisper_temperature")
        userDefaults.set(true, forKey: "whisper_temperature_set")
        userDefaults.set(config.prompt, forKey: "whisper_prompt")
        
        // Notify observers about configuration change
        NotificationCenter.default.post(name: .preferencesDidChange, object: nil)
    }
    
    func resetToDefaults() {
        let userDefaults = UserDefaults.standard
        
        // Remove all custom settings
        userDefaults.removeObject(forKey: "whisper_base_url")
        userDefaults.removeObject(forKey: "whisper_api_key")
        userDefaults.removeObject(forKey: "whisper_model")
        userDefaults.removeObject(forKey: "whisper_language")
        userDefaults.removeObject(forKey: "whisper_temperature")
        userDefaults.removeObject(forKey: "whisper_temperature_set")
        userDefaults.removeObject(forKey: "whisper_prompt")
        
        // Notify observers about configuration change
        NotificationCenter.default.post(name: .preferencesDidChange, object: nil)
    }
    
    func migrateSettings() {
        // Handle migration from older versions if needed
        let userDefaults = UserDefaults.standard
        let version = userDefaults.string(forKey: "app_version") ?? "1.0"
        
        if version < "2.0" {
            // Perform migration logic here
            // For example, convert old settings format to new format
            
            // Update version
            userDefaults.set("2.0", forKey: "app_version")
        }
    }
}

// MARK: - Configuration Validation
extension ConfigurationManager {
    func validateConfiguration() -> (isValid: Bool, errors: [String]) {
        var errors: [String] = []
        let config = loadWhisperConfiguration()
        
        do {
            try config.validate()
        } catch {
            errors.append(error.localizedDescription)
        }
        
        // Check permissions
        if !PermissionManager.shared.hasMicrophonePermission() {
            errors.append("Microphone permission not granted")
        }
        
        if !PermissionManager.shared.hasAccessibilityPermission() {
            errors.append("Accessibility permission not granted")
        }
        
        return (errors.isEmpty, errors)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let preferencesDidChange = Notification.Name("preferencesDidChange")
}
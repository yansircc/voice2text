import Foundation

struct WhisperConfiguration {
    let baseURL: String
    let apiKey: String
    let modelId: String
    let language: String?
    let temperature: Double
    let prompt: String?
    
    init() {
        let userDefaults = UserDefaults.standard
        
        // Try UserDefaults first, then environment variables, then defaults
        self.baseURL = userDefaults.string(forKey: "whisper_base_url")
            ?? ProcessInfo.processInfo.environment["WHISPER_BASE_URL"] 
            ?? "https://api.openai.com"
            
        self.apiKey = userDefaults.string(forKey: "whisper_api_key")
            ?? ProcessInfo.processInfo.environment["WHISPER_API_KEY"] 
            ?? ""
            
        self.modelId = userDefaults.string(forKey: "whisper_model")
            ?? ProcessInfo.processInfo.environment["WHISPER_MODEL_ID"] 
            ?? "whisper-large-v3"
            
        let envLanguage = ProcessInfo.processInfo.environment["WHISPER_LANGUAGE"] ?? "zh"
        let userLanguage = userDefaults.string(forKey: "whisper_language") ?? envLanguage
        self.language = userLanguage.isEmpty ? nil : userLanguage
        
        // Handle temperature with fallback logic
        if userDefaults.bool(forKey: "whisper_temperature_set") {
            self.temperature = userDefaults.double(forKey: "whisper_temperature")
        } else if let envTempString = ProcessInfo.processInfo.environment["WHISPER_TEMPERATURE"],
                  let envTemp = Double(envTempString) {
            self.temperature = envTemp
        } else {
            self.temperature = 0.2
        }
        
        let envPrompt = ProcessInfo.processInfo.environment["WHISPER_PROMPT"]
        let userPrompt = userDefaults.string(forKey: "whisper_prompt") ?? envPrompt ?? ""
        self.prompt = userPrompt.isEmpty ? nil : userPrompt
    }
    
    var transcriptionEndpoint: String {
        // Handle different URL formats
        if baseURL.hasSuffix("/v1") {
            return "\(baseURL)/audio/transcriptions"
        } else if baseURL.contains("api.openai.com") {
            return "\(baseURL)/v1/audio/transcriptions"
        } else {
            return "\(baseURL)/v1/audio/transcriptions"
        }
    }
    
    func validate() throws {
        if apiKey.isEmpty {
            throw ConfigurationError.missingAPIKey
        }
    }
}

enum ConfigurationError: LocalizedError {
    case missingAPIKey
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API key is missing. Please set WHISPER_API_KEY in .env file."
        }
    }
}
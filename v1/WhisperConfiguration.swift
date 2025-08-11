import Foundation

struct WhisperConfiguration {
    let baseURL: String
    let apiKey: String
    let modelId: String
    let language: String?
    let temperature: Double
    let prompt: String?
    
    init() {
        self.baseURL = ProcessInfo.processInfo.environment["WHISPER_BASE_URL"] ?? "https://api.openai.com"
        self.apiKey = ProcessInfo.processInfo.environment["WHISPER_API_KEY"] ?? ""
        self.modelId = ProcessInfo.processInfo.environment["WHISPER_MODEL_ID"] ?? "whisper-large-v3"
        self.language = ProcessInfo.processInfo.environment["WHISPER_LANGUAGE"] ?? "zh"
        self.temperature = Double(ProcessInfo.processInfo.environment["WHISPER_TEMPERATURE"] ?? "") ?? 0.2
        self.prompt = ProcessInfo.processInfo.environment["WHISPER_PROMPT"]
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
import Foundation

enum WhisperModel: String, CaseIterable {
    case whisperLargeV3 = "whisper-large-v3"
    case whisper1 = "whisper-1"
    case distilWhisperLargeV3En = "distil-whisper-large-v3-en"
    
    var description: String {
        switch self {
        case .whisperLargeV3:
            return "Latest large model, best for multilingual (recommended for Chinese)"
        case .whisper1:
            return "Original Whisper model, stable and reliable"
        case .distilWhisperLargeV3En:
            return "Faster processing, English only, slightly lower accuracy"
        }
    }
    
    var recommendedTemperature: Double {
        switch self {
        case .whisperLargeV3:
            return 0.2  // Lower temperature for Chinese and multilingual
        case .whisper1:
            return 0.3
        case .distilWhisperLargeV3En:
            return 0.2  // Lower temperature for better accuracy
        }
    }
}

struct WhisperConfiguration {
    let baseURL: String
    let apiKey: String
    let modelId: String
    let language: String?
    let temperature: Double
    let prompt: String?
    
    init(
        baseURL: String? = nil,
        apiKey: String? = nil,
        modelId: String? = nil,
        language: String? = nil,
        temperature: Double? = nil,
        prompt: String? = nil
    ) {
        self.baseURL = baseURL ?? ProcessInfo.processInfo.environment["WHISPER_BASE_URL"] ?? "https://api.openai.com"
        self.apiKey = apiKey ?? ProcessInfo.processInfo.environment["WHISPER_API_KEY"] ?? ""
        
        // Model selection with validation
        let requestedModel = modelId ?? ProcessInfo.processInfo.environment["WHISPER_MODEL_ID"] ?? "whisper-large-v3"
        if let model = WhisperModel(rawValue: requestedModel) {
            self.modelId = model.rawValue
            // Use provided temperature or model's recommended temperature
            let envTemp = ProcessInfo.processInfo.environment["WHISPER_TEMPERATURE"].flatMap { Double($0) }
            self.temperature = temperature ?? envTemp ?? model.recommendedTemperature
        } else {
            self.modelId = requestedModel  // Allow custom model names
            self.temperature = temperature ?? ProcessInfo.processInfo.environment["WHISPER_TEMPERATURE"].flatMap { Double($0) } ?? 0.2
        }
        
        self.language = language ?? ProcessInfo.processInfo.environment["WHISPER_LANGUAGE"]
        self.prompt = prompt ?? ProcessInfo.processInfo.environment["WHISPER_PROMPT"]
    }
    
    var transcriptionEndpoint: String {
        // Handle different URL formats
        if baseURL.hasSuffix("/v1") {
            // If baseURL already has /v1, just append the endpoint
            return "\(baseURL)/audio/transcriptions"
        } else if baseURL.contains("api.openai.com") {
            // OpenAI format
            return "\(baseURL)/v1/audio/transcriptions"
        } else {
            // For other providers, check if they need /v1 or not
            // Most OpenAI-compatible APIs use /v1/audio/transcriptions
            return "\(baseURL)/v1/audio/transcriptions"
        }
    }
    
    var isValid: Bool {
        return !apiKey.isEmpty
    }
    
    func validate() throws {
        if apiKey.isEmpty {
            throw ConfigurationError.missingAPIKey
        }
    }
}

enum ConfigurationError: LocalizedError {
    case missingAPIKey
    case invalidBaseURL
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API key is missing. Please set WHISPER_API_KEY environment variable or pass it as an argument."
        case .invalidBaseURL:
            return "Invalid base URL provided."
        }
    }
}
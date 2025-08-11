import Foundation

enum RecordingState {
    case idle
    case recording
    case processing
    case transcribing
    case completed
    case error(String)
    
    var statusText: String {
        switch self {
        case .idle:
            return "Ready"
        case .recording:
            return "Recording..."
        case .processing:
            return "Processing..."
        case .transcribing:
            return "Transcribing..."
        case .completed:
            return "Transcription completed"
        case .error(let message):
            return "Error: \(message)"
        }
    }
    
    var iconName: String {
        switch self {
        case .recording:
            return "mic.circle.fill"
        case .idle, .processing, .transcribing, .completed, .error:
            return "mic.fill"
        }
    }
}
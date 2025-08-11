import Foundation

protocol TranscriptionServiceDelegate: AnyObject {
    func transcriptionService(_ service: TranscriptionService, didReceivePartialTranscription text: String)
    func transcriptionService(_ service: TranscriptionService, didCompleteTranscription text: String)
    func transcriptionService(_ service: TranscriptionService, didFailWithError error: Error)
}

protocol TranscriptionService: AnyObject {
    var delegate: TranscriptionServiceDelegate? { get set }
    
    /// Transcribe audio data asynchronously
    func transcribe(audioData: Data, filename: String) async throws -> String
    
    /// Transcribe audio data with streaming support (if available)
    func transcribeStreaming(audioData: Data, filename: String)
    
    /// Check if the service supports streaming
    var supportsStreaming: Bool { get }
}
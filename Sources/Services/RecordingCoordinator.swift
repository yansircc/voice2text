import Foundation
import AVFoundation
import Cocoa

protocol RecordingCoordinatorDelegate: AnyObject {
    func recordingCoordinator(_ coordinator: RecordingCoordinator, didChangeState state: RecordingState)
    func recordingCoordinator(_ coordinator: RecordingCoordinator, didReceiveTranscription text: String)
}

class RecordingCoordinator: NSObject {
    weak var delegate: RecordingCoordinatorDelegate?
    
    private let audioEngine: AudioEngine
    private let whisperService: WhisperService
    private let textInsertion: TextInsertionService
    
    private var currentState: RecordingState = .idle {
        didSet {
            delegate?.recordingCoordinator(self, didChangeState: currentState)
        }
    }
    
    private var placeholderRemoved = false
    
    init(audioEngine: AudioEngine, 
         whisperService: WhisperService,
         textInsertion: TextInsertionService) {
        self.audioEngine = audioEngine
        self.whisperService = whisperService
        self.textInsertion = textInsertion
        super.init()
        
        self.audioEngine.delegate = self
        self.whisperService.delegate = self
    }
    
    func startRecording() {
        do {
            try audioEngine.startRecording()
            currentState = .recording
            
            // Insert recording indicator
            DispatchQueue.main.async {
                self.textInsertion.insertPlaceholder("[正在录音...]")
            }
            
            // Haptic feedback
            NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
        } catch {
            currentState = .error(error.localizedDescription)
        }
    }
    
    func stopRecording() {
        guard let audioData = audioEngine.stopRecording() else {
            currentState = .idle
            return
        }
        
        currentState = .processing
        
        // Remove recording indicator and add processing indicator
        DispatchQueue.main.async {
            self.textInsertion.removePlaceholder("[正在录音...]")
            self.textInsertion.insertPlaceholder("[转录中...]")
        }
        
        // Reset placeholder flag
        placeholderRemoved = false
        
        // Start transcription
        whisperService.transcribeStreaming(audioData: audioData)
    }
}

// MARK: - AudioEngineDelegate
extension RecordingCoordinator: AudioEngineDelegate {
    func audioEngine(_ engine: AudioEngine, didCaptureBuffer buffer: AVAudioPCMBuffer) {
        // Buffer is handled internally by AudioEngine
    }
    
    func audioEngineDidStartRecording(_ engine: AudioEngine) {
        // Already handled in startRecording
    }
    
    func audioEngineDidStopRecording(_ engine: AudioEngine) {
        // Already handled in stopRecording
    }
}

// MARK: - WhisperServiceDelegate
extension RecordingCoordinator: WhisperServiceDelegate {
    func whisperService(_ service: WhisperService, didReceivePartialTranscription text: String) {
        DispatchQueue.main.async {
            if !self.placeholderRemoved && !text.isEmpty {
                self.placeholderRemoved = true
                self.textInsertion.removePlaceholder()
            }
            
            self.textInsertion.insertText(text)
        }
    }
    
    func whisperService(_ service: WhisperService, didCompleteTranscription text: String) {
        DispatchQueue.main.async {
            if !self.placeholderRemoved {
                self.placeholderRemoved = true
                self.textInsertion.removePlaceholder()
            }
            
            if !text.isEmpty {
                self.textInsertion.insertText(text)
            }
            
            self.currentState = .completed
            self.delegate?.recordingCoordinator(self, didReceiveTranscription: text)
            
            // Reset to idle after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.currentState = .idle
            }
        }
    }
    
    func whisperService(_ service: WhisperService, didFailWithError error: Error) {
        DispatchQueue.main.async {
            if !self.placeholderRemoved {
                self.placeholderRemoved = true
                self.textInsertion.removePlaceholder()
            }
            
            self.currentState = .error(error.localizedDescription)
            
            // Reset to idle after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.currentState = .idle
            }
        }
    }
}
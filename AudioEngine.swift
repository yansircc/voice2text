import Foundation
import AVFoundation

protocol AudioEngineDelegate: AnyObject {
    func audioEngine(_ engine: AudioEngine, didCaptureBuffer buffer: AVAudioPCMBuffer)
    func audioEngineDidStartRecording(_ engine: AudioEngine)
    func audioEngineDidStopRecording(_ engine: AudioEngine)
}

class AudioEngine {
    weak var delegate: AudioEngineDelegate?
    
    private let audioEngine = AVAudioEngine()
    private let mixerNode = AVAudioMixerNode()
    private var audioBuffers: [AVAudioPCMBuffer] = []
    private var isRecording = false
    private var recordingFormat: AVAudioFormat?
    
    init() {
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        audioEngine.attach(mixerNode)
        
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        audioEngine.connect(inputNode, to: mixerNode, format: inputFormat)
        
        let mainMixerNode = audioEngine.mainMixerNode
        let mixerFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: inputFormat.sampleRate,
            channels: 1,
            interleaved: false
        )
        
        audioEngine.connect(mixerNode, to: mainMixerNode, format: mixerFormat)
    }
    
    func startRecording() throws {
        // Reset buffers for new recording
        audioBuffers.removeAll()
        
        let inputNode = audioEngine.inputNode
        recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] (buffer, time) in
            self?.processAudioBuffer(buffer)
        }
        
        try audioEngine.start()
        isRecording = true
        
        delegate?.audioEngineDidStartRecording(self)
    }
    
    func stopRecording() -> Data? {
        guard isRecording else { return nil }
        
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        isRecording = false
        
        delegate?.audioEngineDidStopRecording(self)
        
        // Convert buffers to WAV data
        guard !audioBuffers.isEmpty, recordingFormat != nil else {
            return nil
        }
        
        // Downsample to 16kHz for Whisper
        let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16000,
            channels: 1,
            interleaved: false
        )!
        
        var downsampledBuffers: [AVAudioPCMBuffer] = []
        for buffer in audioBuffers {
            if let downsampled = AudioUtilities.downsampleBuffer(buffer, toSampleRate: 16000) {
                downsampledBuffers.append(downsampled)
            }
        }
        
        return AudioUtilities.createWAVData(from: downsampledBuffers, format: targetFormat)
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // Create a copy of the buffer
        guard let bufferCopy = AVAudioPCMBuffer(
            pcmFormat: buffer.format,
            frameCapacity: buffer.frameCapacity
        ) else {
            return
        }
        
        bufferCopy.frameLength = buffer.frameLength
        
        if let channelData = buffer.floatChannelData,
           let copyChannelData = bufferCopy.floatChannelData {
            for channel in 0..<Int(buffer.format.channelCount) {
                memcpy(
                    copyChannelData[channel],
                    channelData[channel],
                    Int(buffer.frameLength) * MemoryLayout<Float>.size
                )
            }
        }
        
        audioBuffers.append(bufferCopy)
        delegate?.audioEngine(self, didCaptureBuffer: bufferCopy)
    }
}
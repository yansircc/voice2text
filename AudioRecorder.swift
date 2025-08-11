import Foundation
import AVFoundation

class AudioRecorder {
    private let audioEngine = AVAudioEngine()
    private var audioFile: AVAudioFile?
    private let mixerNode = AVAudioMixerNode()
    private var isRecording = false
    private var bufferCount = 0
    private let printInterval = 100  // Print every 100 buffers (approximately every 2-3 seconds)
    
    private var audioBuffers: [AVAudioPCMBuffer] = []
    private let bufferAccumulationInterval = 200  // Accumulate ~5 seconds of audio before transcription
    private var recordingFormat: AVAudioFormat?
    private let whisperClient: WhisperClient
    private let transcriptionQueue = DispatchQueue(label: "transcription.queue")
    
    init(whisperClient: WhisperClient) {
        self.whisperClient = whisperClient
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        audioEngine.attach(mixerNode)
        
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        audioEngine.connect(inputNode, to: mixerNode, format: inputFormat)
        
        let mainMixerNode = audioEngine.mainMixerNode
        let mixerFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, 
                                       sampleRate: inputFormat.sampleRate, 
                                       channels: 1, 
                                       interleaved: false)
        
        audioEngine.connect(mixerNode, to: mainMixerNode, format: mixerFormat)
    }
    
    func startRecording() throws {
        // Reset state for new recording session
        audioBuffers.removeAll()
        bufferCount = 0
        
        let inputNode = audioEngine.inputNode
        recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] (buffer, time) in
            self?.processAudioBuffer(buffer)
        }
        
        try audioEngine.start()
        isRecording = true
    }
    
    func stopRecording() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        isRecording = false
        
        if !audioBuffers.isEmpty {
            print("⏸️  Processing final audio segment...")
            transcribeAccumulatedAudio()
        } else {
            print("⚠️  No audio recorded.")
        }
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        bufferCount += 1
        
        guard let bufferCopy = AVAudioPCMBuffer(pcmFormat: buffer.format, frameCapacity: buffer.frameCapacity) else {
            return
        }
        
        bufferCopy.frameLength = buffer.frameLength
        
        if let channelData = buffer.floatChannelData,
           let copyChannelData = bufferCopy.floatChannelData {
            for channel in 0..<Int(buffer.format.channelCount) {
                memcpy(copyChannelData[channel], channelData[channel], 
                       Int(buffer.frameLength) * MemoryLayout<Float>.size)
            }
        }
        
        audioBuffers.append(bufferCopy)
        
        if bufferCount % bufferAccumulationInterval == 0 {
            transcribeAccumulatedAudio()
        }
    }
    
    private func transcribeAccumulatedAudio() {
        guard !audioBuffers.isEmpty, let format = recordingFormat else { return }
        
        let buffersToProcess = audioBuffers
        audioBuffers.removeAll()
        
        transcriptionQueue.async { [weak self] in
            guard let self = self else { return }
            
            let targetFormat = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: 16000,  // Whisper prefers 16kHz
                channels: 1,
                interleaved: false
            )!
            
            var downsampledBuffers: [AVAudioPCMBuffer] = []
            for buffer in buffersToProcess {
                if let downsampled = AudioUtilities.downsampleBuffer(buffer, toSampleRate: 16000) {
                    downsampledBuffers.append(downsampled)
                }
            }
            
            guard let wavData = AudioUtilities.createWAVData(from: downsampledBuffers, format: targetFormat) else {
                print("Failed to create WAV data")
                return
            }
            
            let sizeInMB = Double(wavData.count) / (1024 * 1024)
            print("📤 Sending \(String(format: "%.2f", sizeInMB)) MB of audio for transcription...")
            
            Task {
                do {
                    let transcription = try await self.whisperClient.transcribe(audioData: wavData)
                    if !transcription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        print("\n✅ Transcription Result:")
                        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                        print(transcription)
                        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                    } else {
                        print("⚠️  No speech detected in this segment.")
                    }
                } catch {
                    print("❌ Transcription error: \(error)")
                }
            }
        }
    }
}
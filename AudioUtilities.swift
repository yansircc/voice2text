import Foundation
import AVFoundation

class AudioUtilities {
    
    static func createWAVData(from buffers: [AVAudioPCMBuffer], format: AVAudioFormat) -> Data? {
        guard !buffers.isEmpty else { return nil }
        
        let frameCount = buffers.reduce(0) { $0 + Int($1.frameLength) }
        
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)) else {
            return nil
        }
        
        outputBuffer.frameLength = 0
        
        for buffer in buffers {
            let frameLength = buffer.frameLength
            if frameLength > 0 {
                if let channelData = buffer.floatChannelData {
                    let channelCount = Int(format.channelCount)
                    let startIndex = Int(outputBuffer.frameLength)
                    
                    for channel in 0..<channelCount {
                        let src = channelData[channel]
                        let dst = outputBuffer.floatChannelData![channel]
                        
                        for frame in 0..<Int(frameLength) {
                            dst[startIndex + frame] = src[frame]
                        }
                    }
                    
                    outputBuffer.frameLength += frameLength
                }
            }
        }
        
        return convertPCMBufferToWAV(buffer: outputBuffer, format: format)
    }
    
    static func convertPCMBufferToWAV(buffer: AVAudioPCMBuffer, format: AVAudioFormat) -> Data? {
        let audioFile = createTempWAVFile()
        
        // Create settings for 16-bit PCM to reduce file size
        var settings = format.settings
        settings[AVLinearPCMBitDepthKey] = 16
        settings[AVLinearPCMIsFloatKey] = false
        settings[AVLinearPCMIsBigEndianKey] = false
        
        guard let file = try? AVAudioFile(forWriting: audioFile, settings: settings) else {
            return nil
        }
        
        do {
            try file.write(from: buffer)
            let data = try Data(contentsOf: audioFile)
            try? FileManager.default.removeItem(at: audioFile)
            return data
        } catch {
            print("Error converting to WAV: \(error)")
            try? FileManager.default.removeItem(at: audioFile)
            return nil
        }
    }
    
    private static func createTempWAVFile() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "temp_\(UUID().uuidString).wav"
        return tempDir.appendingPathComponent(filename)
    }
    
    static func downsampleBuffer(_ buffer: AVAudioPCMBuffer, toSampleRate targetSampleRate: Double) -> AVAudioPCMBuffer? {
        let inputFormat = buffer.format
        
        guard let outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: targetSampleRate,
            channels: 1,
            interleaved: false
        ) else {
            return nil
        }
        
        guard let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
            return nil
        }
        
        let ratio = targetSampleRate / inputFormat.sampleRate
        let outputFrameCapacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio)
        
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: outputFrameCapacity) else {
            return nil
        }
        
        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }
        
        var error: NSError?
        let status = converter.convert(to: outputBuffer, error: &error, withInputFrom: inputBlock)
        
        if status == .error {
            print("Conversion error: \(error?.localizedDescription ?? "Unknown")")
            return nil
        }
        
        return outputBuffer
    }
}
import Foundation
import AVFoundation

// Load .env file first
DotEnv.load()

func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
    switch AVCaptureDevice.authorizationStatus(for: .audio) {
    case .authorized:
        completion(true)
    case .notDetermined:
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            completion(granted)
        }
    case .denied, .restricted:
        print("Microphone access denied. Please enable it in System Settings > Privacy & Security > Microphone")
        completion(false)
    @unknown default:
        completion(false)
    }
}

func printUsage() {
    print("""
    Usage: audio_recorder [OPTIONS]
    
    Options:
        --base-url URL      Custom API endpoint (default: https://api.openai.com)
        --api-key KEY       API key for authentication (or use .env file)
        --model MODEL       Model ID to use (default: whisper-large-v3)
        --language LANG     Language code (e.g., en, zh, es)
        --temperature TEMP  Temperature value 0.0-1.0 (default: model-specific)
        --prompt TEXT       Context prompt to improve accuracy
        --help              Show this help message
    
    Available Models:
        whisper-large-v3          Latest, best for multilingual (recommended for Chinese)
        whisper-1                 Original model, stable and reliable
        distil-whisper-large-v3-en  Faster, English only, slightly lower accuracy
    
    Configuration Methods (in order of precedence):
        1. Command-line arguments
        2. Environment variables
        3. .env file in current directory
    
    Example .env file:
        WHISPER_API_KEY=your-api-key-here
        WHISPER_MODEL_ID=whisper-large-v3
        WHISPER_LANGUAGE=zh
        WHISPER_TEMPERATURE=0.2
    
    Examples:
        audio_recorder                    # Uses .env file or environment variables
        audio_recorder --api-key YOUR_KEY --language zh
        audio_recorder --model whisper-large-v3 --temperature 0.2
    """)
}

var baseURL: String?
var apiKey: String?
var modelId: String?
var language: String?
var temperature: Double?
var prompt: String?

let args = CommandLine.arguments
var i = 1
while i < args.count {
    switch args[i] {
    case "--help", "-h":
        printUsage()
        exit(0)
    case "--base-url":
        if i + 1 < args.count {
            baseURL = args[i + 1]
            i += 2
        } else {
            print("Error: --base-url requires a value")
            exit(1)
        }
    case "--api-key":
        if i + 1 < args.count {
            apiKey = args[i + 1]
            i += 2
        } else {
            print("Error: --api-key requires a value")
            exit(1)
        }
    case "--model":
        if i + 1 < args.count {
            modelId = args[i + 1]
            i += 2
        } else {
            print("Error: --model requires a value")
            exit(1)
        }
    case "--language":
        if i + 1 < args.count {
            language = args[i + 1]
            i += 2
        } else {
            print("Error: --language requires a value")
            exit(1)
        }
    case "--temperature":
        if i + 1 < args.count {
            temperature = Double(args[i + 1])
            if temperature == nil || temperature! < 0 || temperature! > 1 {
                print("Error: --temperature must be a number between 0.0 and 1.0")
                exit(1)
            }
            i += 2
        } else {
            print("Error: --temperature requires a value")
            exit(1)
        }
    case "--prompt":
        if i + 1 < args.count {
            prompt = args[i + 1]
            i += 2
        } else {
            print("Error: --prompt requires a value")
            exit(1)
        }
    default:
        print("Unknown option: \(args[i])")
        printUsage()
        exit(1)
    }
}

let configuration = WhisperConfiguration(
    baseURL: baseURL,
    apiKey: apiKey,
    modelId: modelId,
    language: language,
    temperature: temperature,
    prompt: prompt
)

if !configuration.isValid {
    print("Error: API key is required.")
    print("")
    print("Set it using one of these methods:")
    print("  1. Create a .env file:  cp .env.example .env  (then edit with your key)")
    print("  2. Environment variable: export WHISPER_API_KEY='your-api-key-here'")
    print("  3. Command-line: --api-key YOUR_KEY")
    exit(1)
}

print("Configuration:")
print("  Base URL: \(configuration.baseURL)")
print("  Model: \(configuration.modelId)", terminator: "")
if let model = WhisperModel(rawValue: configuration.modelId) {
    print(" - \(model.description)")
} else {
    print()
}
print("  Temperature: \(configuration.temperature)")
if let lang = configuration.language {
    print("  Language: \(lang)")
}
if let prompt = configuration.prompt {
    print("  Prompt: \(prompt.prefix(50))\(prompt.count > 50 ? "..." : "")")
}
print("")

let whisperClient = WhisperClient(configuration: configuration)
let recorder = AudioRecorder(whisperClient: whisperClient)
let semaphore = DispatchSemaphore(value: 0)

requestMicrophonePermission { granted in
    if granted {
        print("╔════════════════════════════════════════════════════════╗")
        print("║  Audio Transcription Ready                              ║")
        print("║  • Press ENTER: Stop recording and get transcription    ║")
        print("║  • Type 'q' + ENTER: Quit the program                   ║")
        print("╚════════════════════════════════════════════════════════╝")
        print("")
        
        var shouldContinue = true
        
        while shouldContinue {
            do {
                try recorder.startRecording()
                print("🎤 Recording... (Press ENTER to stop and transcribe)")
                print("")
                
                let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                
                recorder.stopRecording()
                
                // Wait a moment for final transcription to complete
                Thread.sleep(forTimeInterval: 1.0)
                
                if input == "q" {
                    shouldContinue = false
                    print("\n👋 Goodbye!")
                } else {
                    print("\n─────────────────────────────────────────────────────────")
                    print("Ready for next recording. Press ENTER to start, or 'q' to quit.")
                    let nextInput = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    if nextInput == "q" {
                        shouldContinue = false
                        print("\n👋 Goodbye!")
                    }
                }
            } catch {
                print("Error during recording: \(error)")
                shouldContinue = false
            }
        }
    } else {
        print("Microphone permission not granted.")
    }
    semaphore.signal()
}

semaphore.wait()
print("Program finished.")
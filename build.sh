#!/bin/bash

echo "Building audio recorder with Whisper integration..."

swiftc main.swift AudioRecorder.swift Configuration.swift WhisperClient.swift AudioUtilities.swift DotEnv.swift \
    -o audio_recorder \
    -framework AVFoundation \
    -framework CoreAudio \
    -Xlinker -rpath \
    -Xlinker @executable_path

if [ $? -eq 0 ]; then
    echo "Build successful! Run with: ./audio_recorder"
    echo ""
    echo "Usage:"
    echo "  ./audio_recorder --help                     # Show help"
    echo "  ./audio_recorder --api-key YOUR_KEY         # Use with OpenAI API"
    echo "  export WHISPER_API_KEY='your-key-here'      # Set via environment variable"
    echo ""
    echo "For custom API endpoints:"
    echo "  ./audio_recorder --base-url https://custom-api.com --api-key YOUR_KEY"
    echo ""
    echo "Note: On first run, macOS will ask for microphone permission."
else
    echo "Build failed!"
    exit 1
fi
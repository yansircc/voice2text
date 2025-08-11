#!/bin/bash

echo "🔍 Debug mode for Voice2Text"
echo "=============================="
echo ""

# Check if .env exists
if [ -f "../.env" ]; then
    echo "✅ Found ../.env file"
    # Check for API key
    if grep -q "WHISPER_API_KEY=" "../.env"; then
        echo "✅ API key is set in .env"
    else
        echo "❌ API key not found in .env"
    fi
else
    echo "❌ ../.env file not found"
    echo "   Please create it: cp ../.env.example ../.env"
fi

echo ""
echo "Building with debug output..."
echo ""

# Build with verbose output
swiftc \
    main.swift \
    AppDelegate.swift \
    GlobalKeyboardMonitor.swift \
    AudioEngine.swift \
    WhisperService.swift \
    WhisperConfiguration.swift \
    DotEnv.swift \
    AudioUtilities.swift \
    -o build/Voice2Text.app/Contents/MacOS/Voice2Text \
    -framework Cocoa \
    -framework AVFoundation \
    -framework CoreAudio \
    -framework Carbon \
    -Xlinker -rpath \
    -Xlinker @executable_path/../Frameworks \
    -D DEBUG

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build successful"
    echo ""
    echo "Running in console mode (you'll see debug output)..."
    echo "=============================="
    echo ""
    
    # Run directly in terminal to see console output
    ./build/Voice2Text.app/Contents/MacOS/Voice2Text
else
    echo "❌ Build failed"
fi
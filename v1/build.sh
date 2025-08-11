#!/bin/bash

APP_NAME="Voice2Text"
BUILD_DIR="build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "🔨 Building Voice2Text v1.0..."

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Compile Swift files
echo "📦 Compiling Swift files..."
swiftc \
    main.swift \
    AppDelegate.swift \
    GlobalKeyboardMonitor.swift \
    AudioEngine.swift \
    WhisperService.swift \
    WhisperConfiguration.swift \
    DotEnv.swift \
    AudioUtilities.swift \
    -o "$MACOS_DIR/$APP_NAME" \
    -framework Cocoa \
    -framework AVFoundation \
    -framework CoreAudio \
    -framework Carbon \
    -Xlinker -rpath \
    -Xlinker @executable_path/../Frameworks

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

# Copy Info.plist
cp Info.plist "$CONTENTS_DIR/"

# Create PkgInfo
echo "APPL????" > "$CONTENTS_DIR/PkgInfo"

# Create a simple icon (optional)
# You can add a proper .icns file to Resources later

echo "✅ Build successful!"
echo ""
echo "📍 Application location: $APP_DIR"
echo ""
echo "🚀 To run the app:"
echo "   1. First time: Grant accessibility permission when prompted"
echo "   2. The app will appear in your menu bar (top right)"
echo "   3. Hold Fn key or F5 to record, release to transcribe"
echo ""
echo "⚙️  To install (make it launch at login):"
echo "   1. Copy to Applications: cp -r $APP_DIR /Applications/"
echo "   2. Open the app from Applications folder"
echo "   3. Add to Login Items in System Settings > General > Login Items"
echo ""
echo "🔑 Required permissions:"
echo "   - Accessibility (for keyboard monitoring)"
echo "   - Microphone (for audio recording)"
echo ""
echo "📝 Configuration:"
echo "   Make sure ../.env file exists with your WHISPER_API_KEY"
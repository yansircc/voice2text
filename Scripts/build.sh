#!/bin/bash

APP_NAME="Voice2Text"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/.."

# Build directory is in project root
BUILD_DIR="$PROJECT_ROOT/build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "🔨 Building Voice2Text v2.0 (Modular Architecture)..."

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Change to project root
cd "$PROJECT_ROOT"

# Collect all Swift files from the new directory structure
echo "📦 Collecting Swift files from modular structure..."

# Find all Swift files in Sources directory
SWIFT_FILES=""
for file in $(find Sources -name "*.swift" -type f | sort); do
    echo "  ✓ Found: $file"
    SWIFT_FILES="$SWIFT_FILES $file"
done

# Count files
FILE_COUNT=$(echo $SWIFT_FILES | wc -w | tr -d ' ')
echo "📊 Found $FILE_COUNT Swift files to compile"

# Compile Swift files
echo "📦 Compiling Swift files..."
swiftc \
    $SWIFT_FILES \
    -o "$MACOS_DIR/$APP_NAME" \
    -framework Cocoa \
    -framework AVFoundation \
    -framework CoreAudio \
    -framework Carbon \
    -Xlinker -rpath \
    -Xlinker @executable_path/../Frameworks \
    -suppress-warnings

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

# Copy Info.plist
cp Sources/App/Info.plist "$CONTENTS_DIR/"

# Create PkgInfo
echo "APPL????" > "$CONTENTS_DIR/PkgInfo"

# Create a simple icon (optional)
# You can add a proper .icns file to Resources later

echo "✅ Build successful!"
echo ""
echo "📁 Project structure:"
echo "   Sources/"
echo "   ├── App/          - Application entry point"
echo "   ├── Core/         - Core business logic"
echo "   │   ├── Audio/    - Audio recording"
echo "   │   ├── Input/    - Keyboard & text input"
echo "   │   └── Transcription/ - Whisper API"
echo "   ├── Models/       - Data models"
echo "   ├── Services/     - Service layer"
echo "   ├── UI/           - User interface"
echo "   └── Utilities/    - Helper utilities"
echo ""
echo "📍 Application location: $(cd "$APP_DIR" && pwd)"
echo ""
echo "🚀 To run the app:"
echo "   1. First time: Grant accessibility permission when prompted"
echo "   2. The app will appear in your menu bar (top right)"
echo "   3. Hold Fn key or F5 to record, release to transcribe"
echo ""
echo "⚙️  To install (make it launch at login):"
echo "   1. Copy to Applications: cp -r \"$APP_DIR\" /Applications/"
echo "   2. Open the app from Applications folder"
echo "   3. Add to Login Items in System Settings > General > Login Items"
echo ""
echo "🔑 Required permissions:"
echo "   - Accessibility (for keyboard monitoring)"
echo "   - Microphone (for audio recording)"
echo ""
echo "📝 Configuration:"
echo "   Make sure ../.env file exists with your WHISPER_API_KEY"
#!/bin/bash

echo "🎤 Voice2Text v1.0 - Installation Script"
echo "======================================="
echo ""

# Check if .env file exists
if [ ! -f "../.env" ]; then
    echo "❌ Configuration file not found!"
    echo ""
    echo "Please create ../.env file first:"
    echo "  cp ../.env.example ../.env"
    echo "  # Then edit .env with your API key"
    echo ""
    exit 1
fi

# Check API key
if ! grep -q "WHISPER_API_KEY=" "../.env" || grep -q "WHISPER_API_KEY=$" "../.env" || grep -q "WHISPER_API_KEY=\"\"" "../.env"; then
    echo "⚠️  Warning: API key appears to be empty in ../.env"
    echo "Please make sure to set your WHISPER_API_KEY"
    echo ""
fi

# Build the app
echo "🔨 Building Voice2Text..."
./build.sh

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo ""
echo "📦 Installing to Applications folder..."

# Remove existing installation
if [ -d "/Applications/Voice2Text.app" ]; then
    echo "Removing existing installation..."
    rm -rf "/Applications/Voice2Text.app"
fi

# Copy to Applications
cp -r "build/Voice2Text.app" "/Applications/"

if [ $? -eq 0 ]; then
    echo "✅ Installation successful!"
    echo ""
    echo "🚀 Next steps:"
    echo "  1. Open Voice2Text from Applications folder"
    echo "  2. Grant Accessibility permission when prompted"
    echo "  3. Grant Microphone permission when prompted"
    echo "  4. Look for microphone icon in menu bar"
    echo "  5. Hold Fn or F5 to record, release to transcribe"
    echo ""
    echo "💡 Tips:"
    echo "  • Add to Login Items in System Settings to start at login"
    echo "  • Right-click menu bar icon for options and quit"
    echo "  • Works in any text field or application"
    echo ""
    echo "🔧 Configuration: ../env file"
    echo "📚 Documentation: README.md"
    echo ""
    
    read -p "Would you like to open the app now? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Opening Voice2Text..."
        open "/Applications/Voice2Text.app"
    fi
else
    echo "❌ Installation failed!"
    echo "Please check permissions for /Applications folder"
fi
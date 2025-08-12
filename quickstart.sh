#!/bin/bash

# Voice2Text Quick Start Script
# This script helps you get started with Voice2Text quickly

echo "🎙️ Voice2Text Quick Start"
echo "========================="
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo "📝 Setting up configuration..."
    
    if [ -f .env.example ]; then
        cp .env.example .env
        echo "✅ Created .env from .env.example"
        echo ""
        echo "⚠️  IMPORTANT: Please edit .env and add your WHISPER_API_KEY"
        echo "   You can get an API key from:"
        echo "   - OpenAI: https://platform.openai.com/api-keys"
        echo "   - Or use your own Whisper-compatible API"
        echo ""
        read -p "Press Enter after you've added your API key to .env..."
    else
        echo "❌ .env.example not found. Please create .env manually."
        exit 1
    fi
else
    echo "✅ Configuration file found"
fi

echo ""
echo "🔨 Building Voice2Text..."
echo ""

# Build the application
cd Scripts 2>/dev/null || cd scripts 2>/dev/null || {
    echo "❌ Scripts directory not found"
    exit 1
}

if [ -f build.sh ]; then
    ./build.sh
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ Build successful!"
        echo ""
        echo "🚀 Would you like to:"
        echo "   1) Run the app now"
        echo "   2) Install to Applications folder"
        echo "   3) Exit"
        echo ""
        read -p "Enter your choice (1-3): " choice
        
        case $choice in
            1)
                echo "Starting Voice2Text..."
                ./run.sh
                ;;
            2)
                echo "Installing to Applications..."
                ./install.sh
                ;;
            3)
                echo "Setup complete! You can run the app later with:"
                echo "  cd Scripts && ./run.sh"
                ;;
            *)
                echo "Invalid choice. Setup complete!"
                ;;
        esac
    else
        echo "❌ Build failed. Please check the error messages above."
        exit 1
    fi
else
    echo "❌ build.sh not found"
    exit 1
fi
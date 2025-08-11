#!/bin/bash

# Quick run script for development
echo "🚀 Starting Voice2Text..."

# Build first
./build.sh

if [ $? -eq 0 ]; then
    echo ""
    echo "📱 Launching app..."
    # Run the app directly
    ./build/Voice2Text.app/Contents/MacOS/Voice2Text
fi
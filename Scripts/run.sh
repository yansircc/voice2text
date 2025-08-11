#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/.."

# Quick run script for development
echo "🚀 Starting Voice2Text..."

# Build first
"$SCRIPT_DIR/build.sh"

if [ $? -eq 0 ]; then
    echo ""
    echo "📱 Launching app..."
    # Run the app directly
    "$PROJECT_ROOT/build/Voice2Text.app/Contents/MacOS/Voice2Text"
fi
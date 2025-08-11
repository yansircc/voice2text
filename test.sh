#!/bin/bash

echo "🧪 Testing basic functionality..."
echo ""

# First, test a simple menu bar app
echo "1️⃣ Testing simple menu bar app..."
swiftc test_simple.swift -o test_app -framework Cocoa

if [ $? -eq 0 ]; then
    echo "✅ Simple app compiled"
    echo "Running simple test app..."
    echo "Look for 🎤 in your menu bar!"
    echo ""
    ./test_app
else
    echo "❌ Simple app failed to compile"
fi
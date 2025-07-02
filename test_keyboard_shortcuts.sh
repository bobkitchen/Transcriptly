#!/bin/bash

# Test script for keyboard shortcut functionality

echo "Starting Transcriptly to test keyboard shortcuts..."
echo "Please test the following:"
echo "1. Go to Settings > Keyboard Shortcuts"
echo "2. Click 'Edit' on any shortcut"
echo "3. Press a key combination (e.g., ⌘⇧K)"
echo "4. Verify it doesn't crash"
echo ""
echo "Press Ctrl+C to stop when done testing"

# Run the app
open /Users/bobkitchen/Library/Developer/Xcode/DerivedData/Transcriptly-fohshuwhubzyizgxdnpeuobcbnez/Build/Products/Debug/Transcriptly.app

# Monitor console for crashes
echo ""
echo "Monitoring console for crashes..."
log stream --predicate 'process == "Transcriptly"' --level debug
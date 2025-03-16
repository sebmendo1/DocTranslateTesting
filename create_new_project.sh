#!/bin/bash

# This script fixes the "Multiple commands produce" error by creating a new project
# This approach provides a clean slate and avoids modifying the existing project

echo "This script will guide you through creating a new project to fix the Info.plist conflict."
echo "You'll need to perform these steps manually."
echo ""
echo "Instructions:"
echo "1. Create a new Xcode project (File > New > Project)"
echo "2. Select 'App' template and name it 'DocScannerTest-New'"
echo "3. Make sure 'SwiftUI' is selected for the interface"
echo "4. Create the project in a different location"
echo "5. Copy all the Swift files from the original project to the new project:"
echo "   - ContentView.swift"
echo "   - DocumentScannerModel.swift"
echo "   - DocumentScannerView.swift"
echo "   - ScannedDocumentView.swift"
echo "6. Copy the Info.plist entries to the new project's Info.plist file:"
echo "   - NSCameraUsageDescription"
echo "   - NSPhotoLibraryAddUsageDescription"
echo "   - NSPhotoLibraryUsageDescription"
echo "7. Build and run the new project"
echo ""
echo "This approach creates a new project with clean settings while preserving your code."
echo ""
echo "To automate copying the files, you can run:"
echo "mkdir -p DocScannerTest-New/DocScannerTest-New"
echo "cp DocScannerTest/*.swift DocScannerTest-New/DocScannerTest-New/"
echo ""
echo "Note: You'll still need to manually create the new project and update the Info.plist."

exit 0 
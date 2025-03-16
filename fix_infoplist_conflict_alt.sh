#!/bin/bash

# This script fixes the "Multiple commands produce" error by using a different approach
# It renames the Info.plist file and updates the project to use the new name

# Path to the project.pbxproj file
PROJECT_FILE="DocScannerTest.xcodeproj/project.pbxproj"

# Check if the project file exists
if [ ! -f "$PROJECT_FILE" ]; then
    echo "Error: Project file not found at $PROJECT_FILE"
    exit 1
fi

echo "Creating backup of project file..."
cp "$PROJECT_FILE" "${PROJECT_FILE}.backup.$(date +%Y%m%d%H%M%S)"
echo "Backup created."

echo "Fixing Info.plist conflict..."

# Rename the Info.plist file to CustomInfo.plist
if [ -f "DocScannerTest/Info.plist" ]; then
    mv "DocScannerTest/Info.plist" "DocScannerTest/CustomInfo.plist"
    echo "Renamed Info.plist to CustomInfo.plist"
else
    echo "Warning: Info.plist not found in DocScannerTest directory"
    exit 1
fi

# Update the project to use CustomInfo.plist
sed -i '' 's/INFOPLIST_FILE = "DocScannerTest\/Info.plist";/INFOPLIST_FILE = "DocScannerTest\/CustomInfo.plist";/g' "$PROJECT_FILE"

echo "Conflict fixed. Please clean and rebuild the project in Xcode."
echo ""
echo "Instructions:"
echo "1. Open the project in Xcode"
echo "2. Select Product > Clean Build Folder"
echo "3. Build and run the project"

exit 0 
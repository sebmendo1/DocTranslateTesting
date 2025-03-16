#!/bin/bash

# This script updates the Xcode project settings to use our custom Info.plist file

# Path to the project.pbxproj file
PROJECT_FILE="DocScannerTest.xcodeproj/project.pbxproj"

# Check if the project file exists
if [ ! -f "$PROJECT_FILE" ]; then
    echo "Error: Project file not found at $PROJECT_FILE"
    exit 1
fi

echo "Updating project settings to use custom Info.plist file..."

# Create a backup of the project file
cp "$PROJECT_FILE" "${PROJECT_FILE}.backup"
echo "Created backup at ${PROJECT_FILE}.backup"

# Replace GENERATE_INFOPLIST_FILE = YES with INFOPLIST_FILE = DocScannerTest/Info.plist
sed -i '' 's/GENERATE_INFOPLIST_FILE = YES;/INFOPLIST_FILE = "DocScannerTest\/Info.plist";/g' "$PROJECT_FILE"

echo "Project settings updated. Please clean and rebuild the project in Xcode."
echo "Instructions:"
echo "1. Open the project in Xcode"
echo "2. Select Product > Clean Build Folder"
echo "3. Build and run the project"

exit 0 
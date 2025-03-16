#!/bin/bash

# This script fixes the "Multiple commands produce" error by removing the INFOPLIST_KEY_* settings
# that conflict with our custom Info.plist file

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

# Remove INFOPLIST_KEY_* settings that cause conflicts
sed -i '' 's/INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;//g' "$PROJECT_FILE"
sed -i '' 's/INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;//g' "$PROJECT_FILE"
sed -i '' 's/INFOPLIST_KEY_UILaunchScreen_Generation = YES;//g' "$PROJECT_FILE"
sed -i '' 's/INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";//g' "$PROJECT_FILE"
sed -i '' 's/INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";//g' "$PROJECT_FILE"

echo "Conflict fixed. Please clean and rebuild the project in Xcode."
echo ""
echo "Instructions:"
echo "1. Open the project in Xcode"
echo "2. Select Product > Clean Build Folder"
echo "3. Build and run the project"

exit 0 
#!/bin/bash

# This script fixes the "Multiple commands produce" error by using an xcconfig file
# This approach is less invasive and more maintainable than directly editing the project file

echo "Creating xcconfig file to fix Info.plist conflict..."

# Create the xcconfig directory if it doesn't exist
mkdir -p xcconfig

# Create the xcconfig file
cat > xcconfig/InfoPlistFix.xcconfig << EOL
// Disable automatic Info.plist generation
GENERATE_INFOPLIST_FILE = NO

// Use our custom Info.plist file
INFOPLIST_FILE = DocScannerTest/Info.plist

// Disable other Info.plist related settings
INFOPLIST_KEY_UIApplicationSceneManifest_Generation = NO
INFOPLIST_KEY_UILaunchScreen_Generation = NO
INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = NO

// Add a setting to disable the build warning
DISABLE_MANUAL_TARGET_ORDER_BUILD_WARNING = YES
EOL

echo "XCConfig file created at xcconfig/InfoPlistFix.xcconfig"
echo ""
echo "Instructions to apply the fix:"
echo "1. Open the project in Xcode"
echo "2. Select the project in the Project Navigator (blue icon at the top)"
echo "3. Select the 'DocScannerTest' target"
echo "4. Go to the 'Build Settings' tab"
echo "5. Click on the '+' button at the top and select 'Add User-Defined Setting'"
echo "6. Name it 'XCCONFIG_FILE' and set its value to '\$(SRCROOT)/xcconfig/InfoPlistFix.xcconfig'"
echo "7. Select Product > Clean Build Folder"
echo "8. Build and run the project"
echo ""
echo "If the above doesn't work, try this alternative approach:"
echo "1. Open the project in Xcode"
echo "2. Select the project in the Project Navigator"
echo "3. Select the 'Info' tab at the top"
echo "4. Under 'Configurations', click the '+' button and select 'Duplicate Debug Configuration'"
echo "5. Name it 'Debug-Fixed'"
echo "6. For the 'Debug-Fixed' configuration, select the xcconfig file we created"
echo "7. Change the active scheme to use the 'Debug-Fixed' configuration"
echo "8. Clean and rebuild the project"

exit 0 
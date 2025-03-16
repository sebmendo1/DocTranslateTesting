# Manual Fix Guide for "Multiple commands produce" Error

If you're encountering the "Multiple commands produce '/path/to/Info.plist'" error, follow these steps to fix it manually in Xcode:

## Option 1: Remove INFOPLIST_KEY_* settings

1. Open the project in Xcode
2. Select the project in the Project Navigator (blue icon at the top)
3. Select the "DocScannerTest" target
4. Go to the "Build Settings" tab
5. Search for "info.plist"
6. Make sure "Info.plist File" is set to "DocScannerTest/Info.plist"
7. Search for "scene manifest"
8. Set "Application Scene Manifest Generation" to "No"
9. Search for "launch screen"
10. Set "Launch Screen Generation" to "No"
11. Search for "supported interface"
12. Remove any values for "Supported Interface Orientations" settings (or set them to "$(inherited)")
13. Clean and rebuild the project

## Option 2: Rename Info.plist file

1. In Finder, navigate to your project folder
2. Go to the "DocScannerTest" folder
3. Rename "Info.plist" to "CustomInfo.plist"
4. Open the project in Xcode
5. Select the project in the Project Navigator
6. Select the "DocScannerTest" target
7. Go to the "Build Settings" tab
8. Search for "info.plist"
9. Change "Info.plist File" to "DocScannerTest/CustomInfo.plist"
10. Clean and rebuild the project

## Option 3: Use a different build configuration

1. Open the project in Xcode
2. Select the project in the Project Navigator
3. Select the "DocScannerTest" target
4. Go to the "Build Settings" tab
5. Click the "+" button at the top and select "Add User-Defined Setting"
6. Name it "DISABLE_MANUAL_TARGET_ORDER_BUILD_WARNING"
7. Set its value to "YES"
8. Clean and rebuild the project

## Explanation of the Error

The "Multiple commands produce" error occurs because there are two sources trying to create the Info.plist file:

1. The custom Info.plist file you've created in the project
2. The automatically generated Info.plist from the INFOPLIST_KEY_* settings

By either removing the automatic generation settings or renaming your custom file, you can resolve this conflict.

If you continue to have issues, please try the provided scripts:
- `./fix_infoplist_conflict.sh` (Option 1)
- `./fix_infoplist_conflict_alt.sh` (Option 2) 
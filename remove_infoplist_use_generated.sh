#!/bin/bash

# Script to remove Info.plist file and switch to using generated Info.plist
# This script will:
# 1. Backup the existing Info.plist
# 2. Modify the project settings to use generated Info.plist
# 3. Add all necessary keys to the project settings

echo "Starting Info.plist removal and generated Info.plist configuration..."

# Backup the existing Info.plist
if [ -f "DocScannerTest/Info.plist" ]; then
    echo "Backing up Info.plist..."
    cp DocScannerTest/Info.plist DocScannerTest/Info.plist.backup
    echo "Backup created at DocScannerTest/Info.plist.backup"
    
    # Remove the original Info.plist file
    echo "Removing original Info.plist file..."
    rm DocScannerTest/Info.plist
    echo "Info.plist removed"
else
    echo "Warning: Info.plist not found at DocScannerTest/Info.plist"
fi

# Create a new xcconfig file for the generated Info.plist approach
mkdir -p xcconfig
cat > xcconfig/GeneratedInfoPlist.xcconfig << EOL
// Enable automatic Info.plist generation
GENERATE_INFOPLIST_FILE = YES

// Set the bundle identifier
PRODUCT_BUNDLE_IDENTIFIER = com.document-translator-v4.DocScannerTest

// App settings
MARKETING_VERSION = 1.0
CURRENT_PROJECT_VERSION = 1
INFOPLIST_KEY_CFBundleDisplayName = DocScanner

// UI settings
INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES
INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES
INFOPLIST_KEY_UILaunchScreen_Generation = YES
INFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight
INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight

// Camera and photo library permissions
INFOPLIST_KEY_NSCameraUsageDescription = This app needs access to your camera to scan documents.
INFOPLIST_KEY_NSPhotoLibraryAddUsageDescription = This app needs permission to save scanned documents to your photo library.
INFOPLIST_KEY_NSPhotoLibraryUsageDescription = This app needs access to your photo library to save scanned documents.

// Document types
INFOPLIST_KEY_CFBundleDocumentTypes[0] = <dict><key>CFBundleTypeName</key><string>PDF Document</string><key>LSHandlerRank</key><string>Alternate</string><key>LSItemContentTypes</key><array><string>com.adobe.pdf</string></array></dict>
EOL

echo "Created xcconfig/GeneratedInfoPlist.xcconfig"

# Create a script to modify the project file
cat > modify_project_for_generated_infoplist.rb << EOL
#!/usr/bin/env ruby

require 'xcodeproj'

# Path to your .xcodeproj file
project_path = 'DocScannerTest.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main target
main_target = project.targets.find { |target| target.name == 'DocScannerTest' }

if main_target
  # Get the build configurations
  main_target.build_configurations.each do |config|
    # Enable generated Info.plist
    config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
    
    # Remove reference to the custom Info.plist file
    config.build_settings.delete('INFOPLIST_FILE')
    
    # Set the base configuration to use our xcconfig file
    config.base_configuration_reference = project.new_file('xcconfig/GeneratedInfoPlist.xcconfig')
  end
  
  # Save the project
  project.save
  puts "Project updated successfully!"
else
  puts "Error: Could not find the main target 'DocScannerTest'"
end
EOL

echo "Created modify_project_for_generated_infoplist.rb"
chmod +x modify_project_for_generated_infoplist.rb

# Check if ruby and xcodeproj gem are available
if command -v ruby >/dev/null 2>&1; then
    if gem list -i xcodeproj >/dev/null 2>&1; then
        echo "Running project modification script..."
        ruby modify_project_for_generated_infoplist.rb
    else
        echo "Warning: xcodeproj gem not found. Please install it with: gem install xcodeproj"
        echo "Then run: ruby modify_project_for_generated_infoplist.rb"
    fi
else
    echo "Warning: Ruby not found. Please install Ruby and the xcodeproj gem."
    echo "Then run: ruby modify_project_for_generated_infoplist.rb"
fi

# Update the DocScannerTestApp.swift file to remove Info.plist checks
if [ -f "DocScannerTest/DocScannerTestApp.swift" ]; then
    echo "Updating DocScannerTestApp.swift to remove Info.plist checks..."
    cat > DocScannerTest/DocScannerTestApp.swift << EOL
//
//  DocScannerTestApp.swift
//  DocScannerTest
//
//  Created by Sebastian Mendo on 3/6/25.
//

import SwiftUI
import VisionKit
import AVFoundation

@main
struct DocScannerTestApp: App {
    @State private var isDocumentScanningAvailable: Bool = false
    @State private var cameraPermissionGranted: Bool = false
    @State private var showInfoPlistError: Bool = false
    @State private var infoPlistErrorMessage: String = ""
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .onAppear {
                        // Check if document scanning is available
                        isDocumentScanningAvailable = VNDocumentCameraViewController.isSupported
                        
                        // Check camera permission status
                        checkCameraPermission()
                        
                        // Info.plist checks removed as we now use generated Info.plist
                    }
                
                // Show Info.plist error alert if needed
                if showInfoPlistError {
                    Color.black.opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            // Do nothing, prevent taps from passing through
                        }
                    
                    VStack {
                        Text("Configuration Error")
                            .font(.headline)
                            .padding()
                        
                        Text(infoPlistErrorMessage)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button("See Instructions") {
                            // This would ideally open the README, but for now just dismiss
                            showInfoPlistError = false
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.bottom)
                    }
                    .frame(maxWidth: 300)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 10)
                }
            }
        }
    }
    
    // Check camera permission status
    private func checkCameraPermission() {
        // Check camera authorization status
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            print("Camera access already authorized")
            cameraPermissionGranted = true
        case .notDetermined:
            print("Camera access not determined yet")
            // Request permission
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.cameraPermissionGranted = granted
                    print("Camera access \(granted ? "granted" : "denied")")
                }
            }
        case .denied, .restricted:
            print("Camera access denied or restricted")
            cameraPermissionGranted = false
        @unknown default:
            print("Unknown camera access status")
            cameraPermissionGranted = false
        }
        
        // Log document scanning availability
        if isDocumentScanningAvailable {
            print("Document scanning is available on this device")
        } else {
            print("Document scanning is NOT available on this device")
        }
    }
    
    // Info.plist checks removed as we now use generated Info.plist
}
EOL
    echo "DocScannerTestApp.swift updated"
fi

echo ""
echo "=== NEXT STEPS ==="
echo "1. Install the xcodeproj gem if you haven't already: gem install xcodeproj"
echo "2. Run the Ruby script: ruby modify_project_for_generated_infoplist.rb"
echo "3. Open the project in Xcode"
echo "4. Clean the build folder (Shift+Cmd+K)"
echo "5. Build and run the project"
echo ""
echo "If you encounter any issues, you can restore the backup Info.plist file."
echo "Script completed!"

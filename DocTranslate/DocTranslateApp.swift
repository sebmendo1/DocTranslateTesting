//
//  DocScannerTestApp.swift
//  DocScannerTest
//
//  Created by Sebastian Mendo on 3/6/25.
//

import SwiftUI
import VisionKit
import AVFoundation

// Add a simple AppDelegate class to handle app launch configuration
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Add any setup needed during app launch
        return true
    }
}

@main
struct DocScannerTestApp: App {
    // Use AppDelegate to properly handle app lifecycle
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
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
                    Color.themeNeutralDark.opacity(0.5)
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
                        .background(Color.themePrimary)
                        .foregroundColor(.themeButtonText)
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

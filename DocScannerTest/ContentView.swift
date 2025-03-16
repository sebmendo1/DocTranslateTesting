//
//  ContentView.swift
//  DocScannerTest
//
//  Created by Sebastian Mendo on 3/6/25.
//

import SwiftUI
import VisionKit
import AVFoundation

// No need to import TestAPIKey as it's part of the same module

struct ContentView: View {
    @StateObject private var scannerModel = DocumentScannerModel()
    @State private var showingScanner = false
    @State private var showingErrorAlert = false
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Scanner Tab
            NavigationView {
                mainScannerView
            }
            .tabItem {
                Label("Scanner", systemImage: "doc.text.viewfinder")
            }
            .tag(0)
            
            // Albums Tab
            NavigationView {
                AlbumsView(scannerModel: scannerModel)
            }
            .tabItem {
                Label("Albums", systemImage: "photo.on.rectangle")
            }
            .tag(1)
            
            // Settings Tab
            SettingsView(scannerModel: scannerModel)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
        .sheet(isPresented: $showingScanner) {
            DocumentScannerView(scannerModel: scannerModel)
        }
        .alert("Scanner Error", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            if let errorMessage = scannerModel.errorMessage {
                Text(errorMessage)
            } else {
                Text("An unknown error occurred")
            }
        }
        .onChange(of: scannerModel.errorMessage) { newValue in
            showingErrorAlert = newValue != nil
        }
        .onAppear {
            // Load the DeepL API key when the app starts
            loadAPIKey()
        }
    }
    
    // Load the API key from the APIKeys struct
    private func loadAPIKey() {
        scannerModel.setAPIKey(APIKeys.deepLAPIKey, isPro: APIKeys.isDeepLProAccount)
        
        // Also save to AppStorage for the settings view
        UserDefaults.standard.set(APIKeys.deepLAPIKey, forKey: "deepLApiKey")
        UserDefaults.standard.set(APIKeys.isDeepLProAccount, forKey: "isDeepLProAccount")
    }
    
    var mainScannerView: some View {
        VStack {
            // Header
            HStack {
                Text("Document Scanner")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Translation status indicator
                if scannerModel.isTranslating {
                    HStack {
                        Text("Translating")
                            .font(.caption)
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
            
            // Processing view
            if scannerModel.isProcessing {
                VStack(spacing: 20) {
                    ProgressView("Processing document...", value: scannerModel.progress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle())
                        .padding()
                    
                    Text("Please wait while we process your document")
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
            }
            // Scanned document preview
            else if let _ = scannerModel.scannedImage {
                ScannedDocumentView(scannerModel: scannerModel)
            }
            // Empty state
            else {
                VStack(spacing: 25) {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("No Document Scanned")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Tap the scan button to scan a document")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Spacer().frame(height: 20)
                    
                    // Enhancement toggle
                    Toggle(isOn: $scannerModel.enhancedImage) {
                        Label("Enhance Document", systemImage: "wand.and.stars")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // Language picker
                    VStack(alignment: .leading) {
                        Text("Recognition Language:")
                            .font(.headline)
                            .padding(.bottom, 5)
                        
                        Picker("Language", selection: $scannerModel.selectedLanguage) {
                            ForEach(DocumentScannerModel.RecognitionLanguage.allCases) { language in
                                Text(language.displayName).tag(language)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                .padding()
                .frame(maxHeight: .infinity)
            }
            
            // Action buttons
            VStack {
                if scannerModel.scannedImage == nil && !scannerModel.isProcessing {
                    Button(action: {
                        if scannerModel.isDocumentScanningAvailable {
                            showingScanner = true
                        } else {
                            scannerModel.errorMessage = "Document scanning is not available on this device"
                        }
                    }) {
                        Label("Scan Document", systemImage: "doc.text.viewfinder")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom)
        }
        .navigationBarHidden(true)
    }
}

// Helper struct for alert binding
struct DocumentScannerError: Identifiable {
    var id: String { message }
    let message: String
}

// Helper function to check camera permission
private func checkCameraPermission(completion: @escaping (Bool) -> Void) {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
        completion(true)
    case .notDetermined:
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    case .denied, .restricted:
        completion(false)
    @unknown default:
        completion(false)
    }
}

#Preview {
    ContentView()
}

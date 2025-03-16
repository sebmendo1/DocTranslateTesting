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
    @StateObject var scannerModel = DocumentScannerModel()
    @State private var showingScanner = false
    @State private var showingCameraAlert = false
    @State private var selectedTab = 0
    @AppStorage("deepLApiKey") private var deepLApiKey = ""
    @AppStorage("isDeepLProAccount") private var isDeepLProAccount = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // SCANNER TAB
            NavigationView {
                VStack {
                    mainScannerView
                }
                .navigationTitle("Document Scanner")
                .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("Scanner", systemImage: "doc.viewfinder")
            }
            .tag(0)
            .accessibilityIdentifier("scannerTab")
            
            // ALBUMS TAB
            AlbumsView(scannerModel: scannerModel)
                .tabItem {
                    Label("Albums", systemImage: "photo.on.rectangle")
                }
                .tag(1)
                .accessibilityIdentifier("albumsTab")
            
            // SETTINGS TAB
            SettingsView(scannerModel: scannerModel)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
                .accessibilityIdentifier("settingsTab")
        }
        .accentColor(.blue)
        .onAppear {
            // Set the tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
            
            // Set the API key from AppStorage or APIKeys
            if !deepLApiKey.isEmpty {
                // Use the API key from AppStorage if available
                scannerModel.setAPIKey(deepLApiKey, isPro: isDeepLProAccount)
                print("Using API key from AppStorage: \(deepLApiKey)")
            } else if !APIKeys.deepLAPIKey.contains("YOUR_DEEPL_API_KEY_HERE") {
                // Otherwise use the API key from APIKeys
                let apiKey = APIKeys.deepLAPIKey
                scannerModel.setAPIKey(apiKey, isPro: APIKeys.isDeepLProAccount)
                print("Using API key from APIKeys: \(apiKey)")
                
                // Also save to AppStorage for the settings view
                deepLApiKey = apiKey
                isDeepLProAccount = APIKeys.isDeepLProAccount
            } else {
                print("No valid API key found")
            }
        }
        .sheet(isPresented: $showingScanner) {
            DocumentScannerView(scannerModel: scannerModel)
        }
        .alert(isPresented: $showingCameraAlert) {
            Alert(
                title: Text("Camera Access Required"),
                message: Text("Please allow camera access in Settings to scan documents."),
                primaryButton: .default(Text("Settings"), action: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }),
                secondaryButton: .cancel()
            )
        }
    }
    
    private var mainScannerView: some View {
        ZStack {
            VStack(spacing: 20) {
                // Header with language and enhancement options
                VStack(spacing: 12) {
                    HStack {
                        Toggle(isOn: $scannerModel.enhancedImage) {
                            Label("Enhance Document", systemImage: "wand.and.stars")
                                .font(.subheadline)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                        .padding(.horizontal)
                    }
                    
                    Picker("Recognition Language", selection: $scannerModel.selectedLanguage) {
                        ForEach(DocumentScannerModel.RecognitionLanguage.allCases) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                if scannerModel.isProcessing {
                    processingView
                } else if let image = scannerModel.scannedImage {
                    scannedDocumentView(image)
                } else {
                    emptyStateView
                }
                
                // Action buttons
                VStack(spacing: 16) {
                    Button(action: {
                        if VNDocumentCameraViewController.isSupported {
                            showingScanner = true
                        } else {
                            showingCameraAlert = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "doc.viewfinder")
                                .font(.headline)
                            Text("Scan Document")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .accessibilityIdentifier("scanButton")
                    
                    if scannerModel.scannedImage != nil {
                        HStack(spacing: 12) {
                            Button(action: {
                                shareScannedContent()
                            }) {
                                VStack {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 20))
                                    Text("Share")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray5))
                                .foregroundColor(.primary)
                                .cornerRadius(10)
                            }
                            .accessibilityIdentifier("shareButton")
                            
                            Button(action: {
                                exportToPDF()
                            }) {
                                VStack {
                                    Image(systemName: "arrow.down.doc")
                                        .font(.system(size: 20))
                                    Text("PDF")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray5))
                                .foregroundColor(.primary)
                                .cornerRadius(10)
                            }
                            .accessibilityIdentifier("pdfButton")
                            
                            Button(action: {
                                clearScannedData()
                            }) {
                                VStack {
                                    Image(systemName: "trash")
                                        .font(.system(size: 20))
                                    Text("Clear")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray5))
                                .foregroundColor(.red)
                                .cornerRadius(10)
                            }
                            .accessibilityIdentifier("clearButton")
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
            
            if let error = scannerModel.errorMessage {
                VStack {
                    Spacer()
                    Text(error)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.9))
                        .cornerRadius(8)
                        .padding()
                        .transition(.move(edge: .bottom))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                scannerModel.errorMessage = nil
                            }
                        }
                }
                .zIndex(1)
                .transition(.opacity)
                .animation(.easeInOut, value: scannerModel.errorMessage != nil)
            }
        }
    }
    
    private var processingView: some View {
        VStack(spacing: 20) {
            ProgressView(value: scannerModel.progress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())
                .padding(.horizontal)
            
            Text("Processing document...")
                .font(.headline)
            
            Text("Please wait while we extract text from your document.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding()
    }
    
    private func scannedDocumentView(_ image: UIImage) -> some View {
        NavigationLink(destination: ScannedDocumentView(scannerModel: scannerModel)) {
            VStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(8)
                    .shadow(radius: 2)
                    .padding(.horizontal)
                
                if !scannerModel.scannedText.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Text extracted")
                            .font(.headline)
                        
                        Text(scannerModel.scannedText.prefix(100) + (scannerModel.scannedText.count > 100 ? "..." : ""))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 70))
                .foregroundColor(.blue.opacity(0.8))
            
            Text("No Document Scanned")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Tap the Scan button to capture a document and extract text.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top, 60)
        .padding(.horizontal)
    }
    
    private func shareScannedContent() {
        var itemsToShare: [Any] = []
        
        if let image = scannerModel.scannedImage {
            itemsToShare.append(image)
        }
        
        if !scannerModel.scannedText.isEmpty {
            itemsToShare.append(scannerModel.scannedText)
        }
        
        let activityVC = UIActivityViewController(
            activityItems: itemsToShare,
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
    
    private func exportToPDF() {
        guard let image = scannerModel.scannedImage else { return }
        
        let pdfData = scannerModel.createPDF(from: [image])
        
        let activityVC = UIActivityViewController(
            activityItems: [pdfData],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
    
    private func clearScannedData() {
        scannerModel.scannedImage = nil
        scannerModel.scannedText = ""
        scannerModel.translatedText = ""
        scannerModel.detectedLanguage = nil
    }
}

struct ScannerView: UIViewControllerRepresentable {
    @ObservedObject var scannerModel: DocumentScannerModel
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = context.coordinator
        return scannerViewController
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(scannerModel: scannerModel, parent: self)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        var scannerModel: DocumentScannerModel
        var parent: ScannerView
        
        init(scannerModel: DocumentScannerModel, parent: ScannerView) {
            self.scannerModel = scannerModel
            self.parent = parent
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            scannerModel.isProcessing = true
            scannerModel.progress = 0.0
            
            // Capture all pages
            var images: [UIImage] = []
            for i in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: i)
                images.append(image)
            }
            
            scannerModel.scannedImages = images
            
            // Use the first image as the main image
            if let firstImage = images.first {
                scannerModel.scannedImage = firstImage
                
                // Process the image in the background
                let workItem = DispatchWorkItem {
                    self.scannerModel.recognizeText(in: firstImage)
                }
                DispatchQueue.global(qos: .userInitiated).async(execute: workItem)
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            scannerModel.errorMessage = "Scanner error: \(error.localizedDescription)"
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
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

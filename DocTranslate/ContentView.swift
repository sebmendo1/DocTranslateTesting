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
    @State private var showingSettings = false
    @State private var documentTitle: String = ""
    @State private var showingTitlePrompt: Bool = false
    @AppStorage("deepLApiKey") private var deepLApiKey = ""
    @AppStorage("isDeepLProAccount") private var isDeepLProAccount = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Main content
                VStack {
                    if scannerModel.isProcessing {
                        processingView
                    } else if scannerModel.savedDocuments.isEmpty {
                        emptyStateView
                    } else {
                        savedDocumentsView
                    }
                }
                
                // Floating action button
        VStack {
                    Spacer()
                    
                    Button(action: {
                        if VNDocumentCameraViewController.isSupported {
                            showingScanner = true
                        } else {
                            showingCameraAlert = true
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.themeButtonText)
                            .frame(width: 64, height: 64)
                            .background(Color.themePrimary)
                            .clipShape(Circle())
                            .shadow(
                                color: Color.themePrimary.opacity(0.3),
                                radius: 10,
                                x: 0,
                                y: 4
                            )
                    }
                    .padding(.bottom, 50)
                    .accessibilityLabel("Scan document")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Center logo and app name
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.themePrimary.opacity(0.8),
                                            Color.themePrimary
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "doc.text.viewfinder")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        Text("DocTranslate")
                            .font(AppTheme.Typography.headline)
                            .fontWeight(.bold)
                    }
                }
                
                // Settings button in top right
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 22))
                            .foregroundColor(.themeTextPrimary)
                    }
                    .accessibilityLabel("Settings")
                }
            }
        }
        .accentColor(.themePrimary)
        .onAppear {
            // Set the API key from AppStorage or APIKeys
            if !deepLApiKey.isEmpty {
                scannerModel.setAPIKey(deepLApiKey, isPro: isDeepLProAccount)
            } else if !APIKeys.deepLAPIKey.contains("YOUR_DEEPL_API_KEY_HERE") {
                let apiKey = APIKeys.deepLAPIKey
                scannerModel.setAPIKey(apiKey, isPro: APIKeys.isDeepLProAccount)
                deepLApiKey = apiKey
                isDeepLProAccount = APIKeys.isDeepLProAccount
            } else {
                print("No valid API key found")
            }
        }
        .onReceive(scannerModel.$shouldShowTitlePrompt) { showPrompt in
            if showPrompt {
                documentTitle = scannerModel.generateDocumentTitle(from: scannerModel.scannedText)
                showingTitlePrompt = true
            }
        }
        .sheet(isPresented: $showingScanner) {
            DocumentScannerView(scannerModel: scannerModel)
        }
        .sheet(isPresented: $showingSettings) {
            NavigationView {
                SettingsView(scannerModel: scannerModel)
            }
        }
        .sheet(isPresented: $showingTitlePrompt) {
            documentTitlePromptView
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
    
    // Document title prompt view
    private var documentTitlePromptView: some View {
        NavigationView {
            VStack(spacing: AppTheme.Spacing.large) {
                // Preview of the scanned document
                if let image = scannerModel.scannedImage {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(AppTheme.CornerRadius.medium)
                            .frame(height: 200)
                            .padding(.horizontal)
                        
                        // Enhancement indicator
                        if scannerModel.enhancedImage {
                            Text("Enhanced")
                                .font(AppTheme.Typography.caption1)
                                .padding(.horizontal, AppTheme.Spacing.small)
                                .padding(.vertical, AppTheme.Spacing.xsmall)
                                .background(Color.themePrimary.opacity(0.8))
                                .foregroundColor(.themeButtonText)
                                .cornerRadius(AppTheme.CornerRadius.small)
                                .padding(AppTheme.Spacing.small)
                        }
                    }
                }
                
                // Title field
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("Document Title")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(.themeTextPrimary)
                    
                    TextField("Enter document title", text: $documentTitle)
                        .font(AppTheme.Typography.body)
        .padding()
                        .background(Color.themeBackgroundSecondary)
                        .cornerRadius(AppTheme.CornerRadius.small)
                        .submitLabel(.done)
                }
                .padding(.horizontal)
                
                // Instruction text
                Text("Add a title to help you identify this document later.")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(.themeTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, AppTheme.Spacing.large)
            .navigationTitle("Name Your Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingTitlePrompt = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        scannerModel.saveDocumentWithTitle(documentTitle)
                        showingTitlePrompt = false
                    }
                }
            }
        }
    }
    
    // Saved documents view
    private var savedDocumentsView: some View {
        List {
            ForEach(scannerModel.savedDocuments) { document in
                DocumentCardView(
                    document: document,
                    scannerModel: scannerModel,
                    destination: {
                        ScannedDocumentView(scannerModel: scannerModel, initialDocumentTitle: document.title)
                            .onAppear {
                                scannerModel.loadSavedDocument(document)
                            }
                    }
                )
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                .id(document.id)
            }
            .onDelete(perform: scannerModel.removeSavedDocument)
        }
        .listStyle(PlainListStyle())
        .background(Color.themeBackgroundPrimary)
    }
    
    // Empty state view
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Spacer()
                .frame(height: 60)
            
            Text("We've got work to do")
                .font(AppTheme.Typography.title2)
                .fontWeight(.bold)
            
            Text("Translate your first document to get started.")
                .font(AppTheme.Typography.body)
                .foregroundColor(.themeTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.xlarge)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // Processing view
    private var processingView: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            ProgressView(value: scannerModel.progress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())
                .padding(.horizontal, AppTheme.Spacing.medium)
            
            Text("Processing document...")
                .font(AppTheme.Typography.headline)
            
            Text("Please wait while we extract text from your document.")
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(.themeTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.medium)
            
            Spacer()
        }
        .padding(AppTheme.Spacing.medium)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.themeBackgroundPrimary)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .padding(AppTheme.Spacing.medium)
    }
    
    // Scanned document view
    private func scannedDocumentView(_ image: UIImage) -> some View {
        NavigationLink(destination: ScannedDocumentView(scannerModel: scannerModel)) {
            VStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(AppTheme.CornerRadius.small)
                    .shadow(
                        color: AppTheme.Shadow.small.color.opacity(AppTheme.Shadow.small.opacity),
                        radius: AppTheme.Shadow.small.radius,
                        x: AppTheme.Shadow.small.x,
                        y: AppTheme.Shadow.small.y
                    )
                    .padding(.horizontal, AppTheme.Spacing.medium)
                
                if !scannerModel.scannedText.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xsmall) {
                        Text("Text extracted")
                            .font(AppTheme.Typography.headline)
                        
                        Text(scannerModel.scannedText.prefix(100) + (scannerModel.scannedText.count > 100 ? "..." : ""))
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(.themeTextSecondary)
                            .lineLimit(3)
                    }
                    .padding(AppTheme.Spacing.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.themeBackgroundSecondary)
                    .cornerRadius(AppTheme.CornerRadius.small)
                    .padding(.horizontal, AppTheme.Spacing.medium)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
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
            // Process the scanned document
            if scan.pageCount > 0 {
                // Get the first page as the main image
                let image = scan.imageOfPage(at: 0)
                
                // Store images in the model
                scannerModel.scannedImage = image
                
                var images: [UIImage] = []
                for i in 0..<scan.pageCount {
                    images.append(scan.imageOfPage(at: i))
                }
                scannerModel.scannedImages = images
                
                // Process the document to extract text
                scannerModel.processScannedDocument()
            }
            
            // Dismiss the scanner
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("Scanner error: \(error.localizedDescription)")
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

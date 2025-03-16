import SwiftUI

struct SettingsView: View {
    @ObservedObject var scannerModel: DocumentScannerModel
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("defaultLanguage") private var defaultLanguage = "en-US"
    @AppStorage("enhanceByDefault") private var enhanceByDefault = false
    @AppStorage("saveToPhotos") private var saveToPhotos = false
    @AppStorage("deepLApiKey") private var deepLApiKey = ""
    @AppStorage("isDeepLProAccount") private var isDeepLProAccount = false
    
    @State private var showingClearConfirmation = false
    @State private var showingApiKeyInput = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("OCR Settings")) {
                    Picker("Default Language", selection: $scannerModel.selectedLanguage) {
                        ForEach(DocumentScannerModel.RecognitionLanguage.allCases) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    .onChange(of: scannerModel.selectedLanguage) { newValue in
                        defaultLanguage = newValue.rawValue
                    }
                    
                    Toggle("Enhance Images by Default", isOn: $enhanceByDefault)
                        .onChange(of: enhanceByDefault) { newValue in
                            scannerModel.enhancedImage = newValue
                        }
                    
                    Toggle("Save Scans to Photos", isOn: $saveToPhotos)
                }
                
                Section(header: Text("DeepL Translation")) {
                    if deepLApiKey.isEmpty {
                        Button("Set DeepL API Key") {
                            showingApiKeyInput = true
                        }
                    } else {
                        HStack {
                            Text("API Key")
                            Spacer()
                            Text("•••••••••••" + deepLApiKey.suffix(4))
                                .foregroundColor(.secondary)
                        }
                        
                        Button("Change API Key") {
                            showingApiKeyInput = true
                        }
                        
                        Toggle("Using Pro Account", isOn: $isDeepLProAccount)
                            .onChange(of: isDeepLProAccount) { newValue in
                                scannerModel.setAPIKey(deepLApiKey, isPro: newValue)
                            }
                    }
                    
                    Picker("Default Target Language", selection: $scannerModel.targetLanguage) {
                        ForEach(DocumentScannerModel.TranslationLanguage.allCases) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Technology")
                        Spacer()
                        Text("VisionKit & DeepL")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Help")) {
                    NavigationLink(destination: HelpView()) {
                        Label("How to use", systemImage: "questionmark.circle")
                    }
                    
                    Button(action: {
                        // Send feedback via email
                        if let url = URL(string: "mailto:support@example.com?subject=DocScanner%20Feedback") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Label("Send Feedback", systemImage: "envelope")
                    }
                }
                
                Section(header: Text("Advanced")) {
                    Button("Clear All Albums") {
                        showingClearConfirmation = true
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert("Enter DeepL API Key", isPresented: $showingApiKeyInput) {
                TextField("API Key", text: $deepLApiKey)
                Button("Cancel", role: .cancel) { }
                Button("Save") {
                    scannerModel.setAPIKey(deepLApiKey, isPro: isDeepLProAccount)
                }
            } message: {
                Text("Enter your DeepL API key to enable translation features.")
            }
            .alert("Clear All Albums", isPresented: $showingClearConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    scannerModel.albums = []
                }
            } message: {
                Text("This will delete all your saved scans. This action cannot be undone.")
            }
            .onAppear {
                // Set the selected language from saved preference
                if let savedLanguage = DocumentScannerModel.RecognitionLanguage.allCases.first(where: { $0.rawValue == defaultLanguage }) {
                    scannerModel.selectedLanguage = savedLanguage
                }
                
                // Set enhancement from saved preference
                scannerModel.enhancedImage = enhanceByDefault
                
                // Set the API key from storage when view appears
                if !deepLApiKey.isEmpty {
                    scannerModel.setAPIKey(deepLApiKey, isPro: isDeepLProAccount)
                }
            }
        }
    }
}

struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text("How to Use DocScanner")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("1. Scanning Documents")
                            .font(.headline)
                        Text("Tap the scan button to open the camera. Position your document within the frame and the app will automatically detect its edges. Tap the capture button to scan.")
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("2. OCR Text Recognition")
                            .font(.headline)
                        Text("After scanning, the app will automatically extract text from your document. You can copy this text or share it.")
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("3. Translation")
                            .font(.headline)
                        Text("With a DeepL API key configured, you can translate your scanned text to multiple languages. Tap the 'Translate' button and select your target language.")
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("4. Language Support")
                            .font(.headline)
                        Text("The app supports OCR in multiple languages. You can set your preferred language in Settings.")
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("5. Image Enhancement")
                            .font(.headline)
                        Text("Enable image enhancement to improve text recognition quality, especially for documents with poor contrast.")
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("6. Albums")
                            .font(.headline)
                        Text("Organize your scanned documents into albums. Create a new album from the scanned document view.")
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.vertical)
        }
        .navigationTitle("Help")
    }
} 
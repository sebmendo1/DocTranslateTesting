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
    @State private var tempApiKey = ""
    
    var body: some View {
        NavigationView {
            List {
                // OCR Settings Section
                Section(header: Text("OCR Settings")) {
                    NavigationLink(destination: languageSelectionView) {
                        HStack {
                            Label("Default Language", systemImage: "character.bubble")
                            Spacer()
                            Text(scannerModel.selectedLanguage.displayName)
                                .foregroundColor(.secondary)
                        }
                    }
                    .accessibilityHint("Select the default language for text recognition")
                    
                    Toggle(isOn: $enhanceByDefault) {
                        Label("Enhance Images", systemImage: "wand.and.stars")
                    }
                    .onChange(of: enhanceByDefault) { newValue in
                        scannerModel.enhancedImage = newValue
                    }
                    .accessibilityHint("Enhance document images to improve text recognition")
                    
                    Toggle(isOn: $saveToPhotos) {
                        Label("Save to Photos", systemImage: "photo")
                    }
                    .accessibilityHint("Save scanned documents to your photo library")
                }
                
                // DeepL Translation Section
                Section(header: Text("DeepL Translation"), footer: Text("Enter your DeepL API key to enable translation features. You can get a free API key at deepl.com/pro-api")) {
                    if deepLApiKey.isEmpty {
                        Button(action: {
                            // Pre-fill with the API key from APIKeys if available
                            tempApiKey = APIKeys.deepLAPIKey
                            showingApiKeyInput = true
                        }) {
                            Label("Set API Key", systemImage: "key")
                                .foregroundColor(.blue)
                        }
                        .accessibilityHint("Add your DeepL API key")
                    } else {
                        HStack {
                            Label("API Key", systemImage: "key")
                            Spacer()
                            Text("•••••••••••" + deepLApiKey.suffix(4))
                                .foregroundColor(.secondary)
                        }
                        
                        Button(action: {
                            tempApiKey = deepLApiKey
                            showingApiKeyInput = true
                        }) {
                            Label("Change API Key", systemImage: "pencil")
                                .foregroundColor(.blue)
                        }
                        .accessibilityHint("Change your DeepL API key")
                        
                        Toggle(isOn: $isDeepLProAccount) {
                            Label("Pro Account", systemImage: "checkmark.seal")
                        }
                        .onChange(of: isDeepLProAccount) { newValue in
                            scannerModel.setAPIKey(deepLApiKey, isPro: newValue)
                        }
                        .accessibilityHint("Toggle if you're using a DeepL Pro account")
                    }
                    
                    NavigationLink(destination: translationLanguageSelectionView) {
                        HStack {
                            Label("Default Target Language", systemImage: "globe")
                            Spacer()
                            Text(scannerModel.targetLanguage.displayName)
                                .foregroundColor(.secondary)
                        }
                    }
                    .accessibilityHint("Select the default language for translations")
                }
                
                // About Section
                Section(header: Text("About")) {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Technology", systemImage: "cpu")
                        Spacer()
                        Text("VisionKit & DeepL")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Help Section
                Section(header: Text("Help & Support")) {
                    NavigationLink(destination: HelpView()) {
                        Label("How to Use", systemImage: "questionmark.circle")
                    }
                    .accessibilityHint("View instructions on how to use the app")
                    
                    Button(action: {
                        sendFeedback()
                    }) {
                        Label("Send Feedback", systemImage: "envelope")
                    }
                    .accessibilityHint("Send feedback via email")
                }
                
                // Advanced Section
                Section(header: Text("Advanced")) {
                    Button(action: {
                        showingClearConfirmation = true
                    }) {
                        Label("Clear All Albums", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                    .accessibilityHint("Delete all saved albums and documents")
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert("Enter DeepL API Key", isPresented: $showingApiKeyInput) {
                TextField("API Key", text: $tempApiKey)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                Button("Cancel", role: .cancel) { }
                Button("Save") {
                    if !tempApiKey.isEmpty {
                        deepLApiKey = tempApiKey
                        scannerModel.setAPIKey(deepLApiKey, isPro: isDeepLProAccount)
                    }
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
                // If deepLApiKey is empty, set it from APIKeys
                if deepLApiKey.isEmpty && !APIKeys.deepLAPIKey.contains("YOUR_DEEPL_API_KEY_HERE") {
                    deepLApiKey = APIKeys.deepLAPIKey
                    isDeepLProAccount = APIKeys.isDeepLProAccount
                }
                
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
    
    private var languageSelectionView: some View {
        List {
            ForEach(DocumentScannerModel.RecognitionLanguage.allCases) { language in
                Button(action: {
                    scannerModel.selectedLanguage = language
                    defaultLanguage = language.rawValue
                }) {
                    HStack {
                        Text(language.displayName)
                        Spacer()
                        if scannerModel.selectedLanguage == language {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .foregroundColor(.primary)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Recognition Language")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var translationLanguageSelectionView: some View {
        List {
            ForEach(DocumentScannerModel.TranslationLanguage.allCases) { language in
                Button(action: {
                    scannerModel.targetLanguage = language
                }) {
                    HStack {
                        Text(language.displayName)
                        Spacer()
                        if scannerModel.targetLanguage == language {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .foregroundColor(.primary)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Translation Language")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func sendFeedback() {
        if let url = URL(string: "mailto:support@example.com?subject=DocScanner%20Feedback") {
            UIApplication.shared.open(url)
        }
    }
}

struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("How to Use DocScanner")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("A comprehensive guide to using the app's features")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 8)
                
                // Scanning Documents
                helpSection(
                    title: "Scanning Documents",
                    icon: "doc.viewfinder",
                    content: "Tap the scan button to open the camera. Position your document within the frame and the app will automatically detect its edges. Tap the capture button to scan."
                )
                
                // OCR Text Recognition
                helpSection(
                    title: "OCR Text Recognition",
                    icon: "text.viewfinder",
                    content: "After scanning, the app will automatically extract text from your document. You can copy this text or share it. For better results, enable 'Enhance Images' in Settings."
                )
                
                // Translation
                helpSection(
                    title: "Translation",
                    icon: "globe",
                    content: "With a DeepL API key configured, you can translate your scanned text to multiple languages. Tap the 'Translate' button and select your target language. You can set a default target language in Settings."
                )
                
                // Language Support
                helpSection(
                    title: "Language Support",
                    icon: "character.bubble",
                    content: "The app supports OCR in multiple languages. You can set your preferred language in Settings. The app will also attempt to automatically detect the language of your scanned text."
                )
                
                // Image Enhancement
                helpSection(
                    title: "Image Enhancement",
                    icon: "wand.and.stars",
                    content: "Enable image enhancement to improve text recognition quality, especially for documents with poor contrast or lighting conditions."
                )
                
                // Albums
                helpSection(
                    title: "Albums",
                    icon: "folder",
                    content: "Organize your scanned documents into albums. Create a new album from the Albums tab or when viewing a scanned document. You can view, share, and export documents from your albums."
                )
                
                // Troubleshooting
                helpSection(
                    title: "Troubleshooting",
                    icon: "exclamationmark.triangle",
                    content: "If you encounter issues with scanning or text recognition, try the following:\n• Ensure good lighting conditions\n• Hold the camera steady\n• Make sure the document is flat and fully visible\n• Try enabling image enhancement"
                )
            }
            .padding()
        }
        .navigationTitle("Help")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func helpSection(title: String, icon: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            Text(content)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 36)
        }
        .padding(.vertical, 8)
    }
} 
import SwiftUI

struct TranslationView: View {
    @ObservedObject var scannerModel: DocumentScannerModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingLanguageSelector = false
    @State private var showingShareSheet = false
    @State private var textToShare: String = ""
    @State private var showingCopyConfirmation = false
    @State private var showingSettings = false
    @AppStorage("deepLApiKey") private var deepLApiKey = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.blue)
                    }
                    .accessibilityLabel("Go back")
                    
                    Spacer()
                }
                
                Text("Translation")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                
                HStack {
                    Spacer()
                    
                    Button(action: {
                        showingLanguageSelector = true
                    }) {
                        Image(systemName: "globe")
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                    }
                    .accessibilityLabel("Select language")
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // API Key Warning if needed
                    if deepLApiKey.isEmpty {
                        apiKeyWarningView
                    }
                    
                    // Language information
                    languageSelectionBar
                    
                    // Original text
                    textSection(
                        title: "Original Text",
                        text: scannerModel.scannedText,
                        isProcessing: false,
                        error: nil,
                        emptyMessage: "No text available."
                    )
                    
                    // Translated text
                    textSection(
                        title: "Translated Text",
                        text: scannerModel.translatedText,
                        isProcessing: scannerModel.isTranslating,
                        error: scannerModel.translationError,
                        emptyMessage: "No translation available. Select a language and tap 'Translate'."
                    )
                }
                .padding()
            }
            
            // Bottom action button
            VStack {
                Button(action: {
                    if deepLApiKey.isEmpty {
                        showingSettings = true
                    } else {
                        scannerModel.translateText()
                    }
                }) {
                    HStack {
                        if scannerModel.isTranslating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: deepLApiKey.isEmpty ? "key" : "globe")
                                .font(.headline)
                        }
                        Text(deepLApiKey.isEmpty ? "Set API Key" : "Translate")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(scannerModel.isTranslating || scannerModel.scannedText.isEmpty ? Color.blue.opacity(0.7) : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(scannerModel.isTranslating || (scannerModel.scannedText.isEmpty && !deepLApiKey.isEmpty))
                .padding()
                .accessibilityHint(deepLApiKey.isEmpty ? "Set DeepL API key in settings" : "Translate text to \(scannerModel.targetLanguage.displayName)")
            }
            .background(Color(.systemBackground))
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: -2)
        }
        .navigationBarHidden(true)
        .actionSheet(isPresented: $showingLanguageSelector) {
            ActionSheet(
                title: Text("Select Target Language"),
                message: Text("Choose the language to translate to"),
                buttons: languageButtons()
            )
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [textToShare])
        }
        .overlay(
            showingCopyConfirmation ?
                VStack {
                    Spacer()
                    Text("Copied to clipboard")
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.bottom, 100)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.easeInOut, value: showingCopyConfirmation)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation {
                            showingCopyConfirmation = false
                        }
                    }
                }
                : nil
        )
        .background(
            NavigationLink(destination: SettingsView(scannerModel: scannerModel), isActive: $showingSettings) {
                EmptyView()
            }
        )
    }
    
    private var apiKeyWarningView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.orange)
                Text("API Key Required")
                    .font(.headline)
                    .foregroundColor(.orange)
            }
            
            Text("To use translation features, you need to set up your DeepL API key in Settings.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: {
                showingSettings = true
            }) {
                Text("Go to Settings")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var languageSelectionBar: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("From")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(scannerModel.detectedLanguage ?? "Auto-detected")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if scannerModel.detectedLanguage == nil {
                        Image(systemName: "questionmark.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Image(systemName: "arrow.right")
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("To")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(scannerModel.targetLanguage.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: {
                showingLanguageSelector = true
            }) {
                Text("Change")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            .accessibilityHint("Change target language")
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func textSection(title: String, text: String, isProcessing: Bool, error: String?, emptyMessage: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                if !text.isEmpty {
                    HStack(spacing: 16) {
                        Button(action: {
                            textToShare = text
                            showingShareSheet = true
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                        }
                        .accessibilityLabel("Share \(title.lowercased())")
                        
                        Button(action: {
                            UIPasteboard.general.string = text
                            withAnimation {
                                showingCopyConfirmation = true
                            }
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                        }
                        .accessibilityLabel("Copy \(title.lowercased())")
                    }
                }
            }
            
            Group {
                if isProcessing {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Translating...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 20)
                } else if let error = error {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.red)
                            Text("Translation Error")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                        }
                        
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if error.contains("API key") {
                            Button(action: {
                                showingSettings = true
                            }) {
                                Text("Set API Key in Settings")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                } else if text.isEmpty {
                    Text(emptyMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                } else {
                    Text(text)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .textSelection(.enabled)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }
    
    // Generate language selection buttons
    private func languageButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []
        
        // Add a button for each supported language
        for language in DocumentScannerModel.TranslationLanguage.allCases {
            let isSelected = scannerModel.targetLanguage == language
            buttons.append(.default(Text(isSelected ? "\(language.displayName) ✓" : language.displayName)) {
                scannerModel.targetLanguage = language
                if !deepLApiKey.isEmpty {
                    scannerModel.translateText()
                }
            })
        }
        
        // Add cancel button
        buttons.append(.cancel())
        
        return buttons
    }
}

// Preview
struct TranslationView_Previews: PreviewProvider {
    static var previews: some View {
        let model = DocumentScannerModel()
        model.scannedText = "This is a sample text that would be translated."
        model.translatedText = "Dies ist ein Beispieltext, der übersetzt werden würde."
        model.detectedLanguage = "English"
        model.targetLanguage = .german
        
        return TranslationView(scannerModel: model)
    }
} 
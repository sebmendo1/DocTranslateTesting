import SwiftUI

struct TranslationView: View {
    @ObservedObject var scannerModel: DocumentScannerModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingLanguageSelector = false
    @State private var showingShareSheet = false
    @State private var textToShare: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                }
                
                Spacer()
                
                Text("Translation")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    showingLanguageSelector = true
                }) {
                    Image(systemName: "globe")
                        .font(.title3)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Language information
                    HStack {
                        VStack(alignment: .leading) {
                            Text("From")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(scannerModel.detectedLanguage ?? "Auto-detected")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Image(systemName: "arrow.right")
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading) {
                            Text("To")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(scannerModel.targetLanguage.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showingLanguageSelector = true
                        }) {
                            Text("Change")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    // Original text
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Original Text")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: {
                                textToShare = scannerModel.scannedText
                                showingShareSheet = true
                            }) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.subheadline)
                            }
                            
                            Button(action: {
                                UIPasteboard.general.string = scannerModel.scannedText
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .font(.subheadline)
                            }
                        }
                        
                        Text(scannerModel.scannedText)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .textSelection(.enabled)
                    }
                    
                    // Translated text
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Translated Text")
                                .font(.headline)
                            
                            Spacer()
                            
                            if scannerModel.isTranslating {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Button(action: {
                                    textToShare = scannerModel.translatedText
                                    showingShareSheet = true
                                }) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.subheadline)
                                }
                                .disabled(scannerModel.translatedText.isEmpty)
                                
                                Button(action: {
                                    UIPasteboard.general.string = scannerModel.translatedText
                                }) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.subheadline)
                                }
                                .disabled(scannerModel.translatedText.isEmpty)
                            }
                        }
                        
                        if scannerModel.isTranslating {
                            HStack {
                                Spacer()
                                ProgressView("Translating...")
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        } else if let error = scannerModel.translationError {
                            Text("Translation error: \(error)")
                                .foregroundColor(.red)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        } else if scannerModel.translatedText.isEmpty {
                            Text("No translation available. Select a language and tap 'Translate'.")
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        } else {
                            Text(scannerModel.translatedText)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .textSelection(.enabled)
                        }
                    }
                }
                .padding()
            }
            
            // Bottom action button
            VStack {
                Button(action: {
                    scannerModel.translateText()
                }) {
                    if scannerModel.isTranslating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Translate")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(scannerModel.isTranslating ? Color.blue.opacity(0.7) : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(scannerModel.isTranslating || scannerModel.scannedText.isEmpty)
                .padding()
            }
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
    }
    
    // Generate language selection buttons
    private func languageButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []
        
        // Add a button for each supported language
        for language in DocumentScannerModel.TranslationLanguage.allCases {
            buttons.append(.default(Text(language.displayName)) {
                scannerModel.targetLanguage = language
                scannerModel.translateText()
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
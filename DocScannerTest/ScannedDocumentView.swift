import SwiftUI
import PDFKit
import NaturalLanguage

struct ScannedDocumentView: View {
    @ObservedObject var scannerModel: DocumentScannerModel
    @State private var selectedPageIndex: Int = 0
    @State private var showShareSheet = false
    @State private var showLanguageSheet = false
    @State private var pdfData: Data? = nil
    @State private var showingTranslationOptions = false
    @State private var isShowingTranslatedText = false
    @State private var showingTranslationView = false
    
    var body: some View {
        VStack {
            if scannerModel.isProcessing {
                ProgressView("Processing document...", value: scannerModel.progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding()
            } else if let image = scannerModel.scannedImage {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Image preview
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(8)
                            .shadow(radius: 3)
                            .padding(.horizontal)
                        
                        // Text content section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(isShowingTranslatedText ? "Translated Text" : "Extracted Text")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                Spacer()
                                
                                // Translation toggle button
                                if !scannerModel.translatedText.isEmpty {
                                    Button(action: {
                                        isShowingTranslatedText.toggle()
                                    }) {
                                        Text(isShowingTranslatedText ? "Show Original" : "Show Translation")
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            
                            if scannerModel.isTranslating {
                                ProgressView("Translating...")
                                    .padding()
                            } else if let error = scannerModel.translationError {
                                Text("Translation error: \(error)")
                                    .foregroundColor(.red)
                                    .font(.subheadline)
                                    .padding(.horizontal)
                            } else if isShowingTranslatedText && !scannerModel.translatedText.isEmpty {
                                Text(scannerModel.translatedText)
                                    .padding(.horizontal)
                                    .textSelection(.enabled)
                            } else if !scannerModel.scannedText.isEmpty {
                                Text(scannerModel.scannedText)
                                    .padding(.horizontal)
                                    .textSelection(.enabled)
                            } else {
                                Text("No text was detected in this document.")
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                            }
                            
                            // Language information
                            if let detectedLanguage = scannerModel.detectedLanguage {
                                Text("Detected language: \(detectedLanguage)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .shadow(radius: 1)
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                
                // Action buttons
                HStack(spacing: 20) {
                    Button(action: {
                        // Create PDF
                        pdfData = scannerModel.createPDF()
                        showShareSheet = true
                    }) {
                        VStack {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 22))
                            Text("Share")
                                .font(.caption)
                        }
                    }
                    
                    Button(action: {
                        showingTranslationOptions = true
                    }) {
                        VStack {
                            Image(systemName: "text.bubble")
                                .font(.system(size: 22))
                            Text("Translate")
                                .font(.caption)
                        }
                    }
                    
                    Button(action: {
                        scannerModel.scannedImage = nil
                        scannerModel.scannedText = ""
                        scannerModel.translatedText = ""
                    }) {
                        VStack {
                            Image(systemName: "trash")
                                .font(.system(size: 22))
                            Text("Clear")
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .sheet(isPresented: $showShareSheet) {
                    if let pdfData = pdfData {
                        ShareSheet(items: [pdfData])
                    }
                }
                .actionSheet(isPresented: $showingTranslationOptions) {
                    ActionSheet(
                        title: Text("Translate To"),
                        message: Text("Select target language"),
                        buttons: translationButtons()
                    )
                }
                .background(
                    NavigationLink(destination: TranslationView(scannerModel: scannerModel), isActive: $showingTranslationView) {
                        EmptyView()
                    }
                )
            } else {
                Text("No document scanned")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Scanned Document")
    }
    
    private var createAlbumSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Album Name")) {
                    TextField("Enter album name", text: Binding(
                        get: { 
                            scannerModel.currentAlbum?.name ?? "Scan \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short))"
                        },
                        set: { newValue in
                            if scannerModel.currentAlbum != nil {
                                // This is just a placeholder as we'll create the album on button press
                            }
                        }
                    ))
                }
                
                Section {
                    Button(action: {
                        // Create a new album with the current scans
                        let albumName = scannerModel.currentAlbum?.name ?? "Scan \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short))"
                        scannerModel.createAlbum(name: albumName)
                        showLanguageSheet = false
                    }) {
                        Text("Save to Album")
                    }
                }
            }
            .navigationTitle("Save to Album")
            .navigationBarItems(trailing: Button("Cancel") {
                showLanguageSheet = false
            })
        }
    }
    
    // Generate translation buttons for all supported languages
    private func translationButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []
        
        // Add a button for each supported language
        for language in DocumentScannerModel.TranslationLanguage.allCases {
            buttons.append(.default(Text(language.displayName)) {
                translateTo(language)
            })
        }
        
        // Add a button for the full translation view
        buttons.append(.default(Text("Advanced Translation")) {
            showingTranslationView = true
        })
        
        // Add cancel button
        buttons.append(.cancel())
        
        return buttons
    }
    
    // Translate text to selected language
    private func translateTo(_ language: DocumentScannerModel.TranslationLanguage) {
        // Set target language
        scannerModel.targetLanguage = language
        
        // Start translation
        scannerModel.translateText { success in
            if success {
                isShowingTranslatedText = true
            }
        }
    }
}

// ShareSheet for sharing PDF
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
} 
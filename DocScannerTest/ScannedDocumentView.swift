import SwiftUI
import PDFKit
import NaturalLanguage

struct ScannedDocumentView: View {
    @ObservedObject var scannerModel: DocumentScannerModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingTranslationView = false
    @State private var showingLanguageSelector = false
    @State private var showingShareSheet = false
    @State private var showingAlbumSheet = false
    @State private var showingSettingsSheet = false
    @State private var newAlbumName = ""
    @State private var showingDeleteConfirmation = false
    @State private var textToShare: String = ""
    @State private var showingOriginalText = true
    @AppStorage("deepLApiKey") private var deepLApiKey = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Document image
                if let image = scannerModel.scannedImage {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(12)
                            .shadow(radius: 2)
                            .accessibilityLabel("Scanned document image")
                        
                        // Enhancement indicator
                        if scannerModel.enhancedImage {
                            Text("Enhanced")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .padding(8)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Language detection info
                if let detectedLanguage = scannerModel.detectedLanguage {
                    HStack {
                        Image(systemName: "text.magnifyingglass")
                            .foregroundColor(.secondary)
                        Text("Detected language: \(detectedLanguage)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .accessibilityLabel("Detected language is \(detectedLanguage)")
                }
                
                // Text content section
                VStack(spacing: 16) {
                    // Text toggle
                    if !scannerModel.translatedText.isEmpty {
                        Picker("Text Display", selection: $showingOriginalText) {
                            Text("Original").tag(true)
                            Text("Translated").tag(false)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                    }
                    
                    // Text content
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(showingOriginalText ? "Extracted Text" : "Translated Text")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: {
                                UIPasteboard.general.string = showingOriginalText ? scannerModel.scannedText : scannerModel.translatedText
                            }) {
                                Label("Copy", systemImage: "doc.on.doc")
                                    .font(.subheadline)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .accessibilityLabel("Copy text")
                        }
                        
                        if showingOriginalText {
                            if scannerModel.scannedText.isEmpty {
                                Text("No text was detected in this document.")
                                    .italic()
                                    .foregroundColor(.secondary)
                            } else {
                                Text(scannerModel.scannedText)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .textSelection(.enabled)
                            }
                        } else {
                            if scannerModel.isTranslating {
                                HStack {
                                    Spacer()
                                    ProgressView("Translating...")
                                    Spacer()
                                }
                            } else if let error = scannerModel.translationError {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Translation error: \(error)")
                                        .foregroundColor(.red)
                                    
                                    if error.contains("API key") {
                                        Button(action: {
                                            showingSettingsSheet = true
                                        }) {
                                            Text("Set API Key in Settings")
                                                .font(.subheadline)
                                                .foregroundColor(.blue)
                                        }
                                        .padding(.top, 4)
                                    }
                                }
                            } else {
                                Text(scannerModel.translatedText)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Quick translation buttons
                if !scannerModel.scannedText.isEmpty && scannerModel.translatedText.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Translate")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if deepLApiKey.isEmpty {
                            // API Key warning
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.orange)
                                Text("API Key Required for Translation")
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                                
                                Spacer()
                                
                                Button(action: {
                                    showingSettingsSheet = true
                                }) {
                                    Text("Set Key")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(DocumentScannerModel.TranslationLanguage.allCases.prefix(5)) { language in
                                        Button(action: {
                                            scannerModel.targetLanguage = language
                                            scannerModel.translateText()
                                        }) {
                                            Text(language.displayName)
                                                .font(.subheadline)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(Color.blue.opacity(0.1))
                                                .foregroundColor(.blue)
                                                .cornerRadius(16)
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                        .disabled(scannerModel.isTranslating)
                                    }
                                    
                                    Button(action: {
                                        showingLanguageSelector = true
                                    }) {
                                        Text("More...")
                                            .font(.subheadline)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Color(.systemGray5))
                                            .foregroundColor(.primary)
                                            .cornerRadius(16)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Action buttons
                VStack(spacing: 16) {
                    // Primary actions
                    HStack(spacing: 16) {
                        Button(action: {
                            textToShare = showingOriginalText ? scannerModel.scannedText : scannerModel.translatedText
                            showingShareSheet = true
                        }) {
                            VStack {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 22))
                                Text("Share")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                        }
                        .accessibilityLabel("Share document")
                        
                        NavigationLink(destination: TranslationView(scannerModel: scannerModel), isActive: $showingTranslationView) {
                            Button(action: {
                                showingTranslationView = true
                            }) {
                                VStack {
                                    Image(systemName: "globe")
                                        .font(.system(size: 22))
                                    Text("Translate")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray5))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                            }
                            .accessibilityLabel("Translate document")
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        Button(action: {
                            showingAlbumSheet = true
                        }) {
                            VStack {
                                Image(systemName: "folder.badge.plus")
                                    .font(.system(size: 22))
                                Text("Save")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                        }
                        .accessibilityLabel("Save to album")
                    }
                    .padding(.horizontal)
                    
                    // Secondary actions
                    HStack(spacing: 16) {
                        Button(action: {
                            exportToPDF()
                        }) {
                            VStack {
                                Image(systemName: "arrow.down.doc")
                                    .font(.system(size: 22))
                                Text("PDF")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                        }
                        .accessibilityLabel("Export as PDF")
                        
                        Button(action: {
                            showingDeleteConfirmation = true
                        }) {
                            VStack {
                                Image(systemName: "trash")
                                    .font(.system(size: 22))
                                Text("Clear")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray5))
                            .foregroundColor(.red)
                            .cornerRadius(12)
                        }
                        .accessibilityLabel("Clear document")
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Scanned Document")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    textToShare = showingOriginalText ? scannerModel.scannedText : scannerModel.translatedText
                    showingShareSheet = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Share")
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [textToShare])
        }
        .sheet(isPresented: $showingAlbumSheet) {
            saveToAlbumSheet
        }
        .sheet(isPresented: $showingSettingsSheet) {
            SettingsView(scannerModel: scannerModel)
        }
        .actionSheet(isPresented: $showingLanguageSelector) {
            ActionSheet(
                title: Text("Select Target Language"),
                message: Text("Choose the language to translate to"),
                buttons: languageButtons()
            )
        }
        .alert(isPresented: $showingDeleteConfirmation) {
            Alert(
                title: Text("Clear Document"),
                message: Text("Are you sure you want to clear this document? This action cannot be undone."),
                primaryButton: .destructive(Text("Clear")) {
                    clearDocument()
                    presentationMode.wrappedValue.dismiss()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private var saveToAlbumSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Save to Album")) {
                    if scannerModel.albums.isEmpty {
                        Text("No albums available. Create a new album.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(scannerModel.albums) { album in
                            Button(action: {
                                saveToExistingAlbum(album)
                            }) {
                                HStack {
                                    Text(album.name)
                                    Spacer()
                                    Text("\(album.images.count) images")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Create New Album")) {
                    TextField("Album Name", text: $newAlbumName)
                    
                    Button(action: {
                        createNewAlbumAndSave()
                    }) {
                        Text("Create and Save")
                    }
                    .disabled(newAlbumName.isEmpty)
                }
            }
            .navigationTitle("Save to Album")
            .navigationBarItems(trailing: Button("Cancel") {
                showingAlbumSheet = false
            })
        }
    }
    
    private func languageButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []
        
        if deepLApiKey.isEmpty {
            buttons.append(.default(Text("Set API Key in Settings")) {
                showingSettingsSheet = true
            })
        } else {
            for language in DocumentScannerModel.TranslationLanguage.allCases {
                buttons.append(.default(Text(language.displayName)) {
                    scannerModel.targetLanguage = language
                    scannerModel.translateText()
                })
            }
        }
        
        buttons.append(.cancel())
        
        return buttons
    }
    
    private func exportToPDF() {
        guard let image = scannerModel.scannedImage else { return }
        
        let pdfData = scannerModel.createPDF(from: [image], includeText: true)
        
        let activityVC = UIActivityViewController(
            activityItems: [pdfData],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
    
    private func clearDocument() {
        scannerModel.scannedImage = nil
        scannerModel.scannedText = ""
        scannerModel.translatedText = ""
        scannerModel.detectedLanguage = nil
    }
    
    private func saveToExistingAlbum(_ album: DocumentScannerModel.Album) {
        if let image = scannerModel.scannedImage {
            scannerModel.addImageToAlbum(image, albumId: album.id)
            showingAlbumSheet = false
        }
    }
    
    private func createNewAlbumAndSave() {
        if !newAlbumName.isEmpty, let image = scannerModel.scannedImage {
            let album = scannerModel.createAlbum(name: newAlbumName)
            scannerModel.addImageToAlbum(image, albumId: album.id)
            newAlbumName = ""
            showingAlbumSheet = false
        }
    }
}

// ShareSheet for sharing PDF
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
} 
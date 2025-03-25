import SwiftUI
import PDFKit
import NaturalLanguage

struct ScannedDocumentView: View {
    @ObservedObject var scannerModel: DocumentScannerModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingTranslationView = false
    @State private var showingLanguageSelector = false
    @State private var showingShareSheet = false
    @State private var showingSettingsSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var showingOriginalScan = false
    @State private var showingShareOptions = false
    @State private var textToShare: String = ""
    @State private var selectedTab = 0 // 0 for original, 1 for translation
    @State private var documentTitle: String = ""
    @State private var shareOption: ShareOption = .text
    @AppStorage("deepLApiKey") private var deepLApiKey = ""
    
    // Define share options
    enum ShareOption {
        case text
        case image
        case combinedPDF
    }
    
    init(scannerModel: DocumentScannerModel, initialDocumentTitle: String = "") {
        self.scannerModel = scannerModel
        self._documentTitle = State(initialValue: initialDocumentTitle)
    }
    
    // Memory optimization - called when view appears/disappears
    private func optimizeMemory(active: Bool) {
        if active {
            // View is active, ensure we have necessary resources
        } else {
            // View is disappearing, clean up resources
            scannerModel.cleanupMemory()
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.large) {
                // Document title field
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("Document Title")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(.themeTextPrimary)
                    
                    TextField("Enter document title", text: $documentTitle)
                        .font(AppTheme.Typography.body)
                        .padding()
                        .background(Color.themeBackgroundSecondary)
                        .cornerRadius(AppTheme.CornerRadius.small)
                        .onChange(of: scannerModel.scannedText) { newValue in
                            if documentTitle.isEmpty {
                                documentTitle = scannerModel.generateDocumentTitle(from: newValue)
                            }
                        }
                        
                    // Show language pills if we have scanned text
                    if !scannerModel.scannedText.isEmpty {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                            // Add description text
                            Text("Translate to:")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundColor(.themeTextSecondary)
                                
                            // Language pills
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: AppTheme.Spacing.small) {
                                    // Display common languages as pills
                                    ForEach(DocumentScannerModel.TranslationLanguage.allCases.prefix(6)) { language in
                                        QuickTranslationPill(language: language)
                                    }
                                    
                                    // More languages button
                                    Button(action: {
                                        showingLanguageSelector = true
                                    }) {
                                        Text("More")
                                            .font(AppTheme.Typography.subheadline)
                                            .padding(.horizontal, AppTheme.Spacing.medium)
                                            .padding(.vertical, AppTheme.Spacing.small)
                                            .background(Color.themeBackgroundSecondary)
                                            .foregroundColor(.themePrimary)
                                            .cornerRadius(AppTheme.CornerRadius.pill)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.pill)
                                                    .stroke(Color.themePrimary.opacity(0.3), lineWidth: 1)
                                            )
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(.top, AppTheme.Spacing.xsmall)
                        .animation(.easeInOut, value: scannerModel.scannedText.isEmpty)
                    }
                }
                .padding(.horizontal)
                
                // Language detection info
                if let detectedLanguage = scannerModel.detectedLanguage {
                    HStack {
                        Image(systemName: "text.magnifyingglass")
                            .foregroundColor(.themeTextSecondary)
                        Text("Detected language: \(detectedLanguage)")
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(.themeTextSecondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .accessibilityLabel("Detected language is \(detectedLanguage)")
                }
                
                // Tab-style selector
                HStack(spacing: 0) {
                    // Original Text Tab
                    Button(action: {
                        selectedTab = 0
                    }) {
                        VStack(spacing: 8) {
                            Text("Original Text")
                                .font(AppTheme.Typography.subheadline)
                                .fontWeight(selectedTab == 0 ? .semibold : .regular)
                                .foregroundColor(selectedTab == 0 ? .themePrimary : .themeTextSecondary)
                                .padding(.top, 8)
                            
                            // Active indicator
                            Rectangle()
                                .fill(selectedTab == 0 ? Color.themePrimary : Color.clear)
                                .frame(height: 3)
                        }
                        .frame(maxWidth: .infinity)
                        .background(selectedTab == 0 ? Color.themePrimary.opacity(0.05) : Color.clear)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityAddTraits(selectedTab == 0 ? [.isSelected] : [])
                    
                    // Translation Tab
                    Button(action: {
                        selectedTab = 1
                        // If not yet translated, trigger translation
                        if scannerModel.translatedText.isEmpty && !scannerModel.scannedText.isEmpty {
                            scannerModel.translateText()
                        }
                    }) {
                        VStack(spacing: 8) {
                            Text("Translation")
                                .font(AppTheme.Typography.subheadline)
                                .fontWeight(selectedTab == 1 ? .semibold : .regular)
                                .foregroundColor(selectedTab == 1 ? .themePrimary : .themeTextSecondary)
                                .padding(.top, 8)
                            
                            // Active indicator
                            Rectangle()
                                .fill(selectedTab == 1 ? Color.themePrimary : Color.clear)
                                .frame(height: 3)
                        }
                        .frame(maxWidth: .infinity)
                        .background(selectedTab == 1 ? Color.themePrimary.opacity(0.05) : Color.clear)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityAddTraits(selectedTab == 1 ? [.isSelected] : [])
                }
                .background(Color.themeBackgroundSecondary)
                .cornerRadius(AppTheme.CornerRadius.medium)
                .padding(.horizontal)
                
                // Text content section
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    HStack {
                        Text(selectedTab == 0 ? "Extracted Text" : "Translated Text")
                            .font(AppTheme.Typography.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            UIPasteboard.general.string = selectedTab == 0 ? scannerModel.scannedText : scannerModel.translatedText
                        }) {
                            Label("Copy", systemImage: "doc.on.doc")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundColor(.themePrimary)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .accessibilityLabel("Copy text")
                    }
                    
                    if selectedTab == 0 {
                        if scannerModel.scannedText.isEmpty {
                            Text("No text was detected in this document.")
                                .italic()
                                .font(AppTheme.Typography.body)
                                .foregroundColor(.themeTextSecondary)
                        } else {
                            Text(scannerModel.scannedText)
                                .font(AppTheme.Typography.body)
                                .fixedSize(horizontal: false, vertical: true)
                                .textSelection(.enabled)
                        }
                    } else {
                        if scannerModel.isTranslating {
                            HStack {
                                Spacer()
                                ProgressView("Translating...")
                                    .font(AppTheme.Typography.body)
                                Spacer()
                            }
                        } else if let error = scannerModel.translationError {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                                Text("Translation error: \(error)")
                                    .font(AppTheme.Typography.body)
                                    .foregroundColor(.themeError)
                                
                                if error.contains("API key") {
                                    Button(action: {
                                        showingSettingsSheet = true
                                    }) {
                                        Text("Set API Key in Settings")
                                            .font(AppTheme.Typography.subheadline)
                                            .foregroundColor(.themePrimary)
                                    }
                                    .padding(.top, AppTheme.Spacing.xsmall)
                                }
                            }
                        } else if scannerModel.translatedText.isEmpty {
                            // Translation language selection
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                                Text("Select language for translation:")
                                    .font(AppTheme.Typography.subheadline)
                                    .foregroundColor(.themeTextSecondary)
                                
                                if deepLApiKey.isEmpty {
                                    // API Key warning
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle")
                                            .foregroundColor(.themeWarning)
                                        Text("API Key Required for Translation")
                                            .font(AppTheme.Typography.subheadline)
                                            .foregroundColor(.themeWarning)
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            showingSettingsSheet = true
                                        }) {
                                            Text("Set Key")
                                                .font(AppTheme.Typography.subheadline)
                                                .foregroundColor(.themePrimary)
                                        }
                                    }
                                    .padding()
                                    .background(Color.themeWarning.opacity(0.1))
                                    .cornerRadius(AppTheme.CornerRadius.small)
                                } else {
                                    LanguageSelectionView()
                                }
                            }
                        } else {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                                // Show translated text
                                Text(scannerModel.translatedText)
                                    .font(AppTheme.Typography.body)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .textSelection(.enabled)
                                
                                // Add divider
                                Divider()
                                    .padding(.vertical, AppTheme.Spacing.small)
                                
                                // Add language selector below the translated text
                                LanguageSelectionView()
                            }
                        }
                    }
                }
                .padding(AppTheme.Spacing.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.themeBackgroundSecondary)
                .cornerRadius(AppTheme.CornerRadius.medium)
                .padding(.horizontal)
                
                // Action buttons
                VStack(spacing: AppTheme.Spacing.medium) {
                    // Primary actions
                    HStack(spacing: AppTheme.Spacing.medium) {
                        Button(action: {
                            textToShare = selectedTab == 0 ? scannerModel.scannedText : scannerModel.translatedText
                            showingShareSheet = true
                        }) {
                            VStack {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 22))
                                Text("Share")
                                    .font(AppTheme.Typography.caption1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppTheme.Spacing.medium)
                            .background(Color.themeBackgroundSecondary)
                            .foregroundColor(.themeTextPrimary)
                            .cornerRadius(AppTheme.CornerRadius.medium)
                        }
                        .accessibilityLabel("Share document")
                        
                        Button(action: {
                            if scannerModel.scannedImages.count > 0 {
                                let pdfData = scannerModel.createPDF(from: scannerModel.scannedImages, includeText: true)
                                
                                // Share the PDF
                                let activityVC = UIActivityViewController(
                                    activityItems: [pdfData],
                                    applicationActivities: nil
                                )
                                
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                   let rootViewController = windowScene.windows.first?.rootViewController {
                                    rootViewController.present(activityVC, animated: true)
                                }
                            }
                        }) {
                            VStack {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 22))
                                Text("PDF")
                                    .font(AppTheme.Typography.caption1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppTheme.Spacing.medium)
                            .background(Color.themeBackgroundSecondary)
                            .foregroundColor(.themeTextPrimary)
                            .cornerRadius(AppTheme.CornerRadius.medium)
                        }
                        .accessibilityLabel("Export as PDF")
                    }
                    .padding(.horizontal)
                    
                    // Secondary actions
                    VStack(spacing: AppTheme.Spacing.medium) {
                        // View Original Scan button
                        Button(action: {
                            showingOriginalScan = true
                        }) {
                            HStack {
                                Image(systemName: "doc.viewfinder")
                                Text("View Original Scan")
                                    .font(AppTheme.Typography.subheadline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.themePrimary)
                            .foregroundColor(.themeButtonText)
                            .cornerRadius(AppTheme.CornerRadius.medium)
                        }
                        .accessibilityLabel("View original scanned image")
                        
                        Button(action: {
                            showingDeleteConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete")
                                    .font(AppTheme.Typography.subheadline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.themeError.opacity(0.1))
                            .foregroundColor(.themeError)
                            .cornerRadius(AppTheme.CornerRadius.medium)
                        }
                        .accessibilityLabel("Delete document")
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Document")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingShareOptions = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Share document")
            }
        }
        .onAppear {
            // Set initial document title from text if empty
            if documentTitle.isEmpty && !scannerModel.scannedText.isEmpty {
                documentTitle = scannerModel.generateDocumentTitle(from: scannerModel.scannedText)
            }
            
            // Optimize memory usage
            optimizeMemory(active: true)
        }
        .onDisappear {
            // Release memory when view disappears
            optimizeMemory(active: false)
        }
        // Handle low memory warning
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
            // Clean up memory when system is under pressure
            scannerModel.cleanupMemory()
        }
        .actionSheet(isPresented: $showingShareOptions) {
            ActionSheet(
                title: Text("Share Document"),
                message: Text("Choose what to share"),
                buttons: [
                    .default(Text("Share Text Only")) {
                        textToShare = selectedTab == 0 ? scannerModel.scannedText : scannerModel.translatedText
                        shareOption = .text
                        showingShareSheet = true
                    },
                    .default(Text("Share Original Image")) {
                        if scannerModel.scannedImage != nil {
                            shareOption = .image
                            showingShareSheet = true
                        }
                    },
                    .default(Text("Share as PDF with Translation")) {
                        shareOption = .combinedPDF
                        showingShareSheet = true
                    },
                    .cancel()
                ]
            )
        }
        .sheet(isPresented: $showingShareSheet) {
            switch shareOption {
            case .text:
                OptimizedShareSheet(items: [textToShare])
            case .image:
                if let image = scannerModel.scannedImage {
                    OptimizedShareSheet(items: [image])
                } else {
                    // Fallback to text if image is nil
                    OptimizedShareSheet(items: [textToShare])
                }
            case .combinedPDF:
                let pdfData = createCombinedPDF()
                OptimizedShareSheet(items: [pdfData])
            }
        }
        .sheet(isPresented: $showingSettingsSheet) {
            SettingsView(scannerModel: scannerModel)
        }
        .sheet(isPresented: $showingOriginalScan) {
            OriginalScanView(image: scannerModel.scannedImage)
        }
        .actionSheet(isPresented: $showingLanguageSelector) {
            ActionSheet(
                title: Text("Select Translation Language"),
                message: Text("Choose the language to translate to"),
                buttons: languageButtons()
            )
        }
        .alert(isPresented: $showingDeleteConfirmation) {
            Alert(
                title: Text("Clear Document"),
                message: Text("Are you sure you want to clear this document? This action cannot be undone."),
                primaryButton: .destructive(Text("Clear")) {
                    deleteScannedData()
                },
                secondaryButton: .cancel()
            )
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
                    // Only update and retranslate if a different language is selected
                    if scannerModel.targetLanguage != language {
                        scannerModel.targetLanguage = language
                        scannerModel.translateText()
                    }
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
    
    private func deleteScannedData() {
        // Reset the scanner model
        scannerModel.resetAll()
        
        // Dismiss the view
        presentationMode.wrappedValue.dismiss()
    }
    
    // Optimize PDF creation to use less memory
    private func createCombinedPDF() -> Data {
        let pdfCreator = PDFCreator()
        return pdfCreator.createPDF(
            title: documentTitle,
            originalImage: scannerModel.scannedImage,
            originalText: scannerModel.scannedText,
            translatedText: scannerModel.translatedText,
            sourceLanguage: scannerModel.detectedLanguage,
            targetLanguage: scannerModel.targetLanguage.displayName
        )
    }
    
    // Add a dedicated component for language selection pills
    private func LanguageSelectionView() -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                Text("Translation language:")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(.themeTextSecondary)
                
                Spacer()
                
                Button(action: {
                    showingLanguageSelector = true
                }) {
                    HStack {
                        Text("More")
                        Image(systemName: "chevron.down")
                    }
                    .font(AppTheme.Typography.caption1)
                    .foregroundColor(.themePrimary)
                }
                .buttonStyle(BorderlessButtonStyle())
                .accessibility(label: Text("More language options"))
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.small) {
                    // Display the most common languages
                    ForEach(DocumentScannerModel.TranslationLanguage.allCases.prefix(5)) { language in
                        LanguagePill(language: language, isSelected: scannerModel.targetLanguage == language)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    // Language pill component
    private func LanguagePill(language: DocumentScannerModel.TranslationLanguage, isSelected: Bool) -> some View {
        Button(action: {
            if scannerModel.targetLanguage != language {
                scannerModel.targetLanguage = language
                // Only call translate if we're not currently translating
                if !scannerModel.isTranslating {
                    scannerModel.translateText()
                }
            }
        }) {
            Text(language.displayName)
                .font(AppTheme.Typography.subheadline)
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.vertical, AppTheme.Spacing.small)
                .background(isSelected ? Color.themePrimary : Color.themePrimary.opacity(0.1))
                .foregroundColor(isSelected ? .white : .themePrimary)
                .cornerRadius(AppTheme.CornerRadius.pill)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.pill)
                        .stroke(isSelected ? Color.themePrimary : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(BorderlessButtonStyle())
        .disabled(scannerModel.isTranslating)
        .accessibility(label: Text(language.displayName))
        .accessibility(hint: Text("Select for translation"))
        .accessibility(addTraits: isSelected ? [.isSelected] : [])
    }
    
    // Quick Translation Pill component for document title area
    private func QuickTranslationPill(language: DocumentScannerModel.TranslationLanguage) -> some View {
        Button(action: {
            // Set the target language and switch to the translation tab
            scannerModel.targetLanguage = language
            selectedTab = 1
            
            // Trigger translation
            if scannerModel.translatedText.isEmpty && !scannerModel.scannedText.isEmpty {
                scannerModel.translateText()
            }
        }) {
            Text(language.displayName)
                .font(AppTheme.Typography.subheadline)
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.vertical, AppTheme.Spacing.small)
                .background(scannerModel.targetLanguage == language ? Color.themePrimary : Color.themeBackgroundSecondary)
                .foregroundColor(scannerModel.targetLanguage == language ? .white : .themePrimary)
                .cornerRadius(AppTheme.CornerRadius.pill)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.pill)
                        .stroke(Color.themePrimary.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(BorderlessButtonStyle())
        .disabled(scannerModel.isTranslating)
        .accessibility(label: Text("Translate to \(language.displayName)"))
        .accessibility(addTraits: scannerModel.targetLanguage == language ? [.isSelected] : [])
    }
}

// Memory-optimized original scan view
struct OriginalScanView: View {
    @Environment(\.presentationMode) var presentationMode
    let image: UIImage?
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        NavigationView {
            VStack {
                if let image = image {
                    // Zoomable and pannable image
                    GeometryReader { geometry in
                        ZStack {
                            // Background color
                            Color.black.edgesIgnoringSafeArea(.all)
                            
                            // Use a more memory-efficient image display
                            Image(uiImage: image)
                                .resizable()
                                .interpolation(.medium) // Balance between quality and memory
                                .antialiased(true)
                                .scaledToFit()
                                .scaleEffect(scale)
                                .offset(offset)
                                .gesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            let delta = value / lastScale
                                            lastScale = value
                                            scale *= delta
                                        }
                                        .onEnded { _ in
                                            lastScale = 1.0
                                        }
                                )
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            offset = CGSize(
                                                width: lastOffset.width + value.translation.width,
                                                height: lastOffset.height + value.translation.height
                                            )
                                        }
                                        .onEnded { _ in
                                            lastOffset = offset
                                        }
                                )
                                .gesture(
                                    TapGesture(count: 2)
                                        .onEnded {
                                            withAnimation(.spring()) {
                                                if scale > 1.0 {
                                                    scale = 1.0
                                                    offset = .zero
                                                    lastOffset = .zero
                                                } else {
                                                    scale = 2.0
                                                }
                                            }
                                        }
                                )
                        }
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.themeWarning)
                        
                        Text("No Image Available")
                            .font(AppTheme.Typography.title2)
                            .fontWeight(.bold)
                        
                        Text("The original scanned image is not available.")
                            .font(AppTheme.Typography.body)
                            .foregroundColor(.themeTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.themeBackgroundPrimary)
                }
            }
            .navigationTitle("Original Scan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Done")
                            .fontWeight(.medium)
                    }
                }
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        // Handle low memory warning
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
            // Reset zoom and offset to reclaim memory
            if scale > 1.0 {
                scale = 1.0
                offset = .zero
                lastOffset = .zero
            }
        }
    }
}

// Memory-efficient ShareSheet
private struct OptimizedShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
        // Set completion handler to clean up memory
        controller.completionWithItemsHandler = { _, _, _, _ in
            // Release large resources after sharing
            if UIApplication.shared.applicationState == .inactive {
                // App is in background, we can safely clear memory
                NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
            }
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Preview
struct ScannedDocumentView_Previews: PreviewProvider {
    static var previews: some View {
        ScannedDocumentView(scannerModel: DocumentScannerModel(), initialDocumentTitle: "Sample Document")
    }
} 

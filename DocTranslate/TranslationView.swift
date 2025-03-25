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
                        .foregroundColor(.themePrimary)
                    }
                    .accessibilityLabel("Go back")
                    
                    Spacer()
                }
                
                Text("Translation")
                    .font(AppTheme.Typography.headline)
                    .accessibilityAddTraits(.isHeader)
                
                HStack {
                    Spacer()
                    
                    Button(action: {
                        showingLanguageSelector = true
                    }) {
                        Image(systemName: "globe")
                            .font(.system(size: 18))
                            .foregroundColor(.themePrimary)
                    }
                    .accessibilityLabel("Select language")
                }
            }
            .padding(AppTheme.Spacing.medium)
            .background(Color.themeBackgroundPrimary)
            .shadow(color: AppTheme.Shadow.small.color.opacity(AppTheme.Shadow.small.opacity), 
                    radius: AppTheme.Shadow.small.radius, 
                    x: AppTheme.Shadow.small.x, 
                    y: AppTheme.Shadow.small.y)
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
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
                .padding(AppTheme.Spacing.medium)
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
                                .progressViewStyle(CircularProgressViewStyle(tint: .themeButtonText))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: deepLApiKey.isEmpty ? "key" : "globe")
                                .font(AppTheme.Typography.headline)
                        }
                        Text(deepLApiKey.isEmpty ? "Set API Key" : "Translate")
                            .font(AppTheme.Typography.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(scannerModel.isTranslating || scannerModel.scannedText.isEmpty ? 
                              Color.themePrimary.opacity(0.7) : Color.themePrimary)
                    .foregroundColor(.themeButtonText)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                }
                .disabled(scannerModel.isTranslating || (scannerModel.scannedText.isEmpty && !deepLApiKey.isEmpty))
                .padding(AppTheme.Spacing.medium)
                .accessibilityHint(deepLApiKey.isEmpty ? "Set DeepL API key in settings" : "Translate text to \(scannerModel.targetLanguage.displayName)")
            }
            .background(Color.themeBackgroundPrimary)
            .shadow(color: AppTheme.Shadow.small.color.opacity(AppTheme.Shadow.small.opacity), 
                    radius: AppTheme.Shadow.small.radius, 
                    x: 0, y: -2)
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
                        .font(AppTheme.Typography.caption1)
                        .padding()
                        .background(Color.themeNeutralDark.opacity(0.7))
                        .foregroundColor(.themeButtonText)
                        .cornerRadius(AppTheme.CornerRadius.small)
                        .padding(.bottom, 100)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(AppTheme.Animation.standard, value: showingCopyConfirmation)
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
            Button(action: {
                showingSettings = true
            }) {
                EmptyView()
            }
            .opacity(0)
        )
        .navigationDestination(isPresented: $showingSettings) {
            SettingsView(scannerModel: scannerModel)
        }
    }
    
    private var apiKeyWarningView: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.themeWarning)
                Text("API Key Required")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(.themeWarning)
            }
            
            Text("To use translation features, you need to set up your DeepL API key in Settings.")
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(.themeTextSecondary)
            
            Button(action: {
                showingSettings = true
            }) {
                Text("Go to Settings")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(.themeButtonText)
                    .padding(.horizontal, AppTheme.Spacing.medium)
                    .padding(.vertical, AppTheme.Spacing.small)
                    .background(Color.themePrimary)
                    .cornerRadius(AppTheme.CornerRadius.small)
            }
            .padding(.top, AppTheme.Spacing.xsmall)
        }
        .padding()
        .background(Color.themeWarning.opacity(0.1))
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    private var languageSelectionBar: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xsmall) {
                Text("From")
                    .font(AppTheme.Typography.caption1)
                    .foregroundColor(.themeTextSecondary)
                
                HStack {
                    Text(scannerModel.detectedLanguage ?? "Auto-detected")
                        .font(AppTheme.Typography.subheadline)
                        .fontWeight(.medium)
                    
                    if scannerModel.detectedLanguage == nil {
                        Image(systemName: "questionmark.circle")
                            .font(AppTheme.Typography.caption1)
                            .foregroundColor(.themeTextSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Image(systemName: "arrow.right")
                .foregroundColor(.themeTextSecondary)
                .padding(.horizontal, AppTheme.Spacing.small)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xsmall) {
                Text("To")
                    .font(AppTheme.Typography.caption1)
                    .foregroundColor(.themeTextSecondary)
                
                Text(scannerModel.targetLanguage.displayName)
                    .font(AppTheme.Typography.subheadline)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: {
                showingLanguageSelector = true
            }) {
                Text("Change")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(.themePrimary)
            }
            .accessibilityHint("Change target language")
        }
        .padding()
        .background(Color.themeBackgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    private func textSection(title: String, text: String, isProcessing: Bool, error: String?, emptyMessage: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Text(title)
                    .font(AppTheme.Typography.headline)
                
                Spacer()
                
                if !text.isEmpty {
                    Menu {
                        Button(action: {
                            UIPasteboard.general.string = text
                            showingCopyConfirmation = true
                        }) {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        
                        Button(action: {
                            textToShare = text
                            showingShareSheet = true
                        }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18))
                            .foregroundColor(.themePrimary)
                    }
                }
            }
            
            Group {
                if isProcessing {
                    HStack {
                        Spacer()
                        VStack(spacing: AppTheme.Spacing.small) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Translating...")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundColor(.themeTextSecondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, AppTheme.Spacing.large)
                } else if let error = error {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.themeError)
                            Text("Translation Error")
                                .font(AppTheme.Typography.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.themeError)
                        }
                        
                        Text(error)
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(.themeTextSecondary)
                        
                        if error.contains("API key") {
                            Button(action: {
                                showingSettings = true
                            }) {
                                Text("Set API Key in Settings")
                                    .font(AppTheme.Typography.subheadline)
                                    .foregroundColor(.themePrimary)
                            }
                            .padding(.top, AppTheme.Spacing.xsmall)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.themeError.opacity(0.1))
                    .cornerRadius(AppTheme.CornerRadius.small)
                } else if text.isEmpty {
                    Text(emptyMessage)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(.themeTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, AppTheme.Spacing.large)
                } else {
                    ScrollView {
                        Text(text)
                            .font(AppTheme.Typography.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 300)
                }
            }
        }
        .padding()
        .background(Color.themeBackgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    // Generate language selection buttons
    private func languageButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []
        
        // Add all language options
        for language in DocumentScannerModel.TranslationLanguage.allCases {
            buttons.append(.default(Text(language.displayName)) {
                scannerModel.targetLanguage = language
                // If we already have text, auto-translate
                if !scannerModel.scannedText.isEmpty && !deepLApiKey.isEmpty {
                    scannerModel.translateText()
                }
            })
        }
        
        // Add cancel button
        buttons.append(.cancel())
        
        return buttons
    }
}

// ShareSheet to enable sharing text

// Preview
struct TranslationView_Previews: PreviewProvider {
    static var previews: some View {
        TranslationView(scannerModel: DocumentScannerModel())
    }
} 
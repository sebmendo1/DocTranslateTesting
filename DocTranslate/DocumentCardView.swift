import SwiftUI

/// A reusable card view for displaying document information
struct DocumentCardView: View, Equatable {
    // MARK: - Properties
    
    /// The document to display
    let document: DocumentScannerModel.SavedDocument
    
    /// The scanner model that manages document data
    @ObservedObject var scannerModel: DocumentScannerModel
    
    /// Optional destination view for navigation
    private let destinationView: AnyView?
    
    // MARK: - Initialization
    
    init(document: DocumentScannerModel.SavedDocument, scannerModel: DocumentScannerModel, destination: (() -> some View)? = nil) {
        self.document = document
        self.scannerModel = scannerModel
        self.destinationView = destination.map { AnyView($0()) }
    }
    
    // Special initializer for previews only
    init(document: DocumentScannerModel.SavedDocument, scannerModel: DocumentScannerModel) {
        self.document = document
        self.scannerModel = scannerModel
        self.destinationView = nil
    }
    
    // MARK: - Equatable
    
    static func == (lhs: DocumentCardView, rhs: DocumentCardView) -> Bool {
        lhs.document.id == rhs.document.id
    }
    
    // MARK: - Body
    
    var body: some View {
        if let destinationView = destinationView {
            NavigationLink(destination: destinationView) {
                cardContent
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            cardContent
        }
    }
    
    // MARK: - Private Views
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            // Header row with title and document icon
            headerRow
            
            // Document text preview
            textPreviewSection
            
            // Footer with metadata
            footerRow
        }
        .padding(AppTheme.Spacing.medium)
        .background(Color.themeBackgroundPrimary)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
        .drawingGroup() // Use Metal rendering for better performance
    }
    
    private var headerRow: some View {
        HStack {
            // Document title
            Text(document.title)
                .font(AppTheme.Typography.headline)
                .fontWeight(.bold)
                .foregroundColor(.themeTextPrimary)
                .lineLimit(1)
            
            Spacer()
            
            // Document icon
            documentIcon
        }
    }
    
    private var documentIcon: some View {
        ZStack {
            Circle()
                .fill(Color.themePrimary.opacity(0.1))
                .frame(width: 34, height: 34)
            
            // Show different icon based on document content
            Image(systemName: iconName)
                .font(.system(size: 16))
                .foregroundColor(Color.themePrimary)
        }
    }
    
    private var iconName: String {
        if document.text.isEmpty {
            return "doc.viewfinder"
        } else if document.detectedLanguage != nil {
            return "doc.text.magnifyingglass"
        } else {
            return "doc.text"
        }
    }
    
    private var textPreviewSection: some View {
        Group {
            if !document.text.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xsmall) {
                    Text(document.thumbnailText)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(.themeTextPrimary)
                        .lineLimit(3)
                }
                .padding(AppTheme.Spacing.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.themeBackgroundSecondary)
                .cornerRadius(AppTheme.CornerRadius.small)
            } else {
                // Show placeholder if no text
                HStack {
                    Text("No text detected")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(.themeTextSecondary)
                        .italic()
                }
                .padding(AppTheme.Spacing.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.themeBackgroundSecondary)
                .cornerRadius(AppTheme.CornerRadius.small)
            }
        }
    }
    
    private var footerRow: some View {
        HStack {
            // Date created
            dateView
            
            Spacer()
            
            // Detected language
            if let language = document.detectedLanguage {
                languageTag(language)
            }
        }
    }
    
    private var dateView: some View {
        HStack(spacing: 4) {
            Image(systemName: "calendar")
                .font(.system(size: 12))
                .foregroundColor(.themeTextSecondary)
            Text(document.date, style: .date)
                .font(AppTheme.Typography.caption1)
                .foregroundColor(.themeTextSecondary)
        }
    }
    
    private func languageTag(_ language: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "text.bubble")
                .font(.system(size: 12))
                .foregroundColor(.themeTextSecondary)
            Text(language)
                .font(AppTheme.Typography.caption1)
                .foregroundColor(.themeTextSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(Color.themeBackgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.pill)
    }
    
    // MARK: - Accessibility
    
    /// Creates a descriptive accessibility label for the document card
    private var accessibilityLabel: String {
        var label = "Document: \(document.title)"
        
        if !document.text.isEmpty {
            label += ", contains text"
        } else {
            label += ", no text detected"
        }
        
        if let language = document.detectedLanguage {
            label += ", language: \(language)"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        label += ", created on \(dateFormatter.string(from: document.date))"
        
        return label
    }
}

// MARK: - PreviewProvider
struct DocumentCardView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Document with text and detected language
            DocumentCardView(
                document: DocumentScannerModel.SavedDocument(
                    id: UUID(),
                    image: UIImage(systemName: "doc.text")!,
                    text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam eget justo nec magna commodo tincidunt.",
                    date: Date(),
                    detectedLanguage: "English",
                    title: "Document with text and language"
                ),
                scannerModel: DocumentScannerModel()
            )
            .padding()
            .previewDisplayName("Document with text and language")
            
            // Document with text but no detected language
            DocumentCardView(
                document: DocumentScannerModel.SavedDocument(
                    id: UUID(),
                    image: UIImage(systemName: "doc.text")!,
                    text: "Sample text content for a document without language detection.",
                    date: Date(),
                    detectedLanguage: nil,
                    title: "Document with text only"
                ),
                scannerModel: DocumentScannerModel()
            )
            .padding()
            .previewDisplayName("Document with text, no language")
            
            // Empty document with no text
            DocumentCardView(
                document: DocumentScannerModel.SavedDocument(
                    id: UUID(),
                    image: UIImage(systemName: "doc")!,
                    text: "",
                    date: Date(),
                    detectedLanguage: nil,
                    title: "Empty document"
                ),
                scannerModel: DocumentScannerModel()
            )
            .padding()
            .previewDisplayName("Empty document")
            
            // Dark mode preview
            DocumentCardView(
                document: DocumentScannerModel.SavedDocument(
                    id: UUID(),
                    image: UIImage(systemName: "doc.text")!,
                    text: "This is a preview of the document card in dark mode.",
                    date: Date(),
                    detectedLanguage: "Spanish",
                    title: "Dark mode document"
                ),
                scannerModel: DocumentScannerModel()
            )
            .padding()
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark mode")
        }
        .previewLayout(.sizeThatFits)
    }
} 

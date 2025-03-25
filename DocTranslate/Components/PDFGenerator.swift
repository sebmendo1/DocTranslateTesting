import PDFKit
import UIKit

class PDFGenerator {
    // PDF quality settings
    private let compressionQuality: CGFloat = 0.8
    private let imageScaleFactor: CGFloat = 1.0
    
    // Rendering settings
    private let fontSize: CGFloat = 12.0
    private let fontSizeHeading: CGFloat = 16.0
    private let pageMargin: CGFloat = 50.0
    
    // Memory management
    private var renderingInProgress = false
    
    func createDocumentPDF(
        title: String?,
        image: UIImage,
        originalText: String?,
        translatedText: String?,
        sourceLanguage: String?,
        targetLanguage: String?,
        completion: @escaping (Data?) -> Void
    ) {
        // Execute on background thread to avoid blocking the UI
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            // Create PDF document
            let pdfDocument = PDFDocument()
            
            // Add image page
            if let imagePage = self.createImagePage(image: image, title: title) {
                pdfDocument.insert(imagePage, at: 0)
            }
            
            // Add text pages if available
            if let originalText = originalText, !originalText.isEmpty {
                if let textPage = self.createTextPage(
                    text: originalText,
                    title: "Original Text (\(sourceLanguage ?? "Unknown Language"))"
                ) {
                    pdfDocument.insert(textPage, at: pdfDocument.pageCount)
                }
            }
            
            if let translatedText = translatedText, !translatedText.isEmpty {
                if let translationPage = self.createTextPage(
                    text: translatedText,
                    title: "Translation (\(targetLanguage ?? "Unknown Language"))"
                ) {
                    pdfDocument.insert(translationPage, at: pdfDocument.pageCount)
                }
            }
            
            // Convert PDF to data
            let pdfData = pdfDocument.dataRepresentation()
            
            // Return on main thread
            DispatchQueue.main.async {
                completion(pdfData)
            }
        }
    }
    
    // Create a PDF page with an image
    private func createImagePage(image: UIImage, title: String?) -> PDFPage? {
        // Page setup code
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        
        let renderer = UIGraphicsImageRenderer(bounds: pageRect)
        let pageImage = renderer.image { context in
            // Draw white background
            UIColor.white.set()
            context.fill(pageRect)
            
            // Draw title if available
            if let title = title {
                let titleFont = UIFont.boldSystemFont(ofSize: fontSizeHeading)
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: titleFont,
                    .foregroundColor: UIColor.black
                ]
                
                let titleSize = title.size(withAttributes: titleAttributes)
                let titleRect = CGRect(
                    x: (pageRect.width - titleSize.width) / 2,
                    y: pageMargin,
                    width: titleSize.width,
                    height: titleSize.height
                )
                
                title.draw(in: titleRect, withAttributes: titleAttributes)
            }
            
            // Calculate image size to fit within margins
            let maxWidth = pageRect.width - (pageMargin * 2)
            let maxHeight = pageRect.height - (pageMargin * 3 + (title != nil ? 30 : 0))
            
            let aspectRatio = image.size.width / image.size.height
            var imageSize = CGSize(width: maxWidth, height: maxWidth / aspectRatio)
            
            if imageSize.height > maxHeight {
                imageSize = CGSize(width: maxHeight * aspectRatio, height: maxHeight)
            }
            
            // Center image on page
            let imageRect = CGRect(
                x: (pageRect.width - imageSize.width) / 2,
                y: pageMargin * 1.5 + (title != nil ? 30 : 0),
                width: imageSize.width,
                height: imageSize.height
            )
            
            image.draw(in: imageRect)
        }
        
        return PDFPage(image: pageImage)
    }
    
    // Create a PDF page with text content
    private func createTextPage(text: String, title: String?) -> PDFPage? {
        // Text page rendering code
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        
        // Use text rendering with efficient line breaking
        let renderer = UIGraphicsImageRenderer(bounds: pageRect)
        let pageImage = renderer.image { context in
            // Draw white background
            UIColor.white.set()
            context.fill(pageRect)
            
            // Draw title
            var yPosition: CGFloat = pageMargin
            
            if let title = title {
                let titleFont = UIFont.boldSystemFont(ofSize: fontSizeHeading)
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: titleFont,
                    .foregroundColor: UIColor.black
                ]
                
                let titleSize = title.size(withAttributes: titleAttributes)
                let titleRect = CGRect(
                    x: pageMargin,
                    y: yPosition,
                    width: titleSize.width,
                    height: titleSize.height
                )
                
                title.draw(in: titleRect, withAttributes: titleAttributes)
                yPosition += titleSize.height + 20
            }
            
            // Draw text with efficient text layout
            let textRect = CGRect(
                x: pageMargin,
                y: yPosition,
                width: pageRect.width - (pageMargin * 2),
                height: pageRect.height - yPosition - pageMargin
            )
            
            let textFont = UIFont.systemFont(ofSize: fontSize)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = .byWordWrapping
            paragraphStyle.alignment = .natural
            
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: textFont,
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraphStyle
            ]
            
            // Use TextKit for efficient text rendering
            let attributedText = NSAttributedString(string: text, attributes: textAttributes)
            let textStorage = NSTextStorage(attributedString: attributedText)
            let textContainer = NSTextContainer(size: textRect.size)
            let layoutManager = NSLayoutManager()
            
            layoutManager.addTextContainer(textContainer)
            textStorage.addLayoutManager(layoutManager)
            
            textContainer.lineFragmentPadding = 0
            
            // Draw the glyphs
            layoutManager.drawGlyphs(forGlyphRange: NSRange(location: 0, length: attributedText.length), at: textRect.origin)
        }
        
        return PDFPage(image: pageImage)
    }
    
    // Cancel any ongoing generation
    func cancelGeneration() {
        // Implementation would depend on how you track ongoing tasks
        renderingInProgress = false
    }
} 
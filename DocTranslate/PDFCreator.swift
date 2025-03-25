import UIKit
import PDFKit

/// A utility class for creating PDF documents from document scanner data
class PDFCreator {
    
    /// Creates a PDF document containing the original image, original text, and translation
    /// - Parameters:
    ///   - title: Document title
    ///   - originalImage: The scanned document image
    ///   - originalText: The extracted text from the document
    ///   - translatedText: The translated text (if available)
    ///   - sourceLanguage: The detected source language
    ///   - targetLanguage: The target language for translation
    /// - Returns: PDF data ready for sharing
    func createPDF(
        title: String,
        originalImage: UIImage?,
        originalText: String,
        translatedText: String,
        sourceLanguage: String?,
        targetLanguage: String
    ) -> Data {
        // Create a PDF document in memory
        let pageWidth: CGFloat = 612.0  // 8.5 x 11 inches at 72 dpi
        let pageHeight: CGFloat = 792.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        let data = renderer.pdfData { context in
            // First page - Cover with image
            context.beginPage()
            drawCoverPage(in: context.pdfContextBounds, title: title, image: originalImage)
            
            // Second page - Original text
            if !originalText.isEmpty {
                context.beginPage()
                drawTextPage(
                    in: context.pdfContextBounds,
                    title: "Original Text",
                    subtitle: sourceLanguage != nil ? "Language: \(sourceLanguage!)" : nil,
                    content: originalText
                )
            }
            
            // Third page - Translation (if available)
            if !translatedText.isEmpty {
                context.beginPage()
                drawTextPage(
                    in: context.pdfContextBounds,
                    title: "Translation",
                    subtitle: "Language: \(targetLanguage)",
                    content: translatedText
                )
            }
        }
        
        return data
    }
    
    // Draw the cover page with document title and image
    private func drawCoverPage(in rect: CGRect, title: String, image: UIImage?) {
        let titleFont = UIFont.systemFont(ofSize: 28, weight: .bold)
        let textColor = UIColor.black
        
        // Draw title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: textColor
        ]
        
        let titleSize = (title as NSString).size(withAttributes: titleAttributes)
        let titleRect = CGRect(
            x: (rect.width - titleSize.width) / 2,
            y: 60,
            width: titleSize.width,
            height: titleSize.height
        )
        
        (title as NSString).draw(in: titleRect, withAttributes: titleAttributes)
        
        // Draw date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        let dateString = "Created on \(dateFormatter.string(from: Date()))"
        
        let dateFont = UIFont.systemFont(ofSize: 14, weight: .regular)
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: dateFont,
            .foregroundColor: textColor.withAlphaComponent(0.7)
        ]
        
        let dateSize = (dateString as NSString).size(withAttributes: dateAttributes)
        let dateRect = CGRect(
            x: (rect.width - dateSize.width) / 2,
            y: titleRect.maxY + 10,
            width: dateSize.width,
            height: dateSize.height
        )
        
        (dateString as NSString).draw(in: dateRect, withAttributes: dateAttributes)
        
        // Draw image if available
        if let image = image {
            let maxImageWidth: CGFloat = rect.width - 80
            let maxImageHeight: CGFloat = rect.height - dateRect.maxY - 120
            
            let imageSize = image.size
            let aspectRatio = imageSize.width / imageSize.height
            
            var drawSize: CGSize
            if imageSize.width > imageSize.height {
                drawSize = CGSize(width: min(maxImageWidth, imageSize.width), height: min(maxImageWidth / aspectRatio, maxImageHeight))
            } else {
                drawSize = CGSize(width: min(maxImageHeight * aspectRatio, maxImageWidth), height: min(maxImageHeight, imageSize.height))
            }
            
            let imageRect = CGRect(
                x: (rect.width - drawSize.width) / 2,
                y: dateRect.maxY + 40,
                width: drawSize.width,
                height: drawSize.height
            )
            
            image.draw(in: imageRect)
            
            // Draw border around image
            UIColor.darkGray.withAlphaComponent(0.3).setStroke()
            UIBezierPath(rect: imageRect).stroke()
        }
    }
    
    // Draw a page with text content
    private func drawTextPage(in rect: CGRect, title: String, subtitle: String?, content: String) {
        let margin: CGFloat = 50
        let contentRect = rect.insetBy(dx: margin, dy: margin)
        let titleFont = UIFont.systemFont(ofSize: 24, weight: .bold)
        let subtitleFont = UIFont.systemFont(ofSize: 14, weight: .medium)
        let contentFont = UIFont.systemFont(ofSize: 12, weight: .regular)
        
        // Draw title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.black
        ]
        
        let titleHeight = (title as NSString).boundingRect(
            with: CGSize(width: contentRect.width, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: titleAttributes,
            context: nil
        ).height
        
        let titleRect = CGRect(
            x: contentRect.minX,
            y: contentRect.minY,
            width: contentRect.width,
            height: titleHeight
        )
        
        (title as NSString).draw(in: titleRect, withAttributes: titleAttributes)
        
        var currentY = titleRect.maxY + 10
        
        // Draw subtitle if available
        if let subtitle = subtitle {
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: subtitleFont,
                .foregroundColor: UIColor.darkGray
            ]
            
            let subtitleHeight = (subtitle as NSString).boundingRect(
                with: CGSize(width: contentRect.width, height: .greatestFiniteMagnitude),
                options: .usesLineFragmentOrigin,
                attributes: subtitleAttributes,
                context: nil
            ).height
            
            let subtitleRect = CGRect(
                x: contentRect.minX,
                y: currentY,
                width: contentRect.width,
                height: subtitleHeight
            )
            
            (subtitle as NSString).draw(in: subtitleRect, withAttributes: subtitleAttributes)
            currentY = subtitleRect.maxY + 20
        } else {
            currentY += 10
        }
        
        // Draw separator line
        UIColor.lightGray.setStroke()
        let line = UIBezierPath()
        line.move(to: CGPoint(x: contentRect.minX, y: currentY))
        line.addLine(to: CGPoint(x: contentRect.maxX, y: currentY))
        line.stroke()
        
        currentY += 20
        
        // Draw content
        let contentAttributes: [NSAttributedString.Key: Any] = [
            .font: contentFont,
            .foregroundColor: UIColor.black
        ]
        
        let textRect = CGRect(
            x: contentRect.minX,
            y: currentY,
            width: contentRect.width,
            height: contentRect.height - currentY + contentRect.minY
        )
        
        let textStorage = NSTextStorage(string: content, attributes: contentAttributes)
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        
        let textContainer = NSTextContainer(size: textRect.size)
        textContainer.lineFragmentPadding = 0
        layoutManager.addTextContainer(textContainer)
        
        layoutManager.drawGlyphs(forGlyphRange: NSRange(location: 0, length: textStorage.length), at: textRect.origin)
    }
} 
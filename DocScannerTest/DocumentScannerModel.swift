import SwiftUI
import VisionKit
import Vision
import PDFKit
import NaturalLanguage

class DocumentScannerModel: ObservableObject {
    @Published var scannedText: String = ""
    @Published var scannedImage: UIImage?
    @Published var scannedImages: [UIImage] = []
    @Published var isScanning: Bool = false
    @Published var errorMessage: String?
    @Published var isProcessing: Bool = false
    @Published var progress: Float = 0.0
    
    // Language support
    @Published var selectedLanguage: RecognitionLanguage = .english
    @Published var detectedLanguage: String?
    
    // Translation support
    @Published var translatedText: String = ""
    @Published var isTranslating: Bool = false
    @Published var targetLanguage: TranslationLanguage = .english
    @Published var translationError: String?
    
    // DeepL API configuration
    private var apiKey: String = "" // Will be set via setAPIKey method
    private let freeAPIEndpoint = "https://api-free.deepl.com/v2"
    private let proAPIEndpoint = "https://api.deepl.com/v2"
    private var isProAccount = false
    
    // Enhanced features
    @Published var enhancedImage: Bool = false
    @Published var albums: [Album] = []
    @Published var currentAlbum: Album?
    
    // Check if scanning is available on the device
    var isDocumentScanningAvailable: Bool {
        VNDocumentCameraViewController.isSupported
    }
    
    // Supported languages for OCR
    enum RecognitionLanguage: String, CaseIterable, Identifiable {
        case english = "en-US"
        case italian = "it-IT"
        case french = "fr-FR"
        case portuguese = "pt-BR"
        case german = "de-DE"
        case spanish = "es-ES"
        case chinese = "zh-Hans"
        
        var id: String { self.rawValue }
        
        var displayName: String {
            switch self {
            case .english: return "English"
            case .italian: return "Italian"
            case .french: return "French"
            case .portuguese: return "Portuguese"
            case .german: return "German"
            case .spanish: return "Spanish"
            case .chinese: return "Chinese (Simplified)"
            }
        }
    }
    
    // Supported languages for translation (DeepL)
    enum TranslationLanguage: String, CaseIterable, Identifiable {
        case english = "EN"
        case german = "DE"
        case french = "FR"
        case italian = "IT"
        case spanish = "ES"
        case portuguese = "PT"
        case dutch = "NL"
        case polish = "PL"
        case russian = "RU"
        case japanese = "JA"
        case chinese = "ZH"
        
        var id: String { self.rawValue }
        
        var displayName: String {
            switch self {
            case .english: return "English"
            case .german: return "German"
            case .french: return "French"
            case .italian: return "Italian"
            case .spanish: return "Spanish"
            case .portuguese: return "Portuguese"
            case .dutch: return "Dutch"
            case .polish: return "Polish"
            case .russian: return "Russian"
            case .japanese: return "Japanese"
            case .chinese: return "Chinese"
            }
        }
    }
    
    // Album structure for organizing scans
    struct Album: Identifiable {
        let id = UUID()
        var name: String
        var images: [UIImage]
        var date: Date
    }
    
    // Set the DeepL API key
    func setAPIKey(_ key: String, isPro: Bool = false) {
        self.apiKey = key
        self.isProAccount = isPro
    }
    
    // Get the appropriate API endpoint based on account type
    private var apiEndpoint: String {
        return isProAccount ? proAPIEndpoint : freeAPIEndpoint
    }
    
    // Process the scanned document and extract text
    func processScannedDocument(results: VNDocumentCameraScan) {
        print("processScannedDocument called with \(results.pageCount) pages")
        guard results.pageCount > 0 else {
            self.errorMessage = "No pages scanned"
            print("No pages scanned")
            return
        }
        
        // Clear previous results
        self.scannedImages = []
        self.scannedText = ""
        self.isProcessing = true
        self.progress = 0.0
        
        // Store the first image for preview
        let firstPage = results.imageOfPage(at: 0)
        self.scannedImage = firstPage
        print("First page image set")
        
        // Process all pages
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            print("Starting background processing of pages")
            
            var allText = ""
            var processedPages = 0
            
            // Process each page
            for pageIndex in 0..<results.pageCount {
                print("Processing page \(pageIndex + 1) of \(results.pageCount)")
                let image = results.imageOfPage(at: pageIndex)
                
                // Apply enhancement if enabled
                let processedImage = self.enhancedImage ? self.enhanceImage(image) : image
                self.scannedImages.append(processedImage)
                
                // Recognize text on this page
                print("Recognizing text on page \(pageIndex + 1)")
                let pageText = self.recognizeTextSync(in: processedImage)
                if !pageText.isEmpty {
                    print("Found text on page \(pageIndex + 1): \(pageText.prefix(50))...")
                    if !allText.isEmpty {
                        allText += "\n\n--- Page \(pageIndex + 1) ---\n\n"
                    }
                    allText += pageText
                } else {
                    print("No text found on page \(pageIndex + 1)")
                }
                
                processedPages += 1
                let progress = Float(processedPages) / Float(results.pageCount)
                
                DispatchQueue.main.async {
                    self.progress = progress
                }
            }
            
            // Try to detect the language if text was found
            if !allText.isEmpty {
                print("Detecting language from text")
                self.detectLanguage(from: allText)
            } else {
                print("No text found in document")
            }
            
            // Update UI on main thread
            DispatchQueue.main.async {
                print("Updating UI with processed document")
                self.scannedText = allText
                self.isProcessing = false
                self.progress = 1.0
                
                // Create a new album if we have images
                if !self.scannedImages.isEmpty {
                    print("Creating new album with \(self.scannedImages.count) images")
                    let newAlbum = Album(
                        name: "Scan \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short))",
                        images: self.scannedImages,
                        date: Date()
                    )
                    self.albums.append(newAlbum)
                    self.currentAlbum = newAlbum
                }
            }
        }
    }
    
    // Enhance image with black and white post-processing
    private func enhanceImage(_ image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        
        let ciImage = CIImage(cgImage: cgImage)
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(1.1, forKey: kCIInputContrastKey) // Increase contrast
        
        // Apply black and white filter
        let bwFilter = CIFilter(name: "CIPhotoEffectNoir")
        if let outputImage = filter?.outputImage {
            bwFilter?.setValue(outputImage, forKey: kCIInputImageKey)
        }
        
        // Get the processed image
        guard let outputImage = bwFilter?.outputImage,
              let cgOutputImage = CIContext().createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: cgOutputImage)
    }
    
    // Detect language from text
    private func detectLanguage(from text: String) {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        if let languageCode = recognizer.dominantLanguage?.rawValue {
            DispatchQueue.main.async {
                self.detectedLanguage = Locale.current.localizedString(forIdentifier: languageCode)
            }
        }
    }
    
    // Synchronous text recognition for use in the processing loop
    private func recognizeTextSync(in image: UIImage) -> String {
        print("Starting recognizeTextSync")
        guard let cgImage = image.cgImage else {
            print("Failed to get CGImage from UIImage")
            return ""
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = [selectedLanguage.rawValue]
        
        do {
            print("Performing text recognition request")
            try requestHandler.perform([request])
            
            // Process the recognized text
            if let observations = request.results {
                print("Got \(observations.count) text observations")
                // Since we know the observations are of type VNRecognizedTextObservation,
                // we can directly map them without casting
                #if swift(>=5.0)
                // Suppress the warning about unnecessary casting
                #endif
                let recognizedText = observations.compactMap { observation in
                    // Direct access to the property
                    let textObservation = observation
                    return textObservation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                print("Recognized text length: \(recognizedText.count)")
                return recognizedText
            } else {
                print("No text recognition results")
            }
            
            return ""
        } catch {
            print("Text recognition error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.errorMessage = "Failed to perform text recognition: \(error.localizedDescription)"
            }
            return ""
        }
    }
    
    // Perform OCR using Vision framework
    public func recognizeText(in image: UIImage) {
        guard let cgImage = image.cgImage else {
            self.errorMessage = "Failed to convert image for text recognition"
            return
        }
        
        // Create a request handler
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        // Create a text recognition request
        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Text recognition failed: \(error.localizedDescription)"
                }
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to process text recognition results"
                }
                return
            }
            
            // Process the recognized text
            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            DispatchQueue.main.async {
                self.scannedText = recognizedText
                
                // Try to detect the language
                self.detectLanguage(from: recognizedText)
            }
        }
        
        // Configure the text recognition request
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = [selectedLanguage.rawValue]
        
        // Perform the request
        do {
            try requestHandler.perform([request])
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to perform text recognition: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - DeepL Translation Methods
    
    // Translate the scanned text using DeepL API
    func translateText(completion: ((Bool) -> Void)? = nil) {
        guard !apiKey.isEmpty else {
            self.translationError = "API key not set"
            completion?(false)
            return
        }
        
        guard !scannedText.isEmpty else {
            self.translationError = "No text to translate"
            completion?(false)
            return
        }
        
        self.isTranslating = true
        self.translationError = nil
        
        // Prepare the request
        let urlString = "\(apiEndpoint)/translate"
        guard let url = URL(string: urlString) else {
            self.translationError = "Invalid API URL"
            self.isTranslating = false
            completion?(false)
            return
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("DeepL-Auth-Key \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Prepare request body
        let requestBody: [String: Any] = [
            "text": [scannedText],
            "target_lang": targetLanguage.rawValue,
            "preserve_formatting": true
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            self.translationError = "Failed to prepare request: \(error.localizedDescription)"
            self.isTranslating = false
            completion?(false)
            return
        }
        
        // Perform the request with retry logic
        performRequestWithRetry(request: request, maxRetries: 3) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isTranslating = false
                
                if let error = error {
                    self.translationError = "Translation failed: \(error.localizedDescription)"
                    completion?(false)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.translationError = "Invalid response from server"
                    completion?(false)
                    return
                }
                
                // Check for HTTP errors
                if httpResponse.statusCode != 200 {
                    var errorMessage = "Server error: \(httpResponse.statusCode)"
                    
                    if let data = data, let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = errorResponse["message"] as? String {
                        errorMessage = message
                    }
                    
                    self.translationError = errorMessage
                    completion?(false)
                    return
                }
                
                // Parse the response
                guard let data = data,
                      let responseObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let translations = responseObject["translations"] as? [[String: Any]],
                      let firstTranslation = translations.first,
                      let translatedText = firstTranslation["text"] as? String else {
                    self.translationError = "Failed to parse translation response"
                    completion?(false)
                    return
                }
                
                // Update the translated text
                self.translatedText = translatedText
                
                // If the response includes detected source language, update it
                if let detectedLang = firstTranslation["detected_source_language"] as? String {
                    let langName = Locale.current.localizedString(forIdentifier: detectedLang.lowercased()) ?? detectedLang
                    self.detectedLanguage = langName
                }
                
                completion?(true)
            }
        }
    }
    
    // Translate a document using DeepL API
    func translateDocument(pdfData: Data, completion: @escaping (URL?, Error?) -> Void) {
        guard !apiKey.isEmpty else {
            let error = NSError(domain: "DocumentScannerModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "API key not set"])
            completion(nil, error)
            return
        }
        
        // Prepare the request
        let urlString = "\(apiEndpoint)/document"
        guard let url = URL(string: urlString) else {
            let error = NSError(domain: "DocumentScannerModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid API URL"])
            completion(nil, error)
            return
        }
        
        // Create multipart form data request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("DeepL-Auth-Key \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Generate boundary string
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Create multipart form data
        var body = Data()
        
        // Add target language
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"target_lang\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(targetLanguage.rawValue)\r\n".data(using: .utf8)!)
        
        // Add file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"document.pdf\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/pdf\r\n\r\n".data(using: .utf8)!)
        body.append(pdfData)
        body.append("\r\n".data(using: .utf8)!)
        
        // End boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        // Perform the request to upload document
        performRequestWithRetry(request: request, maxRetries: 3) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                let error = NSError(domain: "DocumentScannerModel", code: statusCode, 
                                   userInfo: [NSLocalizedDescriptionKey: "Server error: \(statusCode)"])
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            // Parse the document ID and key from the response
            guard let data = data,
                  let responseObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let documentId = responseObject["document_id"] as? String,
                  let documentKey = responseObject["document_key"] as? String else {
                let error = NSError(domain: "DocumentScannerModel", code: 3, 
                                   userInfo: [NSLocalizedDescriptionKey: "Failed to parse document upload response"])
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            // Check document status and download when ready
            self.checkDocumentStatus(documentId: documentId, documentKey: documentKey, completion: completion)
        }
    }
    
    // Check document translation status
    private func checkDocumentStatus(documentId: String, documentKey: String, completion: @escaping (URL?, Error?) -> Void) {
        let urlString = "\(apiEndpoint)/document/\(documentId)"
        guard let url = URL(string: urlString) else {
            let error = NSError(domain: "DocumentScannerModel", code: 4, userInfo: [NSLocalizedDescriptionKey: "Invalid status URL"])
            completion(nil, error)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("DeepL-Auth-Key \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyString = "document_key=\(documentKey)"
        request.httpBody = bodyString.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            guard let data = data,
                  let responseObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                let error = NSError(domain: "DocumentScannerModel", code: 5, 
                                   userInfo: [NSLocalizedDescriptionKey: "Failed to parse status response"])
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            // Check document status
            if let status = responseObject["status"] as? String {
                switch status {
                case "queued", "translating":
                    // Document is still being processed, check again after a delay
                    DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
                        self.checkDocumentStatus(documentId: documentId, documentKey: documentKey, completion: completion)
                    }
                    
                case "done":
                    // Document is ready, download it
                    self.downloadTranslatedDocument(documentId: documentId, documentKey: documentKey, completion: completion)
                    
                case "error":
                    let errorMessage = responseObject["error_message"] as? String ?? "Unknown error"
                    let error = NSError(domain: "DocumentScannerModel", code: 6, 
                                       userInfo: [NSLocalizedDescriptionKey: errorMessage])
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                    
                default:
                    let error = NSError(domain: "DocumentScannerModel", code: 7, 
                                       userInfo: [NSLocalizedDescriptionKey: "Unknown status: \(status)"])
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                }
            } else {
                let error = NSError(domain: "DocumentScannerModel", code: 8, 
                                   userInfo: [NSLocalizedDescriptionKey: "Status not found in response"])
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }.resume()
    }
    
    // Download the translated document
    private func downloadTranslatedDocument(documentId: String, documentKey: String, completion: @escaping (URL?, Error?) -> Void) {
        let urlString = "\(apiEndpoint)/document/\(documentId)/result"
        guard let url = URL(string: urlString) else {
            let error = NSError(domain: "DocumentScannerModel", code: 9, userInfo: [NSLocalizedDescriptionKey: "Invalid download URL"])
            completion(nil, error)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("DeepL-Auth-Key \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyString = "document_key=\(documentKey)"
        request.httpBody = bodyString.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                let error = NSError(domain: "DocumentScannerModel", code: statusCode, 
                                   userInfo: [NSLocalizedDescriptionKey: "Download failed with status: \(statusCode)"])
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            guard let data = data, !data.isEmpty else {
                let error = NSError(domain: "DocumentScannerModel", code: 10, 
                                   userInfo: [NSLocalizedDescriptionKey: "Downloaded document is empty"])
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            // Save the document to a temporary file
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "translated_document_\(Date().timeIntervalSince1970).pdf"
            let fileURL = tempDir.appendingPathComponent(fileName)
            
            do {
                try data.write(to: fileURL)
                DispatchQueue.main.async {
                    completion(fileURL, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }.resume()
    }
    
    // Helper method to perform requests with retry logic for error handling
    private func performRequestWithRetry(request: URLRequest, maxRetries: Int, attempt: Int = 0, 
                                        completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            // Check for server errors that should trigger a retry
            if let httpResponse = response as? HTTPURLResponse, 
               (httpResponse.statusCode == 429 || httpResponse.statusCode >= 500), 
               attempt < maxRetries {
                
                // Calculate backoff time with exponential increase
                let backoffTime = pow(2.0, Double(attempt)) * 1.0 // 1, 2, 4, 8... seconds
                
                DispatchQueue.global().asyncAfter(deadline: .now() + backoffTime) {
                    self.performRequestWithRetry(
                        request: request,
                        maxRetries: maxRetries,
                        attempt: attempt + 1,
                        completion: completion
                    )
                }
                return
            }
            
            // No retry needed or max retries reached, return the result
            completion(data, response, error)
        }.resume()
    }
    
    // Create a PDF from scanned images
    func createPDF(from images: [UIImage], includeText: Bool = false) -> Data {
        let pdfDocument = PDFDocument()
        
        for (index, image) in images.enumerated() {
            guard let pdfPage = PDFPage(image: image) else { continue }
            pdfDocument.insert(pdfPage, at: index)
            
            // Add text annotation if requested and text is available
            if includeText && !scannedText.isEmpty && index == 0 {
                let annotation = PDFAnnotation(bounds: pdfPage.bounds(for: .mediaBox), forType: .text, withProperties: nil)
                annotation.contents = scannedText
                annotation.color = .clear // Make it invisible but searchable
                pdfPage.addAnnotation(annotation)
            }
        }
        
        return pdfDocument.dataRepresentation() ?? Data()
    }
    
    // Create a PDF from all scanned images
    func createPDF() -> Data? {
        guard !scannedImages.isEmpty else { return nil }
        return createPDF(from: scannedImages, includeText: true)
    }
    
    // Create a new album
    func createAlbum(name: String) -> Album {
        let newAlbum = Album(name: name, images: [], date: Date())
        albums.append(newAlbum)
        return newAlbum
    }
    
    // Add image to album
    func addImageToAlbum(_ image: UIImage, albumId: UUID) {
        if let index = albums.firstIndex(where: { $0.id == albumId }) {
            var album = albums[index]
            album.images.append(image)
            albums[index] = album
        }
    }
    
    // Remove image from album
    func removeImageFromAlbum(at index: Int, albumId: UUID) {
        if let albumIndex = albums.firstIndex(where: { $0.id == albumId }) {
            var album = albums[albumIndex]
            if index < album.images.count {
                album.images.remove(at: index)
                albums[albumIndex] = album
            }
        }
    }
    
    // Toggle image enhancement
    func toggleEnhancement() {
        enhancedImage.toggle()
        
        // Re-process images if we have any
        if !scannedImages.isEmpty {
            isProcessing = true
            progress = 0.0
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                
                var processedImages: [UIImage] = []
                var processedCount = 0
                
                for image in self.scannedImages {
                    let processedImage = self.enhancedImage ? self.enhanceImage(image) : image
                    processedImages.append(processedImage)
                    
                    processedCount += 1
                    let progress = Float(processedCount) / Float(self.scannedImages.count)
                    
                    DispatchQueue.main.async {
                        self.progress = progress
                    }
                }
                
                DispatchQueue.main.async {
                    self.scannedImages = processedImages
                    if let firstImage = processedImages.first {
                        self.scannedImage = firstImage
                    }
                    self.isProcessing = false
                    self.progress = 1.0
                    
                    // Re-run OCR on the first image
                    if let firstImage = self.scannedImages.first {
                        self.recognizeText(in: firstImage)
                    }
                }
            }
        }
    }
} 

// MARK: - Data Extensions
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
} 

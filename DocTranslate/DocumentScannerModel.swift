import SwiftUI
import VisionKit
import Vision
import PDFKit
import NaturalLanguage

// MARK: - Optimized Document Model
class DocumentScannerModel: ObservableObject {
    // Dependencies
    private let imageCache = OptimizedImageCache.shared
    private let documentProcessor = DocumentProcessor()
    private let apiClient = APIClient()
    private let pdfGenerator = PDFGenerator()
    private let languageService = LanguageDetectionService()
    
    // MARK: - Properties
    
    // Scanner state
    @Published var scannedImage: UIImage?
    @Published var scannedImages: [UIImage] = []
    @Published var isProcessing: Bool = false
    @Published var progress: Float = 0.0
    @Published var shouldShowTitlePrompt: Bool = false
    
    // Image management
    private var currentImageIDs: [String] = []
    private var currentImageID: String?
    
    // Document text and language
    @Published var scannedText: String = ""
    @Published var translatedText: String = ""
    @Published var detectedLanguage: String?
    @Published var targetLanguage: TranslationLanguage = .english
    @Published var savedDocuments: [SavedDocument] = []
    
    // Vision settings
    @Published var enhancedImage: Bool = false
    
    // DeepL API configuration
    private var apiKey: String = "" // Will be set via setAPIKey method
    private let freeAPIEndpoint = "https://api-free.deepl.com/v2"
    private let proAPIEndpoint = "https://api.deepl.com/v2"
    private var isProAccount = false
    
    // Language support
    @Published var selectedLanguage: RecognitionLanguage = .english
    
    // Translation support
    @Published var isTranslating: Bool = false
    @Published var translationError: String?
    @Published var translationProgress: Float = 0.0
    @Published var hasTranslation: Bool = false
    
    // Enhanced features
    @Published var albums: [Album] = []
    @Published var currentAlbum: Album?
    
    // For task cancellation
    private var currentTranslationTask: URLSessionDataTask?
    private var currentOCRTask: DispatchWorkItem?
    
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
        
        var identifier: String {
            return self.rawValue
        }
        
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
        var id = UUID()
        var name: String
        var images: [UIImage]
        var date: Date
    }
    
    // Saved document structure
    struct SavedDocument: Identifiable {
        var id = UUID()
        let image: UIImage
        let text: String
        let date: Date
        let detectedLanguage: String?
        var title: String
        
        var thumbnailText: String {
            if text.isEmpty {
                return "[No text detected]"
            } else {
                return text.prefix(100) + (text.count > 100 ? "..." : "")
            }
        }
    }
    
    // MARK: - API Response Models
    
    struct LanguageDetectionResponse: Decodable {
        struct Detection: Decodable {
            let language: String
            let confidence: Float
        }
        
        let detections: [Detection]
    }
    
    // Set the DeepL API key
    func setAPIKey(_ key: String, isPro: Bool = false) {
        guard !key.isEmpty else {
            try? KeychainManager.shared.delete(key: "deepLApiKey")
            self.apiKey = ""
            self.isProAccount = false
            return
        }
        
        // Validate API key format
        guard KeychainManager.shared.isValidAPIKey(key) else {
            // Invalid format - don't save
            self.apiKey = ""
            self.isProAccount = false
            NotificationCenter.default.post(name: .apiKeyValidationFailed, object: nil)
            return
        }
        
        // Save to keychain
        do {
            try KeychainManager.shared.save(key: "deepLApiKey", value: key)
            self.apiKey = key
            self.isProAccount = isPro
            
            // Post notification that API key was successfully set
            NotificationCenter.default.post(name: .apiKeyChanged, object: nil)
        } catch {
            print("Failed to save API key to keychain: \(error)")
            self.apiKey = ""
            self.isProAccount = false
        }
    }
    
    // Get the API key from keychain
    func loadApiKey() {
        if let key = KeychainManager.shared.get(key: "deepLApiKey") {
            self.apiKey = key
            // Determine if it's a pro account by checking for ":fx" suffix
            self.isProAccount = !key.hasSuffix(":fx")
        }
    }
    
    // Get the appropriate API endpoint based on account type
    private var apiEndpoint: String {
        return isProAccount ? proAPIEndpoint : freeAPIEndpoint
    }
    
    // Document storage
    private struct DocumentStorage: Codable {
        var documents: [StoredDocument]
        var albums: [StoredAlbum]
    }
    
    private struct StoredDocument: Codable {
        var id: UUID
        var title: String
        var text: String
        var imageID: String
        var detectedLanguage: String?
        var date: Date
    }
    
    private struct StoredAlbum: Codable {
        var id: UUID
        var name: String
        var imageIDs: [String]
        var date: Date
    }
    
    // MARK: - Initialization and Lifecycle
    
    init() {
        // Set up handlers for component events
        documentProcessor.onStateChange = { [weak self] state in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch state {
                case .idle:
                    self.isProcessing = false
                case .processing:
                    self.isProcessing = true
                case .completed:
                    self.isProcessing = false
                    // Handle completion
                case .failed(let error):
                    self.isProcessing = false
                    print("Processing failed: \(error.localizedDescription)")
                    NotificationCenter.default.post(
                        name: .ocrFailed, 
                        object: nil, 
                        userInfo: ["error": error.localizedDescription]
                    )
                }
            }
        }
        
        documentProcessor.onProgressUpdate = { [weak self] progress in
            DispatchQueue.main.async {
                self?.progress = progress
            }
        }
        
        // Load settings
        if let languageString = UserDefaults.standard.string(forKey: "targetLanguage"),
           let language = TranslationLanguage(rawValue: languageString) {
            targetLanguage = language
        }
        
        // Load saved documents
        loadSavedDocuments()
        
        // Load API key from keychain
        loadApiKey()
        
        // Set up memory warning notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleMemoryWarning() {
        // Clear any non-essential memory
        imageCache.handleMemoryWarning()
        
        // Keep only the current image in memory and clear other references
        if let currentID = currentImageID {
            imageCache.getImage(withID: currentID) { [weak self] image in
                self?.scannedImage = image
            }
        }
        
        // Clear the array but keep IDs
        scannedImages = []
    }
    
    // MARK: - Document Saving and Loading
    
    private func saveScannerState() {
        var storedDocuments: [StoredDocument] = []
        
        // Convert SavedDocument objects to StoredDocument
        for document in savedDocuments {
            let imageID = storeImageIfNeeded(document.image)
            
            let storedDoc = StoredDocument(
                id: document.id,
                title: document.title,
                text: document.text,
                imageID: imageID,
                detectedLanguage: document.detectedLanguage,
                date: document.date
            )
            
            storedDocuments.append(storedDoc)
        }
        
        // Convert albums
        var storedAlbums: [StoredAlbum] = []
        for album in albums {
            var imageIDs: [String] = []
            
            for image in album.images {
                let imageID = storeImageIfNeeded(image)
                imageIDs.append(imageID)
            }
            
            let storedAlbum = StoredAlbum(
                id: album.id,
                name: album.name,
                imageIDs: imageIDs,
                date: album.date
            )
            
            storedAlbums.append(storedAlbum)
        }
        
        // Create storage object
        let storage = DocumentStorage(
            documents: storedDocuments,
            albums: storedAlbums
        )
        
        // Save to disk
        saveStorageToDisk(storage)
    }
    
    private func storeImageIfNeeded(_ image: UIImage) -> String {
        let imageID = UUID().uuidString
        let entry = OptimizedImageCache.CacheEntry(image: image)
        imageCache.storeImage(entry, withID: imageID)
        return imageID
    }
    
    private func saveStorageToDisk(_ storage: DocumentStorage) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(storage) {
            let fileURL = getDocumentStorageURL()
            try? data.write(to: fileURL)
        }
    }
    
    private func loadSavedDocuments() {
        let fileURL = getDocumentStorageURL()
        guard let data = try? Data(contentsOf: fileURL) else { return }
        
        let decoder = JSONDecoder()
        guard let storage = try? decoder.decode(DocumentStorage.self, from: data) else { return }
        
        // Load documents
        var loadedDocuments: [SavedDocument] = []
        let group = DispatchGroup()
        
        for storedDoc in storage.documents {
            group.enter()
            imageCache.getImage(withID: storedDoc.imageID) { image in
                if let image = image {
                    let document = SavedDocument(
                        id: storedDoc.id,
                        image: image,
                        text: storedDoc.text,
                        date: storedDoc.date,
                        detectedLanguage: storedDoc.detectedLanguage,
                        title: storedDoc.title
                    )
                    loadedDocuments.append(document)
                }
                group.leave()
            }
        }
        
        // Load albums
        var loadedAlbums: [Album] = []
        for storedAlbum in storage.albums {
            group.enter()
            var albumImages: [UIImage] = []
            let albumGroup = DispatchGroup()
            
            for imageID in storedAlbum.imageIDs {
                albumGroup.enter()
                imageCache.getImage(withID: imageID) { image in
                    if let image = image {
                        albumImages.append(image)
                    }
                    albumGroup.leave()
                }
            }
            
            albumGroup.notify(queue: .global()) {
                let album = Album(
                    id: storedAlbum.id,
                    name: storedAlbum.name,
                    images: albumImages,
                    date: storedAlbum.date
                )
                loadedAlbums.append(album)
                group.leave()
            }
        }
        
        // Update published properties on main thread
        group.notify(queue: .main) {
            self.savedDocuments = loadedDocuments
            self.albums = loadedAlbums
        }
    }
    
    private func getDocumentStorageURL() -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent("documentStorage.json")
    }
    
    // MARK: - Memory Management
    
    // Reset all data and clear memory
    func resetAll() {
        // Clear all in-memory data
        scannedImage = nil
        scannedImages = []
        currentImageIDs = []
        currentImageID = nil
        scannedText = ""
        translatedText = ""
        detectedLanguage = nil
        isProcessing = false
        progress = 0.0
        savedDocuments = []
        albums = []
        isTranslating = false
        translationError = nil
        
        // Clear image storage
        imageCache.clearAllImages()
        
        // Delete saved document file
        let fileURL = getDocumentStorageURL()
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    // Add a scanned image with memory optimization
    func addScannedImage(_ image: UIImage) {
        let imageID = UUID().uuidString
        currentImageIDs.append(imageID)
        currentImageID = imageID
        
        // Keep scannedImage reference for immediate use
        scannedImage = image
        
        // Update scannedImages array (only if needed for display)
        // This minimizes keeping multiple copies in memory
        if scannedImages.isEmpty {
            scannedImages = [image]
        } else {
            // Append to array, but limit in-memory copies
            if scannedImages.count < 5 {
                scannedImages.append(image)
            } else {
                // Only keep reference IDs for images beyond the first 5
                // They'll be loaded from disk when needed
            }
        }
        
        // Store image in background
        let entry = OptimizedImageCache.CacheEntry(image: image)
        imageCache.storeImage(entry, withID: imageID)
        
        // Process the image in background
        processImage(image)
    }
    
    // Clear unnecessary memory when not needed
    func cleanupMemory() {
        // Keep current image but remove others from memory
        if let currentID = currentImageID {
            imageCache.getImage(withID: currentID) { [weak self] image in
                if let image = image {
                    self?.scannedImage = image
                }
                self?.scannedImages = []
            }
        }
    }
    
    // MARK: - Image Processing
    
    private func processImage(_ image: UIImage) {
        // Continue with existing image processing logic here...
        // ... existing code ...
    }
    
    // Create a PDF from stored image IDs
    func createOptimizedPDF(from imageIDs: [String], includeText: Bool = false) -> Data {
        // We'll create a group to synchronously get all images
        let group = DispatchGroup()
        var images: [UIImage] = []
        
        for imageID in imageIDs {
            group.enter()
            imageCache.getImage(withID: imageID) { image in
                if let image = image {
                    images.append(image)
                }
                group.leave()
            }
        }
        
        // Wait for all images to be retrieved
        group.wait()
        
        let result = group.wait(timeout: .now() + 5.0)
        if result == .timedOut {
            print("Warning: Timed out waiting for images to load for PDF")
        }
        
        // Use the PDF generator to create the document
        var pdfData = Data()
        let semaphore = DispatchSemaphore(value: 0)
        
        pdfGenerator.createDocumentPDF(
            title: "Document Scan",
            image: images.first ?? UIImage(),
            originalText: includeText ? scannedText : nil,
            translatedText: includeText && !translatedText.isEmpty ? translatedText : nil,
            sourceLanguage: detectedLanguage,
            targetLanguage: targetLanguage.displayName
        ) { data in
            if let data = data {
                pdfData = data
            }
            semaphore.signal()
        }
        
        // Wait for PDF generation to complete
        _ = semaphore.wait(timeout: .now() + 10.0)
        
        return pdfData
    }
    
    // Create a PDF from all currently scanned images
    func createPDF(from images: [UIImage], includeText: Bool = false) -> Data {
        // For backward compatibility
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
    
    // MARK: - Document Saving with Custom Title
    
    func saveDocumentWithTitle(_ title: String) {
        let documentTitle = title.isEmpty ? generateDocumentTitle(from: scannedText) : title
        
        if let image = scannedImage {
            // Create a new document with the provided or generated title
            let newDocument = SavedDocument(
                id: UUID(),
                image: image,
                text: scannedText,
                date: Date(),
                detectedLanguage: detectedLanguage,
                title: documentTitle
            )
            
            // Add to saved documents and save to user defaults
            savedDocuments.append(newDocument)
            saveToUserDefaults()
            
            // Reset prompt flag
            shouldShowTitlePrompt = false
        }
    }
    
    // Save documents to UserDefaults
    private func saveToUserDefaults() {
        let _ = JSONEncoder()
        
        // Convert UIImages to Data and prepare for storage
        let documentsData = savedDocuments.map { document -> [String: Any] in
            let imageData = document.image.jpegData(compressionQuality: 0.7)
            
            return [
                "id": document.id.uuidString,
                "imageData": imageData ?? Data(),
                "text": document.text,
                "date": document.date,
                "detectedLanguage": document.detectedLanguage ?? "",
                "title": document.title
            ]
        }
        
        UserDefaults.standard.set(documentsData, forKey: "savedDocuments")
    }
    
    // Remove a saved document
    func removeSavedDocument(at indexSet: IndexSet) {
        savedDocuments.remove(atOffsets: indexSet)
        saveToUserDefaults()
    }
    
    // Load a saved document as the current document
    func loadSavedDocument(_ document: SavedDocument) {
        scannedImage = document.image
        scannedImages = [document.image]
        scannedText = document.text
        detectedLanguage = document.detectedLanguage
        translatedText = ""
    }
    
    // Function to recognize text in a specific image
    func recognizeText(in image: UIImage) {
        scannedImage = image
        let _ = documentProcessor.processImage(image) { [weak self] text in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let text = text {
                    self.scannedText = text
                    self.detectLanguage(text: text)
                }
            }
        }
    }
    
    // MARK: - Document Processing
    
    // Process the scanned document and extract text
    func processScannedDocument() {
        guard let image = scannedImage else { return }
        
        isProcessing = true
        self.progress = 0.2
        
        let requestHandler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
        let textRequest = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Text recognition error: \(error)")
                self.scannedText = "Error: Could not recognize text."
                DispatchQueue.main.async {
                    self.isProcessing = false
                }
                return
            }
            
            self.progress = 0.6
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                self.scannedText = "Error: Invalid observation format."
                self.isProcessing = false
                return
            }
            
            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            // Store recognized text
            self.scannedText = recognizedText
            self.progress = 0.8
            
            if !recognizedText.isEmpty {
                // Detect language
                self.detectLanguage(text: recognizedText)
            } else {
                self.detectedLanguage = nil
                self.progress = 1.0
                // Trigger title prompt instead of automatically saving
                self.shouldShowTitlePrompt = true
                self.isProcessing = false
            }
        }
        
        // Set recognition level to accurate
        textRequest.recognitionLevel = VNRequestTextRecognitionLevel.accurate
        textRequest.usesLanguageCorrection = true
        
        // Try to recognize text
        do {
            try requestHandler.perform([textRequest])
        } catch {
            print("Error performing vision request: \(error)")
            self.scannedText = "Error: Could not process the document."
            self.isProcessing = false
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
    private func detectLanguage(text: String) {
        let apiUrl = isProAccount ? "\(proAPIEndpoint)/detect" : "\(freeAPIEndpoint)/detect"
        
        guard !text.isEmpty else {
            print("No text to detect language from")
            detectedLanguage = nil
            isProcessing = false
            return
        }
        
        guard let url = URL(string: apiUrl) else {
            print("Invalid API URL")
            detectedLanguage = nil
            isProcessing = false
            return
        }
        
        // Setup HTTP request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("DeepL-Auth-Key \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Prepare request body
        let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let postData = "text=\(encodedText)"
        request.httpBody = postData.data(using: .utf8)
        
        // Make API call
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    print("Language detection error: \(error)")
                    self.detectedLanguage = nil
                    self.progress = 1.0
                    self.shouldShowTitlePrompt = true
                    self.isProcessing = false
                    return
                }
                
                guard let data = data else {
                    print("No data received from language detection")
                    self.detectedLanguage = nil
                    self.progress = 1.0
                    self.shouldShowTitlePrompt = true
                    self.isProcessing = false
                    return
                }
                
                // Try to parse the response
                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(LanguageDetectionResponse.self, from: data)
                    if let firstResult = response.detections.first {
                        self.detectedLanguage = firstResult.language
                    } else {
                        self.detectedLanguage = nil
                    }
                } catch {
                    print("Error parsing language detection response: \(error)")
                    print("Response data: \(String(data: data, encoding: .utf8) ?? "Could not convert data to string")")
                    self.detectedLanguage = nil
                }
                
                // Finish processing
                self.progress = 1.0
                // Trigger title prompt instead of automatically saving
                self.shouldShowTitlePrompt = true
                self.isProcessing = false
            }
        }.resume()
    }
    
    // Synchronously recognize text in an image
    private func recognizeTextSync(in image: UIImage) -> String {
        print("Starting recognizeTextSync")
        guard let cgImage = image.cgImage else {
            print("Failed to convert image for text recognition")
            return ""
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = VNRequestTextRecognitionLevel.accurate
        request.usesLanguageCorrection = true
        
        // Process the request
        do {
            try requestHandler.perform([request])
            
            guard let observations = request.results else {
                print("Failed to process text recognition results")
                return ""
            }
            
            // Combine all recognized text
            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            return recognizedText
        } catch {
            print("Text recognition failed: \(error.localizedDescription)")
            return ""
        }
    }
    
    // MARK: - Custom Text Recognition

    // Recognize text with custom language selection
    func recognizeText() {
        guard let image = scannedImage else {
            NotificationCenter.default.post(
                name: .ocrFailed, 
                object: nil, 
                userInfo: ["error": "No image available for processing"]
            )
            return
        }
        
        // Cancel any previous OCR task
        cancelOCR()
        
        isProcessing = true
        progress = 0.1
        
        // Process the image using DocumentProcessor
        let _ = documentProcessor.processImage(image, recognitionLanguage: selectedLanguage.rawValue)
            
        // Listen for text recognition from document processor
        documentProcessor.onStateChange = { [weak self] state in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch state {
                case .idle:
                    self.isProcessing = false
                    
                case .processing:
                    self.isProcessing = true
                    
                case .completed:
                    self.isProcessing = false
                    
                    // Post notification for successful OCR
                    NotificationCenter.default.post(name: .ocrCompleted, object: nil)
                    
                case .failed(let error):
                    self.isProcessing = false
                    
                    // Post notification for OCR failure
                    NotificationCenter.default.post(
                        name: .ocrFailed, 
                        object: nil, 
                        userInfo: ["error": error.localizedDescription]
                    )
                }
            }
        }
        
        // Listen for text content
        documentProcessor.onTextRecognized = { [weak self] text in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.scannedText = text ?? ""
                
                // Detect language if text is found
                if let text = text, !text.isEmpty {
                    self.detectLanguageWithService(text: text)
                } else {
                    self.detectedLanguage = nil
                }
            }
        }
    }
    
    // Cancel ongoing OCR task
    func cancelOCR() {
        documentProcessor.cancelCurrentTask()
        isProcessing = false
        progress = 0
    }
    
    // Use the language detection service instead of direct API calls
    private func detectLanguageWithService(text: String) {
        guard !text.isEmpty else {
            print("No text to detect language from")
            detectedLanguage = nil
            return
        }
        
        languageService.detectLanguage(text: text, apiKey: apiKey) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let detectionResult):
                    self.detectedLanguage = detectionResult.languageCode
                    self.shouldShowTitlePrompt = true
                    
                case .failure(let error):
                    print("Language detection error: \(error)")
                    self.detectedLanguage = nil
                    self.shouldShowTitlePrompt = true
                }
            }
        }
    }
    
    // MARK: - DeepL Translation Methods
    
    // Translate the scanned text using DeepL API
    func translateText() {
        // Cancel any previous translation task
        cancelTranslation()
        
        guard !apiKey.isEmpty else {
            NotificationCenter.default.post(name: .apiKeyValidationFailed, object: nil, userInfo: ["error": "API key not set"])
            return
        }
        
        // Check if scannedText is empty
        if scannedText.isEmpty {
            NotificationCenter.default.post(name: .translationFailed, object: nil, userInfo: ["error": "No text to translate"])
            return
        }
        
        isTranslating = true
        translationProgress = 0.1
        
        let urlString = apiKey.hasSuffix(":fx") 
            ? "\(freeAPIEndpoint)/translate"
            : "\(proAPIEndpoint)/translate"
        
        // Prepare request parameters
        let encodedText = scannedText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let requestBody = "text=\(encodedText)&target_lang=\(targetLanguage.identifier)".data(using: .utf8)
        
        let headers = [
            "Content-Type": "application/x-www-form-urlencoded",
            "Authorization": "DeepL-Auth-Key \(apiKey)"
        ]
        
        // Define the response structure for decoding
        struct TranslationResponse: Decodable {
            struct Translation: Decodable {
                let text: String
                let detected_source_language: String
            }
            let translations: [Translation]
        }
        
        // Make the API request through our APIClient
        apiClient.request(
            endpoint: urlString,
            method: "POST",
            headers: headers,
            body: requestBody,
            responseType: TranslationResponse.self,
            requestId: "translation",
            progress: { [weak self] progress in
                DispatchQueue.main.async {
                    self?.translationProgress = progress
                }
            }
        ) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isTranslating = false
                
                switch result {
                case .success(let response):
                    if let firstTranslation = response.translations.first {
                        // Save detected language
                        self.detectedLanguage = firstTranslation.detected_source_language
                        
                        // Set translated text
                        self.translatedText = firstTranslation.text
                        self.hasTranslation = true
                        
                        // Notify about successful translation
                        NotificationCenter.default.post(name: .translationCompleted, object: nil)
                    } else {
                        // No translations in response
                        NotificationCenter.default.post(
                            name: .translationFailed, 
                            object: nil, 
                            userInfo: ["error": "No translation returned from server"]
                        )
                    }
                    
                case .failure(let error):
                    // Handle specific API errors
                    var errorMessage = "Translation failed"
                    
                    switch error {
                    case .invalidURL:
                        errorMessage = "Invalid API URL"
                    case .requestPreparationFailed:
                        errorMessage = "Failed to prepare translation request"
                    case .networkError(let underlyingError):
                        errorMessage = "Network error: \(underlyingError.localizedDescription)"
                    case .serverError(let code, let message):
                        errorMessage = message ?? "Server error (status \(code))"
                    case .invalidResponse:
                        errorMessage = "Invalid response from server"
                    case .decodingError(let decodingError):
                        errorMessage = "Failed to parse response: \(decodingError.localizedDescription)"
                    }
                    
                    // Post failure notification
                    NotificationCenter.default.post(
                        name: .translationFailed, 
                        object: nil, 
                        userInfo: ["error": errorMessage]
                    )
                }
                
                // Reset progress after a slight delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.translationProgress = 0
                }
            }
        }
    }
    
    func cancelTranslation() {
        apiClient.cancelRequest(withId: "translation")
        isTranslating = false
        translationProgress = 0
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
        
        // Generate boundary string
        let boundary = UUID().uuidString
        
        // Create multipart form data
        var body = Data()
        
        // Add target language
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"target_lang\"\r\n\r\n")
        body.append("\(targetLanguage.rawValue)\r\n")
        
        // Add file data
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"document.pdf\"\r\n")
        body.append("Content-Type: application/pdf\r\n\r\n")
        body.append(pdfData)
        body.append("\r\n")
        
        // End boundary
        body.append("--\(boundary)--\r\n")
        
        let headers = [
            "Content-Type": "multipart/form-data; boundary=\(boundary)",
            "Authorization": "DeepL-Auth-Key \(apiKey)"
        ]
        
        // Response type
        struct DocumentUploadResponse: Decodable {
            let document_id: String
            let document_key: String
        }
        
        // Make the upload request
        apiClient.request(
            endpoint: urlString,
            method: "POST",
            headers: headers,
            body: body,
            responseType: DocumentUploadResponse.self,
            requestId: "documentUpload"
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                // Check document status
                self.checkDocumentStatus(
                    documentId: response.document_id,
                    documentKey: response.document_key,
                    completion: completion
                )
            
            case .failure(let error):
                var nsError: NSError
                
                switch error {
                case .serverError(let code, let message):
                    nsError = NSError(
                        domain: "DocumentScannerModel",
                        code: code,
                        userInfo: [NSLocalizedDescriptionKey: message ?? "Server error: \(code)"]
                    )
                    
                case .networkError(let underlyingError):
                    nsError = underlyingError as NSError
                    
                case .invalidURL:
                    nsError = NSError(
                        domain: "DocumentScannerModel",
                        code: 2,
                        userInfo: [NSLocalizedDescriptionKey: "Invalid API URL"]
                    )
                    
                case .requestPreparationFailed:
                    nsError = NSError(
                        domain: "DocumentScannerModel",
                        code: 3,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to prepare document upload request"]
                    )
                    
                case .invalidResponse, .decodingError:
                    nsError = NSError(
                        domain: "DocumentScannerModel",
                        code: 4,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to parse document upload response"]
                    )
                }
                
                completion(nil, nsError)
            }
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
                    if processedImages.first != nil {
                        self.scannedImage = processedImages.first
                    }
                    self.isProcessing = false
                    self.progress = 1.0
                    
                    // Re-run OCR on the first image
                    if self.scannedImages.first != nil {
                        self.recognizeText()
                    }
                }
            }
        }
    }
    
    // Add current document to saved documents
    func saveCurrentDocument() {
        guard let image = scannedImage else { return }
        
        // Generate a title from the first line of text or use a default title
        let title = generateDocumentTitle(from: scannedText)
        
        let newDocument = SavedDocument(
            id: UUID(),
            image: image,
            text: scannedText,
            date: Date(),
            detectedLanguage: detectedLanguage,
            title: title
        )
        
        savedDocuments.append(newDocument)
    }
    
    // Generate a document title from text or using a timestamp
    func generateDocumentTitle(from text: String) -> String {
        if text.isEmpty {
            // If no text is detected, use the current date/time
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            return "Scan \(dateFormatter.string(from: Date()))"
        } else {
            // Use the first line or first few words of the text
            let firstLine = text.components(separatedBy: .newlines).first ?? text
            
            if firstLine.count <= 30 {
                return firstLine
            } else {
                // Take up to 30 characters
                let words = firstLine.components(separatedBy: .whitespaces)
                var title = ""
                for word in words {
                    if (title + word).count <= 30 {
                        title += (title.isEmpty ? "" : " ") + word
                    } else {
                        break
                    }
                }
                return title + "..."
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

// MARK: - Notification Names
extension Notification.Name {
    static let apiKeyChanged = Notification.Name("apiKeyChanged")
    static let apiKeyValidationFailed = Notification.Name("apiKeyValidationFailed")
    static let translationCompleted = Notification.Name("translationCompleted")
    static let translationFailed = Notification.Name("translationFailed")
    static let ocrCompleted = Notification.Name("ocrCompleted")
    static let ocrFailed = Notification.Name("ocrFailed")
}


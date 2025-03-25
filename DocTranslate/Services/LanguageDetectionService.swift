import Foundation
import NaturalLanguage

class LanguageDetectionService {
    enum DetectionMethod {
        case local
        case api
    }
    
    enum DetectionError: Error {
        case emptyText
        case apiError(String)
        case invalidResponse
        case networkError(Error)
    }
    
    struct DetectionResult {
        let languageCode: String
        let confidence: Float
        let displayName: String?
    }
    
    private let apiClient = APIClient()
    private var currentTaskId: String?
    
    // Detect language with fallback
    func detectLanguage(
        text: String,
        apiKey: String?,
        preferredMethod: DetectionMethod = .local,
        completion: @escaping (Result<DetectionResult, DetectionError>) -> Void
    ) {
        // Cancel any existing task
        if let taskId = currentTaskId {
            apiClient.cancelRequest(withId: taskId)
        }
        
        // Guard against empty text
        guard !text.isEmpty else {
            completion(.failure(.emptyText))
            return
        }
        
        // Try local detection first if preferred
        if preferredMethod == .local {
            if let result = detectLanguageLocally(text: text) {
                completion(.success(result))
                return
            }
        }
        
        // Fall back to API if we have a key
        if let apiKey = apiKey, !apiKey.isEmpty {
            detectLanguageWithAPI(text: text, apiKey: apiKey, completion: completion)
        } else {
            // Try local as fallback if API was preferred but unavailable
            if preferredMethod == .api, let result = detectLanguageLocally(text: text) {
                completion(.success(result))
            } else {
                completion(.failure(.apiError("API key not provided and local detection failed")))
            }
        }
    }
    
    // Use on-device detection
    private func detectLanguageLocally(text: String) -> DetectionResult? {
        // Use Natural Language framework for on-device detection
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        guard let languageCode = recognizer.dominantLanguage?.rawValue else {
            return nil
        }
        
        let confidence = recognizer.languageHypotheses(withMaximum: 1)[recognizer.dominantLanguage!] ?? 0
        
        // Get localized language name
        let locale = Locale.current
        let displayName = locale.localizedString(forIdentifier: languageCode)
        
        return DetectionResult(
            languageCode: languageCode,
            confidence: Float(confidence),
            displayName: displayName
        )
    }
    
    // Use DeepL API for detection
    private func detectLanguageWithAPI(
        text: String,
        apiKey: String,
        completion: @escaping (Result<DetectionResult, DetectionError>) -> Void
    ) {
        // Determine endpoint based on API key format
        let baseUrl = apiKey.hasSuffix(":fx") 
            ? "https://api-free.deepl.com/v2/detect"
            : "https://api.deepl.com/v2/detect"
        
        // Prepare request parameters
        let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let requestBody = "text=\(encodedText)".data(using: .utf8)
        
        let headers = [
            "Content-Type": "application/x-www-form-urlencoded",
            "Authorization": "DeepL-Auth-Key \(apiKey)"
        ]
        
        // Generate task ID for cancellation
        let taskId = UUID().uuidString
        currentTaskId = taskId
        
        // Make API request
        struct DeepLDetection: Decodable {
            let language: String
            let confidence: Float
        }
        
        struct DeepLResponse: Decodable {
            let detections: [DeepLDetection]
        }
        
        apiClient.request(
            endpoint: baseUrl,
            method: "POST",
            headers: headers,
            body: requestBody,
            responseType: DeepLResponse.self,
            requestId: taskId
        ) { result in
            switch result {
            case .success(let response):
                guard let detection = response.detections.first else {
                    completion(.failure(.invalidResponse))
                    return
                }
                
                // Get localized language name
                let locale = Locale.current
                let displayName = locale.localizedString(forIdentifier: detection.language)
                
                let result = DetectionResult(
                    languageCode: detection.language,
                    confidence: detection.confidence,
                    displayName: displayName
                )
                
                completion(.success(result))
                
            case .failure(let error):
                switch error {
                case .networkError(let underlyingError):
                    completion(.failure(.networkError(underlyingError)))
                case .serverError(_, let message):
                    completion(.failure(.apiError(message ?? "Unknown server error")))
                default:
                    completion(.failure(.apiError(error.localizedDescription)))
                }
            }
        }
    }
    
    func cancelDetection() {
        if let taskId = currentTaskId {
            apiClient.cancelRequest(withId: taskId)
            currentTaskId = nil
        }
    }
} 
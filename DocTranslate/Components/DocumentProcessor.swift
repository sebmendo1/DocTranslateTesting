import Vision
import UIKit

class DocumentProcessor {
    enum ProcessingState {
        case idle, processing, completed, failed(Error)
    }
    
    // Processing task management
    private var currentTask: DispatchWorkItem?
    
    // Observable state
    var onStateChange: ((ProcessingState) -> Void)?
    var onProgressUpdate: ((Float) -> Void)?
    var onTextRecognized: ((String?) -> Void)?
    
    // Process an image with cancellation support
    func processImage(_ image: UIImage, recognitionLanguage: String? = nil, completion: ((String?) -> Void)? = nil) -> String? {
        // Cancel any existing task
        cancelCurrentTask()
        
        // Set the completion handler if provided
        if let completion = completion {
            onTextRecognized = completion
        }
        
        // Create new processing task
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            self.onStateChange?(.processing)
            self.onProgressUpdate?(0.2)
            
            // Image processing logic moved from DocumentScannerModel...
            guard let cgImage = image.cgImage else {
                self.onStateChange?(.failed(NSError(domain: "DocumentProcessor", code: 100, userInfo: [NSLocalizedDescriptionKey: "Invalid image format"])))
                return
            }
            
            // Process with Vision framework
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            // Create the text recognition request
            let textRequest = VNRecognizeTextRequest { [weak self] request, error in
                guard let self = self else { return }
                
                // Check for errors
                if let error = error {
                    self.onStateChange?(.failed(error))
                    return
                }
                
                // Process the recognized text observations
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    self.onStateChange?(.failed(NSError(domain: "DocumentProcessor", code: 101, userInfo: [NSLocalizedDescriptionKey: "Invalid observation format"])))
                    return
                }
                
                // Extract text from observations
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                // Update progress
                self.onProgressUpdate?(0.8)
                
                // Notify through callback
                self.onTextRecognized?(recognizedText)
                
                // Report completion
                self.onProgressUpdate?(1.0)
                self.onStateChange?(.completed)
            }
            
            // Configure text recognition request
            textRequest.recognitionLevel = .accurate
            textRequest.usesLanguageCorrection = true
            
            // Set recognition language if specified
            if let language = recognitionLanguage {
                textRequest.recognitionLanguages = [language]
            }
            
            // Execute the request
            do {
                try requestHandler.perform([textRequest])
            } catch {
                self.onStateChange?(.failed(error))
            }
        }
        
        currentTask = workItem
        DispatchQueue.global(qos: .userInitiated).async(execute: workItem)
        
        return nil // Return immediately, results will come through callbacks
    }
    
    func cancelCurrentTask() {
        currentTask?.cancel()
        currentTask = nil
        onStateChange?(.idle)
        onProgressUpdate?(0)
    }
} 
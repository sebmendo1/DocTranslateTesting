import Foundation

class APIClient {
    enum APIError: Error {
        case invalidURL
        case requestPreparationFailed
        case networkError(Error)
        case serverError(Int, String?)
        case invalidResponse
        case decodingError(Error)
    }
    
    // Configuration
    private let timeoutInterval: TimeInterval = 30.0
    private let maxRetries = 3
    
    // Active requests for cancellation
    private var activeTasks: [String: URLSessionTask] = [:]
    private let taskQueue = DispatchQueue(label: "com.document-translator.apiTasks")
    
    // Make API request with automatic retries
    func request<T: Decodable>(
        endpoint: String,
        method: String = "POST",
        headers: [String: String],
        body: Data?,
        responseType: T.Type,
        requestId: String = UUID().uuidString,
        progress: ((Float) -> Void)? = nil,
        completion: @escaping (Result<T, APIError>) -> Void
    ) {
        // Cancel existing request with same ID
        cancelRequest(withId: requestId)
        
        // Create and configure request
        guard let url = URL(string: endpoint) else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = timeoutInterval
        
        // Add headers
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        // Add body
        request.httpBody = body
        
        progress?(0.1)
        
        // Create and start task
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            // Handle common errors
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }
            
            progress?(0.7)
            
            // Handle HTTP errors
            if !(200...299).contains(httpResponse.statusCode) {
                var errorMessage: String?
                if let data = data {
                    errorMessage = String(data: data, encoding: .utf8)
                }
                
                // Check if should retry
                if self.shouldRetryRequest(statusCode: httpResponse.statusCode) {
                    self.retryRequest(
                        endpoint: endpoint,
                        method: method,
                        headers: headers,
                        body: body,
                        responseType: responseType,
                        requestId: requestId,
                        retryCount: 1,
                        progress: progress,
                        completion: completion
                    )
                    return
                }
                
                completion(.failure(.serverError(httpResponse.statusCode, errorMessage)))
                return
            }
            
            progress?(0.9)
            
            // Parse response
            guard let data = data else {
                completion(.failure(.invalidResponse))
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                progress?(1.0)
                completion(.success(decodedResponse))
            } catch {
                completion(.failure(.decodingError(error)))
            }
            
            // Remove task from active tasks
            self.removeTask(withId: requestId)
        }
        
        // Store for cancellation
        storeTask(task, withId: requestId)
        
        // Start request
        task.resume()
    }
    
    // Retry logic
    private func retryRequest<T: Decodable>(
        endpoint: String,
        method: String,
        headers: [String: String],
        body: Data?,
        responseType: T.Type,
        requestId: String,
        retryCount: Int,
        progress: ((Float) -> Void)?,
        completion: @escaping (Result<T, APIError>) -> Void
    ) {
        // Exponential backoff
        let delay = pow(2.0, Double(retryCount)) * 0.5
        
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            
            if retryCount >= self.maxRetries {
                completion(.failure(.serverError(0, "Max retries exceeded")))
                return
            }
            
            // Recursive retry with incremented counter
            self.request(
                endpoint: endpoint,
                method: method,
                headers: headers,
                body: body,
                responseType: responseType,
                requestId: requestId,
                progress: progress,
                completion: completion
            )
        }
    }
    
    // Determine if request should be retried
    private func shouldRetryRequest(statusCode: Int) -> Bool {
        return statusCode == 429 || (500...599).contains(statusCode)
    }
    
    // Task management for cancellation
    private func storeTask(_ task: URLSessionTask, withId id: String) {
        taskQueue.async { [weak self] in
            self?.activeTasks[id] = task
        }
    }
    
    private func removeTask(withId id: String) {
        taskQueue.async { [weak self] in
            self?.activeTasks.removeValue(forKey: id)
        }
    }
    
    func cancelRequest(withId id: String) {
        taskQueue.async { [weak self] in
            if let task = self?.activeTasks[id] {
                task.cancel()
                self?.activeTasks.removeValue(forKey: id)
            }
        }
    }
    
    func cancelAllRequests() {
        taskQueue.async { [weak self] in
            self?.activeTasks.values.forEach { $0.cancel() }
            self?.activeTasks.removeAll()
        }
    }
} 
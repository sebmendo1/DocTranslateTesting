import Foundation

// This file contains API key handling for the app.
// In a production app, API keys should be stored securely and not in source code.

public struct APIKeys {
    // DeepL API key - read from environment or use the provided key
    public static let deepLAPIKey: String = {
        // For production, use environment variables or secure storage
        if let envKey = ProcessInfo.processInfo.environment["DEEPL_API_KEY"] {
            return envKey
        }
        
        // Return the provided API key
        return "62262f3b-ab22-4100-ad41-a1a693c97a2b:fx"
    }()
    
    // Whether this is a DeepL Pro account (false for Free account)
    public static let isDeepLProAccount: Bool = {
        if let envValue = ProcessInfo.processInfo.environment["DEEPL_IS_PRO_ACCOUNT"],
           envValue.lowercased() == "true" {
            return true
        }
        // This is a free account based on the ":fx" suffix in the API key
        return false
    }()
}

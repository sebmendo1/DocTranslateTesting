import Foundation

// This file is a template for API key handling.
// Copy this file to TestAPIKey.swift and replace the placeholder with your actual API key.
// In a production app, API keys should be stored securely and not in source code.

public struct APIKeysTeXmplate {
    // DeepL API key - read from environment or use placeholder
    public static let deepLAPIKey: String = {
        // For production, use environment variables or secure storage
        if let envKey = ProcessInfo.processInfo.environment["DEEPL_API_KEY"] {
            return envKey
        }
        
        // Return a placeholder for development
        return "YOUR_DEEPL_API_KEY_HERE"
    }()
    
    // Whether this is a DeepL Pro account (false for Free account)
    public static let isDeepLProAccount: Bool = {
        if let envValue = ProcessInfo.processInfo.environment["DEEPL_IS_PRO_ACCOUNT"],
           envValue.lowercased() == "true" {
            return true
        }
        return false
    }()
}

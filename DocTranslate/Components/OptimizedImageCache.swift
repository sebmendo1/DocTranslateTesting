import Foundation
import UIKit

class OptimizedImageCache {
    // Singleton instance
    static let shared = OptimizedImageCache()
    
    // Cache Entry class to match what the model expects
    class CacheEntry {
        let image: UIImage
        
        init(image: UIImage) {
            self.image = image
        }
    }
    
    // Internal cache implementation
    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    private let diskCacheDirectory: URL
    
    init() {
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        diskCacheDirectory = documentsDirectory.appendingPathComponent("ImageCache")
        
        // Create cache directory if it doesn't exist
        if !fileManager.fileExists(atPath: diskCacheDirectory.path) {
            do {
                try fileManager.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)
            } catch {
                print("Error creating disk cache directory: \(error)")
            }
        }
        
        // Set up cache size limits
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        
        // Register for memory warnings
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
    
    // Store an image in the cache
    func storeImage(_ image: UIImage, forKey key: String) {
        let cacheKey = NSString(string: key)
        cache.setObject(image, forKey: cacheKey)
        
        // Also save to disk for persistence
        let fileURL = diskCacheDirectory.appendingPathComponent(key)
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: fileURL)
        }
    }
    
    // Store an image in the cache
    func storeImage(_ entry: CacheEntry, withID id: String) {
        storeImage(entry.image, forKey: id)
    }
    
    // Retrieve an image from the cache
    func getImage(forKey key: String) -> UIImage? {
        let cacheKey = NSString(string: key)
        
        // First check memory cache
        if let cachedImage = cache.object(forKey: cacheKey) {
            return cachedImage
        }
        
        // Then check disk cache
        let fileURL = diskCacheDirectory.appendingPathComponent(key)
        if fileManager.fileExists(atPath: fileURL.path),
           let data = try? Data(contentsOf: fileURL),
           let image = UIImage(data: data) {
            // Load back into memory cache
            cache.setObject(image, forKey: cacheKey)
            return image
        }
        
        return nil
    }
    
    // Retrieve an image from the cache with callback
    func getImage(withID id: String, completion: @escaping (UIImage?) -> Void) {
        let image = getImage(forKey: id)
        completion(image)
    }
    
    // Remove an image from the cache
    func removeImage(forKey key: String) {
        let cacheKey = NSString(string: key)
        cache.removeObject(forKey: cacheKey)
        
        // Also remove from disk
        let fileURL = diskCacheDirectory.appendingPathComponent(key)
        if fileManager.fileExists(atPath: fileURL.path) {
            try? fileManager.removeItem(at: fileURL)
        }
    }
    
    // Remove an image with ID
    func removeImage(withID id: String) {
        removeImage(forKey: id)
    }
    
    // Clear all images from the cache
    func clearAllImages() {
        cache.removeAllObjects()
        
        // Also clear disk
        if fileManager.fileExists(atPath: diskCacheDirectory.path) {
            try? fileManager.removeItem(at: diskCacheDirectory)
            try? fileManager.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)
        }
    }
    
    // Handle memory warning by clearing the memory cache
    @objc public func handleMemoryWarning() {
        cache.removeAllObjects()
    }
} 
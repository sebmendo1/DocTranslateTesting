import SwiftUI
import VisionKit
import AVFoundation

struct DocumentScannerView: UIViewControllerRepresentable {
    @ObservedObject var scannerModel: DocumentScannerModel
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        // Check camera permission before presenting the scanner
        checkCameraPermission()
        
        let documentCameraViewController = VNDocumentCameraViewController()
        documentCameraViewController.delegate = context.coordinator
        return documentCameraViewController
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Check camera permission
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // Camera access is already authorized
            break
        case .notDetermined:
            // Request camera access
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if !granted {
                    DispatchQueue.main.async {
                        print("Camera access is required to scan documents")
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        case .denied, .restricted:
            // Camera access was denied
            DispatchQueue.main.async {
                print("Camera access is required to scan documents. Please enable it in Settings.")
                self.presentationMode.wrappedValue.dismiss()
            }
        @unknown default:
            break
        }
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        var parent: DocumentScannerView
        
        init(_ parent: DocumentScannerView) {
            self.parent = parent
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            // Process the scanned document
            if scan.pageCount > 0 {
                // Get the first page as the main image
                let image = scan.imageOfPage(at: 0)
                
                // Store images in the model
                parent.scannerModel.scannedImage = image
                
                var images: [UIImage] = []
                for i in 0..<scan.pageCount {
                    images.append(scan.imageOfPage(at: i))
                }
                parent.scannerModel.scannedImages = images
                
                // Process the document to extract text
                parent.scannerModel.processScannedDocument()
            }
            
            // Dismiss the scanner
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            // User canceled the scan
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            // Handle error
            print("Document scanner error: \(error.localizedDescription)")
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Preview Provider
struct DocumentScannerView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a DocumentScannerModel for previews
        let scannerModel = DocumentScannerModel()
        
        // Mock a placeholder view that represents how DocumentScannerView would be used
        return Group {
            // Preview showing how to present DocumentScannerView in sheet
            PreviewDocumentScannerContainer(scannerModel: scannerModel)
                .previewDisplayName("Scanner Usage Example")
            
            // Preview showing how scanner would be presented in dark mode
            PreviewDocumentScannerContainer(scannerModel: scannerModel)
                .preferredColorScheme(.dark)
                .previewDisplayName("Scanner Usage (Dark Mode)")
        }
    }
}

// Helper container for previewing DocumentScannerView usage
private struct PreviewDocumentScannerContainer: View {
    @ObservedObject var scannerModel: DocumentScannerModel
    @State private var showingScanner = false
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Document Scanner Preview")
                    .font(.headline)
                    .padding()
                
                Image(systemName: "doc.viewfinder")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .padding()
                
                Text("This is a preview of how to integrate the DocumentScannerView in your app")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button(action: {
                    // In real usage, this would show the scanner
                    showingScanner = true
                }) {
                    HStack {
                        Image(systemName: "camera.viewfinder")
                        Text("Scan Document")
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                Text("Note: The actual camera scanner cannot be shown in previews")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top)
            }
            .padding()
            .navigationTitle("Document Scanner")
            .sheet(isPresented: $showingScanner) {
                // In actual usage, this is where DocumentScannerView would be presented
                // The preview doesn't show the actual camera view since it requires device access
                Text("Camera Scanner View")
                    .font(.headline)
                    .padding()
            }
        }
    }
} 
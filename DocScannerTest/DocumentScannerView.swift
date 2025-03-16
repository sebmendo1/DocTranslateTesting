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
                        self.scannerModel.errorMessage = "Camera access is required to scan documents"
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        case .denied, .restricted:
            // Camera access was denied
            DispatchQueue.main.async {
                self.scannerModel.errorMessage = "Camera access is required to scan documents. Please enable it in Settings."
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
            parent.scannerModel.processScannedDocument(results: scan)
            
            // Dismiss the scanner
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            // User canceled the scan
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            // Handle error
            parent.scannerModel.errorMessage = error.localizedDescription
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
} 
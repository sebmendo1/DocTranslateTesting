import SwiftUI
import StoreKit
import UIKit

struct SettingsView: View {
    @ObservedObject var scannerModel: DocumentScannerModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingRequestReview = false
    @State private var showingResetConfirmation = false
    @State private var showingScanningTips = false
    
    var body: some View {
        NavigationView {
            List {
                // Appearance Settings
                Section(header: Text("Appearance")) {
                    // Theme toggle (Light/Dark) could be added here
                    Toggle(isOn: .constant(true)) { // Replace with actual binding when implemented
                        HStack {
                            Image(systemName: "moon.fill")
                                .foregroundColor(.themePrimary)
                            Text("Dark Mode")
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .themePrimary))
                }
                
                // Document Settings
                Section(header: Text("Documents")) {
                    NavigationLink(destination: scanQualitySettingsView) {
                        HStack {
                            Image(systemName: "doc.viewfinder")
                                .foregroundColor(.themePrimary)
                            Text("Scanning Quality")
                            Spacer()
                            Text("High")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Storage management row
                    NavigationLink(destination: Text("Storage Management View")) {
                        HStack {
                            Image(systemName: "externaldrive")
                                .foregroundColor(.themePrimary)
                            Text("Storage Management")
                        }
                    }
                }
                
                // App Settings
                Section(header: Text("App Settings")) {
                    Button(action: {
                        showingScanningTips = true
                    }) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.themePrimary)
                            Text("Scanning Tips")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.system(size: 14))
                        }
                    }
                    
                    Button(action: {
                        showingResetConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("Reset All Data")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // Support
                Section(header: Text("Support")) {
                    Button(action: {
                        if let url = URL(string: "https://example.com/privacy") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(.themePrimary)
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.gray)
                                .font(.system(size: 14))
                        }
                    }
                    
                    Button(action: {
                        if let url = URL(string: "https://example.com/terms") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.themePrimary)
                            Text("Terms of Service")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.gray)
                                .font(.system(size: 14))
                        }
                    }
                    
                    Button(action: {
                        showingRequestReview = true
                    }) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.themePrimary)
                            Text("Rate the App")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.system(size: 14))
                        }
                    }
                    
                    Button(action: sendFeedback) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.themePrimary)
                            Text("Send Feedback")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.system(size: 14))
                        }
                    }
                }
                
                // About
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundColor(.gray)
                    }
                    
                    // App information
                    HStack {
                        Text("Made with ♥ by Example Inc.")
                            .font(.footnote)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showingScanningTips) {
                ScanningTipsView()
            }
            .alert(isPresented: $showingResetConfirmation) {
                Alert(
                    title: Text("Reset All Data"),
                    message: Text("This will delete all your saved documents and settings. This action cannot be undone."),
                    primaryButton: .destructive(Text("Reset")) {
                        // Reset the scanner model
                        scannerModel.resetAll()
                        // Show confirmation
                        presentationMode.wrappedValue.dismiss()
                    },
                    secondaryButton: .cancel()
                )
            }
            .onChange(of: showingRequestReview) { value in
                if value {
                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        SKStoreReviewController.requestReview(in: scene)
                    }
                    showingRequestReview = false
                }
            }
        }
    }
    
    // Scanning quality settings view
    private var scanQualitySettingsView: some View {
        List {
            ForEach(ScanQualityOption.allCases, id: \.self) { quality in
                Button(action: {
                    // Update scanning quality preference
                    // scannerModel.scanQuality = quality
                }) {
                    HStack {
                        Text(quality.displayName)
                        Spacer()
                        if quality == .high { // Replace with actual quality check
                            Image(systemName: "checkmark")
                                .foregroundColor(.themePrimary)
                        }
                    }
                }
                .foregroundColor(.primary)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Scanning Quality")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func sendFeedback() {
        if let url = URL(string: "mailto:support@example.com?subject=DocScanner%20Feedback") {
            UIApplication.shared.open(url)
        }
    }
}

// Scanning tips view
struct ScanningTipsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    tipCard(
                        icon: "light.max",
                        title: "Good Lighting",
                        description: "Ensure your document is well-lit to get the best quality scan."
                    )
                    
                    tipCard(
                        icon: "doc.viewfinder",
                        title: "Proper Alignment",
                        description: "Position the document so all four corners are visible in the frame."
                    )
                    
                    tipCard(
                        icon: "hand.raised",
                        title: "Avoid Shadows",
                        description: "Try not to cast shadows on your document while scanning."
                    )
                    
                    tipCard(
                        icon: "camera.filters",
                        title: "Clean Camera",
                        description: "Make sure your camera lens is clean for the best results."
                    )
                    
                    tipCard(
                        icon: "arrow.left.and.right.square",
                        title: "Document Size",
                        description: "For multi-page documents, ensure consistent positioning between scans."
                    )
                }
                .padding()
            }
            .navigationTitle("Scanning Tips")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func tipCard(icon: String, title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.themePrimary)
                    .frame(width: 36, height: 36)
                
                Text(title)
                    .font(.headline)
                
                Spacer()
            }
            
            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color.themeBackgroundSecondary)
        .cornerRadius(10)
    }
}

// Mock enum for scan quality
enum ScanQualityOption: String, CaseIterable {
    case low
    case medium
    case high
    
    var displayName: String {
        switch self {
        case .low: return "Low (Faster)"
        case .medium: return "Medium"
        case .high: return "High (Better Quality)"
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(scannerModel: DocumentScannerModel())
    }
} 
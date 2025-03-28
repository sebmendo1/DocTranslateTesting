import SwiftUI

struct AlbumsView: View {
    @ObservedObject var scannerModel: DocumentScannerModel
    @State private var showingNewAlbumSheet = false
    @State private var newAlbumName = ""
    @State private var searchText = ""
    @State private var showingDeleteConfirmation = false
    @State private var albumToDelete: IndexSet?
    
    var filteredAlbums: [DocumentScannerModel.Album] {
        if searchText.isEmpty {
            return scannerModel.albums
        } else {
            return scannerModel.albums.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if scannerModel.albums.isEmpty {
                    emptyStateView
                } else {
                    albumListView
                }
            }
            .navigationTitle("Albums")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingNewAlbumSheet = true
                    }) {
                        Image(systemName: "folder.badge.plus")
                            .accessibilityLabel("Create new album")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search Albums")
            .sheet(isPresented: $showingNewAlbumSheet) {
                createAlbumSheet
            }
            .alert(isPresented: $showingDeleteConfirmation) {
                Alert(
                    title: Text("Delete Album"),
                    message: Text("Are you sure you want to delete this album? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        if let offsets = albumToDelete {
                            deleteAlbum(at: offsets)
                            albumToDelete = nil
                        }
                    },
                    secondaryButton: .cancel {
                        albumToDelete = nil
                    }
                )
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 80))
                .foregroundColor(.themePrimary.opacity(0.8))
                .accessibilityHidden(true)
            
            Text("No Albums")
                .font(AppTheme.Typography.title2)
                .fontWeight(.bold)
            
            Text("Create albums to organize your scanned documents")
                .foregroundColor(.themeTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.xlarge)
            
            Button(action: {
                showingNewAlbumSheet = true
            }) {
                Label("Create Album", systemImage: "folder.badge.plus")
                    .font(AppTheme.Typography.headline)
                    .padding()
                    .frame(maxWidth: 250)
                    .background(Color.themePrimary)
                    .foregroundColor(.themeButtonText)
                    .cornerRadius(AppTheme.CornerRadius.medium)
            }
            .padding(.top, AppTheme.Spacing.medium)
            .accessibilityIdentifier("createAlbumButton")
        }
        .padding(AppTheme.Spacing.medium)
    }
    
    private var albumListView: some View {
        List {
            ForEach(filteredAlbums) { album in
                NavigationLink(destination: AlbumDetailView(album: album, scannerModel: scannerModel)) {
                    HStack(spacing: AppTheme.Spacing.medium) {
                        // Album thumbnail
                        ZStack {
                            if let firstImage = album.images.first {
                                Image(uiImage: firstImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 70, height: 70)
                                    .cornerRadius(AppTheme.CornerRadius.small)
                                    .clipped()
                            } else {
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                                    .strokeBorder(Color.themePrimary, lineWidth: 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                                            .foregroundColor(Color.themeNeutralLight.opacity(0.3))
                                    )
                                
                                Image(systemName: "doc.text")
                                    .font(.system(size: 24))
                                    .foregroundColor(.themeNeutralMedium)
                            }
                        }
                        .shadow(
                            color: AppTheme.Shadow.small.color.opacity(AppTheme.Shadow.small.opacity),
                            radius: AppTheme.Shadow.small.radius,
                            x: AppTheme.Shadow.small.x,
                            y: AppTheme.Shadow.small.y
                        )
                        
                        // Album info
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xsmall) {
                            Text(album.name)
                                .font(AppTheme.Typography.headline)
                                .lineLimit(1)
                            
                            HStack(spacing: AppTheme.Spacing.xsmall) {
                                Image(systemName: "doc.text")
                                    .font(AppTheme.Typography.caption1)
                                    .foregroundColor(.themeTextSecondary)
                                
                                Text("\(album.images.count) \(album.images.count == 1 ? "document" : "documents")")
                                    .font(AppTheme.Typography.subheadline)
                                    .foregroundColor(.themeTextSecondary)
                            }
                            
                            Text(album.date, style: .date)
                                .font(AppTheme.Typography.caption1)
                                .foregroundColor(.themeTextSecondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, AppTheme.Spacing.small)
                    .contentShape(Rectangle())
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(album.name) album with \(album.images.count) \(album.images.count == 1 ? "document" : "documents"), created on \(album.date, style: .date)")
                }
            }
            .onDelete { indexSet in
                albumToDelete = indexSet
                showingDeleteConfirmation = true
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    private var createAlbumSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Album Details")) {
                    TextField("Album Name", text: $newAlbumName)
                        .font(AppTheme.Typography.body)
                        .autocapitalization(.words)
                        .disableAutocorrection(false)
                        .accessibilityIdentifier("albumNameField")
                }
                
                Section {
                    Button(action: {
                        if !newAlbumName.isEmpty {
                            let album = scannerModel.createAlbum(name: newAlbumName)
                            // Add the current image to the album if available
                            if let image = scannerModel.scannedImage {
                                scannerModel.addImageToAlbum(image, albumId: album.id)
                            }
                            newAlbumName = ""
                            showingNewAlbumSheet = false
                        }
                    }) {
                        HStack {
                            Spacer()
                            Text("Create Album")
                                .font(AppTheme.Typography.headline)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(newAlbumName.isEmpty)
                    .accessibilityIdentifier("confirmCreateAlbumButton")
                }
            }
            .navigationTitle("New Album")
            .navigationBarItems(
                leading: Button("Cancel") {
                    newAlbumName = ""
                    showingNewAlbumSheet = false
                },
                trailing: Button("Create") {
                    if !newAlbumName.isEmpty {
                        let album = scannerModel.createAlbum(name: newAlbumName)
                        // Add the current image to the album if available
                        if let image = scannerModel.scannedImage {
                            scannerModel.addImageToAlbum(image, albumId: album.id)
                        }
                        newAlbumName = ""
                        showingNewAlbumSheet = false
                    }
                }
                .disabled(newAlbumName.isEmpty)
            )
        }
    }
    
    private func deleteAlbum(at offsets: IndexSet) {
        scannerModel.albums.remove(atOffsets: offsets)
    }
}

struct AlbumDetailView: View {
    let album: DocumentScannerModel.Album
    @ObservedObject var scannerModel: DocumentScannerModel
    @State private var selectedImage: UIImage?
    @State private var showingImageViewer = false
    @State private var showingDeleteConfirmation = false
    @State private var imageToDelete: Int?
    
    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            if album.images.isEmpty {
                emptyAlbumView
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(0..<album.images.count, id: \.self) { index in
                        let image = album.images[index]
                        documentItem(image: image, index: index)
                    }
                }
                .padding()
            }
        }
        .navigationTitle(album.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        // Export all as PDF
                        exportAlbumAsPDF()
                    }) {
                        Label("Export as PDF", systemImage: "arrow.down.doc")
                    }
                    
                    Button(action: {
                        // Share album
                        shareAlbum()
                    }) {
                        Label("Share Album", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .accessibilityLabel("More options")
                }
            }
        }
        .sheet(isPresented: $showingImageViewer) {
            if let image = selectedImage {
                ImageViewerView(image: image, scannerModel: scannerModel)
            }
        }
        .alert(isPresented: $showingDeleteConfirmation) {
            Alert(
                title: Text("Delete Document"),
                message: Text("Are you sure you want to remove this document from the album?"),
                primaryButton: .destructive(Text("Delete")) {
                    if let index = imageToDelete {
                        removeImage(at: index)
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private var emptyAlbumView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.themeTextSecondary)
            
            Text("No Documents")
                .font(AppTheme.Typography.title2)
                .fontWeight(.semibold)
            
            Text("This album is empty. Scan documents and add them to this album.")
                .multilineTextAlignment(.center)
                .foregroundColor(.themeTextSecondary)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
        .frame(minHeight: 300)
    }
    
    private func documentItem(image: UIImage, index: Int) -> some View {
        ZStack(alignment: .bottomTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 200)
                .cornerRadius(AppTheme.CornerRadius.medium)
                .clipped()
                .shadow(
                    color: AppTheme.Shadow.small.color.opacity(AppTheme.Shadow.small.opacity),
                    radius: AppTheme.Shadow.small.radius,
                    x: AppTheme.Shadow.small.x,
                    y: AppTheme.Shadow.small.y
                )
                .onTapGesture {
                    selectedImage = image
                    showingImageViewer = true
                }
                .contextMenu {
                    Button(action: {
                        selectedImage = image
                        showingImageViewer = true
                    }) {
                        Label("View", systemImage: "eye")
                    }
                    
                    Button(action: {
                        scannerModel.recognizeText(in: image)
                    }) {
                        Label("Extract Text", systemImage: "text.viewfinder")
                    }
                    
                    Button(action: {
                        shareImage(image)
                    }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(role: .destructive, action: {
                        imageToDelete = index
                        showingDeleteConfirmation = true
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                }
            
            // OCR button
            Button(action: {
                scannerModel.recognizeText(in: image)
            }) {
                Image(systemName: "text.viewfinder")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(8)
                    .background(Color.themePrimary)
                    .clipShape(Circle())
                    .shadow(
                        color: AppTheme.Shadow.small.color.opacity(AppTheme.Shadow.small.opacity),
                        radius: AppTheme.Shadow.small.radius,
                        x: AppTheme.Shadow.small.x,
                        y: AppTheme.Shadow.small.y
                    )
            }
            .padding(8)
            .accessibilityLabel("Extract text")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Document image \(index + 1)")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Double tap to view document")
    }
    
    private func removeImage(at index: Int) {
        scannerModel.removeImageFromAlbum(at: index, albumId: album.id)
    }
    
    private func shareImage(_ image: UIImage) {
        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
    
    private func shareAlbum() {
        let activityVC = UIActivityViewController(
            activityItems: album.images,
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
    
    private func exportAlbumAsPDF() {
        let pdfData = scannerModel.createPDF(from: album.images, includeText: false)
        
        let activityVC = UIActivityViewController(
            activityItems: [pdfData],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
}

struct ImageViewerView: View {
    let image: UIImage
    @ObservedObject var scannerModel: DocumentScannerModel
    @Environment(\.presentationMode) var presentationMode
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var showingOCRResult = false
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.themeNeutralDark.edgesIgnoringSafeArea(.all)
                
                // Image with gestures
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / lastScale
                                lastScale = value
                                scale *= delta
                            }
                            .onEnded { _ in
                                lastScale = 1.0
                            }
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
                    .gesture(
                        TapGesture(count: 2)
                            .onEnded {
                                withAnimation(.spring()) {
                                    if scale > 1.0 {
                                        scale = 1.0
                                        offset = .zero
                                        lastOffset = .zero
                                    } else {
                                        scale = 2.0
                                    }
                                }
                            }
                    )
                    .accessibilityLabel("Document image")
                
                // OCR result overlay
                if showingOCRResult && !scannerModel.scannedText.isEmpty {
                    VStack {
                        ScrollView {
                            Text(scannerModel.scannedText)
                                .padding()
                                .foregroundColor(.themeButtonText)
                                .textSelection(.enabled)
                        }
                        .background(Color.themeNeutralDark.opacity(0.7))
                        .cornerRadius(12)
                        .padding()
                        
                        HStack {
                            Button(action: {
                                UIPasteboard.general.string = scannerModel.scannedText
                            }) {
                                Label("Copy", systemImage: "doc.on.doc")
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.themePrimaryDark.opacity(0.5))
                                    .cornerRadius(8)
                            }
                            
                            Button(action: {
                                showingShareSheet = true
                            }) {
                                Label("Share", systemImage: "square.and.arrow.up")
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.themePrimaryDark.opacity(0.5))
                                    .cornerRadius(8)
                            }
                        }
                        .foregroundColor(.themeButtonText)
                        .padding(.bottom)
                    }
                }
                
                // Processing indicator
                if scannerModel.isProcessing {
                    VStack {
                        ProgressView("Processing...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .themeButtonText))
                            .foregroundColor(.themeButtonText)
                            .padding()
                            .background(Color.themeNeutralDark.opacity(0.7))
                            .cornerRadius(12)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Close")
                            .foregroundColor(.themeButtonText)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 20) {
                        Button(action: {
                            if scannerModel.scannedText.isEmpty {
                                scannerModel.recognizeText(in: image)
                            }
                            showingOCRResult.toggle()
                        }) {
                            Image(systemName: showingOCRResult ? "text.viewfinder.fill" : "text.viewfinder")
                                .foregroundColor(.themeButtonText)
                        }
                        .disabled(scannerModel.isProcessing)
                        
                        Button(action: {
                            showingShareSheet = true
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.themeButtonText)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if !scannerModel.scannedText.isEmpty && showingOCRResult {
                    ShareSheet(items: [scannerModel.scannedText])
                } else {
                    ShareSheet(items: [image])
                }
            }
        }
    }
} 

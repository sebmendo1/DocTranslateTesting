import SwiftUI

struct AlbumsView: View {
    @ObservedObject var scannerModel: DocumentScannerModel
    @State private var showingNewAlbumSheet = false
    @State private var newAlbumName = ""
    @State private var searchText = ""
    
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
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search Albums")
            .sheet(isPresented: $showingNewAlbumSheet) {
                createAlbumSheet
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            Text("No Albums")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Scan documents to create albums")
                .foregroundColor(.secondary)
            
            Button(action: {
                // Navigate to scanner
            }) {
                Text("Scan Document")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
    
    private var albumListView: some View {
        List {
            ForEach(filteredAlbums) { album in
                NavigationLink(destination: AlbumDetailView(album: album, scannerModel: scannerModel)) {
                    HStack {
                        if let firstImage = album.images.first {
                            Image(uiImage: firstImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .cornerRadius(8)
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 60, height: 60)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(album.name)
                                .font(.headline)
                            
                            Text("\(album.images.count) \(album.images.count == 1 ? "image" : "images")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(album.date, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 8)
                    }
                    .padding(.vertical, 4)
                }
            }
            .onDelete(perform: deleteAlbum)
        }
    }
    
    private var createAlbumSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Album Name")) {
                    TextField("Enter album name", text: $newAlbumName)
                }
                
                Section {
                    Button(action: {
                        if !newAlbumName.isEmpty {
                            scannerModel.createAlbum(name: newAlbumName)
                            newAlbumName = ""
                            showingNewAlbumSheet = false
                        }
                    }) {
                        Text("Create Album")
                    }
                    .disabled(newAlbumName.isEmpty)
                }
            }
            .navigationTitle("New Album")
            .navigationBarItems(trailing: Button("Cancel") {
                showingNewAlbumSheet = false
            })
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
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 10) {
                ForEach(0..<album.images.count, id: \.self) { index in
                    let image = album.images[index]
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 160)
                        .cornerRadius(8)
                        .onTapGesture {
                            selectedImage = image
                            showingImageViewer = true
                        }
                }
            }
            .padding()
        }
        .navigationTitle(album.name)
        .sheet(isPresented: $showingImageViewer) {
            if let image = selectedImage {
                ImageViewerView(image: image, scannerModel: scannerModel)
            }
        }
    }
}

struct ImageViewerView: View {
    let image: UIImage
    @ObservedObject var scannerModel: DocumentScannerModel
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var showingOCRResult = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
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
                                if scale > 1.0 {
                                    scale = 1.0
                                    offset = .zero
                                    lastOffset = .zero
                                } else {
                                    scale = 2.0
                                }
                            }
                    )
            }
            .navigationBarItems(
                leading: Button("Close") {
                    // This will dismiss the sheet
                },
                trailing: HStack {
                    Button(action: {
                        scannerModel.recognizeText(in: image)
                        showingOCRResult = true
                    }) {
                        Image(systemName: "text.viewfinder")
                    }
                    
                    Button(action: {
                        // Share the image
                        let activityVC = UIActivityViewController(
                            activityItems: [image],
                            applicationActivities: nil
                        )
                        
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let rootViewController = windowScene.windows.first?.rootViewController {
                            rootViewController.present(activityVC, animated: true)
                        }
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            )
            .sheet(isPresented: $showingOCRResult) {
                OCRResultView(text: scannerModel.scannedText, language: scannerModel.detectedLanguage)
            }
        }
    }
}

struct OCRResultView: View {
    let text: String
    let language: String?
    @State private var translatedText: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let language = language {
                        Text("Detected Language: \(language)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                    
                    Text(text.isEmpty ? "No text detected" : text)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    
                    if !text.isEmpty {
                        Button(action: {
                            UIPasteboard.general.string = text
                        }) {
                            Label("Copy Text", systemImage: "doc.on.doc")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Extracted Text")
            .navigationBarItems(trailing: Button("Done") {
                // This will dismiss the sheet
            })
        }
    }
} 

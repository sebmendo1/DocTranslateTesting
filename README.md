# Document Scanner App

A powerful document scanning app built with SwiftUI and VisionKit that allows you to scan documents, extract text using OCR, and translate text using the DeepL API.

## Features

- **Document Scanning**: Easily scan documents using your device's camera with automatic edge detection
- **OCR Text Recognition**: Extract text from scanned documents in multiple languages
- **Translation**: Translate extracted text to multiple languages using DeepL API
- **Image Enhancement**: Improve document readability with image enhancement
- **Album Organization**: Organize your scanned documents into albums
- **PDF Export**: Export scanned documents as PDF files
- **Multi-language Support**: OCR and translation support for multiple languages

## Requirements

- iOS 16.0+
- Xcode 14.0+
- Swift 5.0+
- DeepL API key (for translation features)

## Setup After Cloning

### API Key Setup

For security reasons, the API key is not included in the repository. After cloning, you need to set up your API key:

1. Copy the template file:
   ```bash
   cp DocScannerTest/TestAPIKey.template.swift DocScannerTest/TestAPIKey.swift
   ```

2. Edit the `TestAPIKey.swift` file and replace `YOUR_DEEPL_API_KEY_HERE` with your actual DeepL API key.

3. Alternatively, you can set environment variables in Xcode:
   - Open the scheme editor (Product > Scheme > Edit Scheme)
   - Select "Run" and then the "Arguments" tab
   - Under "Environment Variables", add:
     - `DEEPL_API_KEY` with your API key
     - `DEEPL_IS_PRO_ACCOUNT` with "true" or "false"

### Important Note

Never commit your API keys to public repositories. The `TestAPIKey.swift` file is included in `.gitignore` to prevent accidental commits.

## Translation Features

The app integrates with the DeepL API to provide high-quality translations of scanned text. Key translation features include:

- Translate text to 11 different languages
- Detect source language automatically
- Preserve formatting during translation
- Translate entire documents (PDF)
- View original and translated text side by side

### Setting Up DeepL API

To use the translation features, you need to:

1. Sign up for a DeepL API account at [DeepL API](https://www.deepl.com/pro-api)
2. Get your API key from the DeepL dashboard
3. Enter your API key in the app's Settings screen
4. Select whether you're using a Free or Pro account

## Usage

1. **Scanning Documents**:
   - Tap the "Scan Document" button
   - Position your document within the frame
   - The app will automatically detect the document edges
   - Tap the capture button to scan

2. **OCR Text Recognition**:
   - After scanning, the app will automatically extract text
   - View the extracted text in the document view
   - Copy or share the extracted text

3. **Translation**:
   - Tap the "Translate" button on the document view
   - Select a target language or choose "Advanced Translation"
   - View the translated text alongside the original
   - Copy or share the translated text

4. **Document Management**:
   - Save scans to albums for organization
   - Export documents as PDFs
   - Share documents via standard iOS sharing options

## Implementation Details

The app uses:
- SwiftUI for the user interface
- VisionKit for document scanning
- Vision framework for OCR
- DeepL API for translation
- PDFKit for PDF generation

## License

This project is licensed under the MIT License - see the LICENSE file for details. 
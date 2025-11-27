# LLMKit

A Swift package for parsing documents and images using AI models from Claude (Anthropic) and OpenAI.

## Overview

LLMKit provides a unified interface for parsing PDFs, images, and text using large language models. It supports both Claude (Anthropic) and OpenAI as backends, allowing you to extract structured data from documents with type-safe Swift models.

## Platform Support

- iOS 15.0+
- macOS 12.0+
- watchOS 8.0+
- tvOS 15.0+

## Installation

### Swift Package Manager

Add LLMKit to your project via Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/LLMKit.git", from: "1.0.0")
]
```

## Usage

### Creating a Service

Use `LLMKitFactory` to create a document parsing service with your preferred AI provider:

```swift
import LLMKit

// For Claude (Anthropic)
let service = LLMKitFactory.createUnifiedService(claudeKey: "your-claude-api-key")

// For OpenAI
let service = LLMKitFactory.createUnifiedService(openAIKey: "your-openai-api-key")
```

### Parsing Documents

The `UnifiedDocumentParsingService` supports parsing various document types:

#### Parse from Data

```swift
// Define your model
struct Invoice: ParseableModel {
    let invoiceNumber: String
    let amount: Double
    let date: String
}

// Parse PDF or image data
let result = try await service.parseDocument(
    data: documentData,
    fileName: "invoice.pdf",
    as: Invoice.self
)
```

#### Parse from URL

```swift
let fileURL = URL(fileURLWithPath: "/path/to/document.pdf")
let result = try await service.parseDocument(from: fileURL, as: Invoice.self)
```

#### Query with Prompt

```swift
struct Summary: ParseableModel {
    let keyPoints: [String]
    let sentiment: String
}

let result = try await service.query(
    prompt: "Summarize the main points of this text",
    as: Summary.self
)
```

### Supported File Types

LLMKit supports the following file formats:

- **PDF**: `.pdf`
- **Images**: `.jpg`, `.jpeg`, `.png`, `.gif`, `.webp`, `.heic`, `.heif`

#### Check File Support

```swift
let url = URL(fileURLWithPath: "/path/to/file.pdf")

if service.isFileTypeSupported(url) {
    if let method = service.getParsingMethod(for: url) {
        print("Parsing method: \(method)")
    }
}
```

## Features

- **Unified API**: Single interface for multiple AI providers (Claude and OpenAI)
- **Type-Safe Parsing**: Define Swift structs/classes conforming to `ParseableModel` for structured extraction
- **Multiple Input Sources**: Parse from `Data` or file `URL`
- **Document Format Detection**: Automatic file type detection and appropriate parsing strategy
- **Zero Dependencies**: Uses only Foundation framework

## Requirements

- Swift 5.9+
- Valid API key from Claude (Anthropic) or OpenAI

## License

Copyright © 2025 m. All rights reserved.

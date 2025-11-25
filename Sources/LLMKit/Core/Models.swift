//
//  Models.swift
//  LLMKit
//
//  Created by Mayank Gandhi on 05/08/25.
//  Copyright © 2025 m. All rights reserved.
//

import Foundation

public enum LLMKitError: Error, LocalizedError {
    case invalidAPIKey
    case invalidURL
    case invalidResponse
    case invalidFileData
    case networkError(Error)
    case parsingError(String)
    case uploadError(String)
    case deleteError(String)
    case unsupportedFileType(String)
    case decodingError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API key provided"
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .invalidFileData:
            return "Invalid file data provided"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .parsingError(let message):
            return "Parsing error: \(message)"
        case .uploadError(let message):
            return "Upload error: \(message)"
        case .deleteError(let message):
            return "Delete error: \(message)"
        case .unsupportedFileType(let message):
            return "Unsupported file type: \(message)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
}

// MARK: - File Processing

public enum ParsingMethod {
    case directVision
    case pdfFileUpload
    
    public var description: String {
        switch self {
        case .directVision:
            return "Direct AI Vision analysis"
        case .pdfFileUpload:
            return "PDF uploaded to AI service with file search and structured parsing"
        }
    }
}
//
//  UnifiedDocumentParsingService.swift
//  LLMKit
//
//  Created by Mayank Gandhi on 05/08/25.
//  Copyright © 2025 m. All rights reserved.
//

import Foundation

/// Simple, unified service for parsing any supported document type
public final class UnifiedDocumentParsingService: DocumentParsingService, ObservableObject {

    // MARK: - Dependencies
    
    private var parser: DocumentParserProtocol
    private var serviceType: ServiceType
    private var claudeKey: String?
    private var openAIKey: String?
    private let parserFactory: DocumentParserFactoryProtocol
    
    // MARK: - Initialization
    
    public init(
        apiKey: String,
        serviceType: ServiceType,
        parserFactory: DocumentParserFactoryProtocol = DocumentParserFactory()
    ) {
        self.serviceType = serviceType
        self.parserFactory = parserFactory
        switch serviceType {
        case .claude:
            self.claudeKey = apiKey
            self.parser = parserFactory.createParser(claudeKey: apiKey)
        case .openAI:
            self.openAIKey = apiKey
            self.parser = parserFactory.createParser(openAIKey: apiKey)
        }
    }
    
    // MARK: - Configuration
    
    /// Configure which service to use for parsing
    /// Note: The service must have been initialized with the appropriate API key
    public func configure(serviceType: ServiceType) {
        self.serviceType = serviceType
        parser.configure(serviceType: serviceType)
        
        // Set the appropriate key if available
        switch serviceType {
        case .claude:
            if let claudeKey = claudeKey {
                parser.setClaudeKey(claudeKey)
            }
        case .openAI:
            if let openAIKey = openAIKey {
                parser.setOpenAIKey(openAIKey)
            }
        }
    }
    
    /// Set the Claude API key (allows switching to Claude service)
    public func setClaudeKey(_ key: String) {
        self.claudeKey = key
        parser.setClaudeKey(key)
    }
    
    /// Set the OpenAI API key (allows switching to OpenAI service)
    public func setOpenAIKey(_ key: String) {
        self.openAIKey = key
        parser.setOpenAIKey(key)
    }
    
    // MARK: - DocumentParsingService
    
    public func parseDocument<T: ParseableModel>(data: Data, fileName: String, as type: T.Type) async throws -> T {
        let fileExtension = URL(fileURLWithPath: fileName).pathExtension.lowercased()
        
        switch fileExtension {
        case "pdf":
            return try await parser.parsePDF(data: data, fileName: fileName, as: type)
        case "jpg", "jpeg", "png", "gif", "webp", "heic", "heif":
            return try await parser.parseImage(data: data, fileName: fileName, as: type)
        default:
            throw LLMKitError.unsupportedFileType("File type '\(fileExtension)' is not supported. Supported types: PDF, JPEG, PNG, GIF, WebP, HEIC, HEIF")
        }
    }
    
    public func parseDocument<T: ParseableModel>(from url: URL, as type: T.Type) async throws -> T {
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "pdf":
            return try await parser.parsePDF(from: url, as: type)
        case "jpg", "jpeg", "png", "gif", "webp", "heic", "heif":
            let fileData = try Data(contentsOf: url)
            let fileName = url.lastPathComponent
            return try await parseDocument(data: fileData, fileName: fileName, as: type)
        default:
            throw LLMKitError.unsupportedFileType("File type '\(fileExtension)' is not supported. Supported types: PDF, JPEG, PNG, GIF, WebP, HEIC, HEIF")
        }
    }
    
    // MARK: - File Type Support
    
    public func isFileTypeSupported(_ url: URL) -> Bool {
        let fileExtension = url.pathExtension.lowercased()
        let supportedTypes = ["pdf", "jpg", "jpeg", "png", "gif", "webp", "heic", "heif"]
        return supportedTypes.contains(fileExtension)
    }
    
    public func getParsingMethod(for url: URL) -> ParsingMethod? {
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "pdf":
            return .pdfFileUpload
        case "jpg", "jpeg", "png", "gif", "webp", "heic", "heif":
            return .directVision
        default:
            return nil
        }
    }
}

//
//  DocumentParser.swift
//  LLMKit
//
//  Created by Mayank Gandhi on 05/08/25.
//  Copyright © 2025 m. All rights reserved.
//

import Foundation

/// Unified document parser that handles both OpenAI and Claude parsing
class DocumentParser: DocumentParserProtocol {
    
    // MARK: - Properties
    
    private var openAIClient: OpenAINetworkClientProtocol?
    private var claudeClient: ClaudeNetworkClientProtocol?
    private var claudeFileManager: FileManagerProtocol?
    private var currentServiceType: ServiceType
    private let jsonDecoder: JSONDecoder
    private let jsonParser: JSONResponseParser
    
    // MARK: - Initialization
    
    init(claudeKey: String) {
        let client = ClaudeNetworkClient(apiKey: claudeKey)
        self.claudeClient = client
        self.claudeFileManager = ClaudeFileManager(networkClient: client)
        self.currentServiceType = .claude
        self.jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601
        self.jsonParser = JSONResponseParser(jsonDecoder: jsonDecoder)
    }
    
    init(openAIKey: String) {
        self.openAIClient = OpenAINetworkClient(apiKey: openAIKey)
        self.currentServiceType = .openAI
        self.jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601
        self.jsonParser = JSONResponseParser(jsonDecoder: jsonDecoder)
    }
    
    // MARK: - Dependency Injection Initializers
    
    init(
        claudeClient: ClaudeNetworkClientProtocol?,
        claudeFileManager: FileManagerProtocol?,
        openAIClient: OpenAINetworkClientProtocol?,
        serviceType: ServiceType
    ) {
        self.claudeClient = claudeClient
        self.claudeFileManager = claudeFileManager
        self.openAIClient = openAIClient
        self.currentServiceType = serviceType
        self.jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601
        self.jsonParser = JSONResponseParser(jsonDecoder: jsonDecoder)
    }
    
    // MARK: - Configuration
    
    func configure(serviceType: ServiceType) {
        self.currentServiceType = serviceType
    }
    
    func setClaudeKey(_ key: String) {
        let client = ClaudeNetworkClient(apiKey: key)
        self.claudeClient = client
        self.claudeFileManager = ClaudeFileManager(networkClient: client)
    }
    
    func setOpenAIKey(_ key: String) {
        self.openAIClient = OpenAINetworkClient(apiKey: key)
    }
    
    // MARK: - Image Parsing

    func parseImage<T: ParseableModel>(
        data: Data,
        fileName: String,
        as type: T.Type
    ) async throws -> T {
        switch currentServiceType {
        case .claude:
            return try await parseImageWithClaude(data: data, fileName: fileName, as: type)
        case .openAI:
            return try await parseImageWithOpenAI(data: data, fileName: fileName, as: type)
        }
    }
    
    private func parseImageWithClaude<T: ParseableModel>(
        data: Data,
        fileName: String,
        as type: T.Type
    ) async throws -> T {
        guard let claudeClient = claudeClient else {
            throw LLMKitError.invalidAPIKey
        }
        
        let base64Data = data.base64EncodedString()
        let mimeType = MimeTypeResolver.mimeType(for: fileName)

        let prompt = """
        Please analyze this document and extract the information into the following JSON structure.
        Return ONLY JSON and nothing else. Ensure that the values are properly cased as per the data: upper cased, lower cased, etc.
        Make sure the data is grammatically correct.
        \(T.parseDefinition)
        The response is directly decoded by the same model shared.
        """

        let messageRequest = ClaudeMessageRequest(
            model: "claude-sonnet-4-20250514",
            maxTokens: 4096,
            tools: [type.tool],
            toolChoice: type.toolChoice,
            messages: [
                ClaudeMessage(
                    role: "user",
                    content: [
                        .text(ClaudeTextContent(text: prompt)),
                        .image(ClaudeImageContent(mediaType: mimeType, data: base64Data))
                    ]
                )
            ]
        )

        let requestData = try JSONEncoder().encode(messageRequest)
        let request = try claudeClient.createMessageRequest(endpoint: "messages", body: requestData)
        let (data, httpResponse) = try await claudeClient.executeRequest(request)

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw LLMKitError.parsingError(errorMessage)
        }

        let messageResponse = try jsonDecoder.decode(
            ClaudeMessageResponse<T>.self,
            from: data
        )
        return try jsonParser.parseClaudeResponse(messageResponse, as: type)
    }
    
    private func parseImageWithOpenAI<T: ParseableModel>(
        data: Data,
        fileName: String,
        as type: T.Type
    ) async throws -> T {
        guard let openAIClient = openAIClient else {
            throw LLMKitError.invalidAPIKey
        }
        // TODO: Implement OpenAI image parsing
        throw LLMKitError.unsupportedFileType("OpenAI image parsing not yet implemented")
    }
    
    // MARK: - PDF Parsing
    
    func parsePDF<T: ParseableModel>(
        data: Data, 
        fileName: String, 
        as type: T.Type
    ) async throws -> T {
        switch currentServiceType {
        case .claude:
            return try await parsePDFWithClaude(data: data, fileName: fileName, as: type)
        case .openAI:
            return try await parsePDFWithOpenAI(data: data, fileName: fileName, as: type)
        }
    }
    
    func parsePDF<T: ParseableModel>(
        from url: URL, 
        as type: T.Type
    ) async throws -> T {
        switch currentServiceType {
        case .claude:
            return try await parsePDFWithClaude(from: url, as: type)
        case .openAI:
            return try await parsePDFWithOpenAI(from: url, as: type)
        }
    }
    
    private func parsePDFWithClaude<T: ParseableModel>(
        data: Data, 
        fileName: String, 
        as type: T.Type
    ) async throws -> T {
        guard let claudeFileManager = claudeFileManager else {
            throw LLMKitError.invalidAPIKey
        }
        
        var fileID: String?
        do {
            // Upload file to Claude
            let uploadResponse = try await claudeFileManager.uploadFile(data: data, fileName: fileName)
            fileID = uploadResponse.id
            // Parse using Claude
            let result = try await parseWithClaude(fileId: uploadResponse.id, as: type)
            
            // Clean up uploaded file
            try await claudeFileManager.deleteDocument(fileId: uploadResponse.id)
            
            return result
        } catch {
            if let fileID = fileID {
                try? await claudeFileManager.deleteDocument(fileId: fileID)
            }
            throw error
        }
    }
    
    private func parsePDFWithClaude<T: ParseableModel>(
        from url: URL, 
        as type: T.Type
    ) async throws -> T {
        guard let claudeFileManager = claudeFileManager else {
            throw LLMKitError.invalidAPIKey
        }
        
        let uploadResponse = try await claudeFileManager.uploadDocument(at: url)
        let result = try await parseWithClaude(fileId: uploadResponse.id, as: type)
        try await claudeFileManager.deleteDocument(fileId: uploadResponse.id)
        return result
    }
    
    private func parsePDFWithOpenAI<T: ParseableModel>(
        data: Data, 
        fileName: String, 
        as type: T.Type
    ) async throws -> T {
        // TODO: Implement OpenAI PDF parsing
        throw LLMKitError.unsupportedFileType("OpenAI PDF parsing not yet implemented")
    }
    
    private func parsePDFWithOpenAI<T: ParseableModel>(
        from url: URL, 
        as type: T.Type
    ) async throws -> T {
        // TODO: Implement OpenAI PDF parsing
        throw LLMKitError.unsupportedFileType("OpenAI PDF parsing not yet implemented")
    }
    
    // MARK: - Private Helpers
    
    private func parseWithClaude<T: ParseableModel>(fileId: String, as type: T.Type) async throws -> T {
        guard let claudeClient = claudeClient else {
            throw LLMKitError.invalidAPIKey
        }
        
        let prompt = """
        Please analyze this document and extract the information into the following JSON structure. 
        Return ONLY JSON and nothing else. Ensure that the values are properly cased as per the data: upper cased, lower cased, etc. 
        Make sure the data is grammatically correct. 
        \(T.parseDefinition)
        The response is directly decoded by the same model shared.
        """
        
        let messageRequest = ClaudeMessageRequest(
            model: "claude-sonnet-4-20250514",
            maxTokens: 4096,
            tools: [type.tool],
            toolChoice: type.toolChoice,
            messages: [
                ClaudeMessage(
                    role: "user",
                    content: [
                        .text(ClaudeTextContent(text: prompt)),
                        .document(ClaudeDocumentContent(fileId: fileId, citations: ClaudeCitations(enabled: true)))
                    ]
                )
            ]
        )
        
        let requestData = try JSONEncoder().encode(messageRequest)
        let request = try claudeClient.createMessageRequest(endpoint: "messages", body: requestData)
        let (data, httpResponse) = try await claudeClient.executeRequest(request)
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw LLMKitError.parsingError(errorMessage)
        }
        
        let messageResponse = try jsonDecoder.decode(
            ClaudeMessageResponse<T>.self,
            from: data
        )
        return try jsonParser.parseClaudeResponse(messageResponse, as: type)
    }
    
    // MARK: - File Type Support
    
    func isImageFile(fileName: String) -> Bool {
        let pathExtension = (fileName as NSString).pathExtension.lowercased()
        let supportedImageTypes = ["jpg", "jpeg", "png", "gif", "webp", "heic", "heif"]
        return supportedImageTypes.contains(pathExtension)
    }
    
    func isPDFFile(fileName: String) -> Bool {
        let pathExtension = (fileName as NSString).pathExtension.lowercased()
        return pathExtension == "pdf"
    }
}

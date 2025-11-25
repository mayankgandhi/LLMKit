//
//  DocumentParser.swift
//  LLMKit
//
//  Created by Mayank Gandhi on 05/08/25.
//  Copyright © 2025 m. All rights reserved.
//

import Foundation

/// Unified document parser that handles both OpenAI and Claude parsing
final class DocumentParser {
    
    // MARK: - Properties
    
    private let openAIClient: OpenAINetworkClient
    private let claudeClient: ClaudeNetworkClient
    private let claudeFileManager: ClaudeFileManager
    private let jsonDecoder: JSONDecoder
    private let jsonParser: JSONResponseParser
    
    // MARK: - Initialization
    
    init(openAIKey: String, claudeKey: String) {
        self.openAIClient = OpenAINetworkClient(apiKey: openAIKey)
        self.claudeClient = ClaudeNetworkClient(apiKey: claudeKey)
        self.claudeFileManager = ClaudeFileManager(networkClient: claudeClient)
        self.jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601
        self.jsonParser = JSONResponseParser(jsonDecoder: jsonDecoder)
    }
    
    // MARK: - Image Parsing (Claude Vision)

    func parseImage<T: ParseableModel>(
        data: Data,
        fileName: String,
        as type: T.Type
    ) async throws -> T {
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
    
    // MARK: - PDF Parsing (Claude with file upload)
    
    func parsePDF<T: ParseableModel>(
        data: Data, 
        fileName: String, 
        as type: T.Type
    ) async throws -> T {
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
            if fileID != nil {
                try await claudeFileManager.deleteDocument(fileId: fileID!)
            }
            throw error
        }
    }
    
    func parsePDF<T: ParseableModel>(
        from url: URL, 
        as type: T.Type
    ) async throws -> T {
        let uploadResponse = try await claudeFileManager.uploadDocument(at: url)
        let result = try await parseWithClaude(fileId: uploadResponse.id, as: type)
        try await claudeFileManager.deleteDocument(fileId: uploadResponse.id)
        return result
    }
    
    // MARK: - Private Helpers
    
    private func parseWithClaude<T: ParseableModel>(fileId: String, as type: T.Type) async throws -> T {
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

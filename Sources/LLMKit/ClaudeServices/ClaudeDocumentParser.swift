//
//  ClaudeDocumentParser.swift
//  LLMKit
//
//  Created by Mayank Gandhi on 05/08/25.
//  Copyright © 2025 m. All rights reserved.
//

import Foundation

/// Claude-specific implementation of document parsing
final class ClaudeDocumentParser: ClaudeDocumentParserProtocol {

    // MARK: - Properties

    private let claudeClient: ClaudeNetworkClientProtocol
    private let claudeFileManager: FileManagerProtocol
    private let jsonDecoder: JSONDecoder
    private let jsonParser: JSONResponseParser

    var providerName: String { "Claude" }

    // MARK: - Initialization

    init(apiKey: String) {
        let client = ClaudeNetworkClient(apiKey: apiKey)
        self.claudeClient = client
        self.claudeFileManager = ClaudeFileManager(networkClient: client)
        self.jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601
        self.jsonParser = JSONResponseParser(jsonDecoder: jsonDecoder)
    }

    // For testing with dependency injection
    init(
        claudeClient: ClaudeNetworkClientProtocol,
        claudeFileManager: FileManagerProtocol,
        jsonDecoder: JSONDecoder = JSONDecoder(),
        jsonParser: JSONResponseParser? = nil
    ) {
        self.claudeClient = claudeClient
        self.claudeFileManager = claudeFileManager
        self.jsonDecoder = jsonDecoder
        jsonDecoder.dateDecodingStrategy = .iso8601
        self.jsonParser = jsonParser ?? JSONResponseParser(jsonDecoder: jsonDecoder)
    }

    // MARK: - DocumentParserProtocol

    func parseImage<T: ClaudeParseableModel>(
        data: Data,
        fileName: String,
        as type: T.Type
    ) async throws -> T {
        return try await parseImageRequest(data: data, fileName: fileName, as: type)
    }

    func parsePDF<T: ClaudeParseableModel>(
        data: Data,
        fileName: String,
        as type: T.Type
    ) async throws -> T {
        return try await parsePDFRequest(data: data, fileName: fileName, as: type)
    }

    func parsePDF<T: ClaudeParseableModel>(
        from url: URL,
        as type: T.Type
    ) async throws -> T {
        return try await parsePDFRequest(from: url, as: type)
    }

    func isImageFile(fileName: String) -> Bool {
        return FileTypeUtils.isImageFile(fileName: fileName)
    }

    func isPDFFile(fileName: String) -> Bool {
        return FileTypeUtils.isPDFFile(fileName: fileName)
    }

    func query<T: ClaudeParseableModel>(prompt: String, as type: T.Type) async throws -> T {
        return try await queryWithPrompt(prompt: prompt, as: type)
    }

    // MARK: - Private Implementation - Query

    private func parseImageRequest<T: ClaudeParseableModel>(
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

    // MARK: - Private Implementation - PDF Parsing

    private func parsePDFRequest<T: ClaudeParseableModel>(
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
            let result = try await parseWithFileUpload(fileId: uploadResponse.id, as: type)

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

    private func parsePDFRequest<T: ClaudeParseableModel>(
        from url: URL,
        as type: T.Type
    ) async throws -> T {
        let uploadResponse = try await claudeFileManager.uploadDocument(at: url)
        let result = try await parseWithFileUpload(fileId: uploadResponse.id, as: type)
        try await claudeFileManager.deleteDocument(fileId: uploadResponse.id)
        return result
    }

    // MARK: - Private Helpers

    private func parseWithFileUpload<T: ClaudeParseableModel>(fileId: String, as type: T.Type) async throws -> T {
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

    private func queryWithPrompt<T: ClaudeParseableModel>(prompt: String, as type: T.Type) async throws -> T {
        let systemPrompt = """
        Extract the requested information from the user's query and return it in the following JSON structure.
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
                        .text(ClaudeTextContent(text: "\(systemPrompt)\n\nUser Query: \(prompt)"))
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
}

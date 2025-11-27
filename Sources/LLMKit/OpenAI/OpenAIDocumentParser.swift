//
//  OpenAIDocumentParser.swift
//  LLMKit
//
//  Created by Mayank Gandhi on 05/08/25.
//  Copyright © 2025 m. All rights reserved.
//

import Foundation

/// OpenAI-specific implementation of document parsing
final class OpenAIDocumentParser: DocumentParserProtocol {

    // MARK: - Properties

    private let openAIClient: OpenAINetworkClientProtocol
    private let jsonDecoder: JSONDecoder
    private let jsonParser: JSONResponseParser

    var providerName: String { "OpenAI" }

    // MARK: - Initialization

    init(apiKey: String) {
        self.openAIClient = OpenAINetworkClient(apiKey: apiKey)
        self.jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601
        self.jsonParser = JSONResponseParser(jsonDecoder: jsonDecoder)
    }

    // For testing with dependency injection
    init(
        openAIClient: OpenAINetworkClientProtocol,
        jsonDecoder: JSONDecoder = JSONDecoder(),
        jsonParser: JSONResponseParser? = nil
    ) {
        self.openAIClient = openAIClient
        self.jsonDecoder = jsonDecoder
        jsonDecoder.dateDecodingStrategy = .iso8601
        self.jsonParser = jsonParser ?? JSONResponseParser(jsonDecoder: jsonDecoder)
    }

    // MARK: - DocumentParserProtocol

    func parseImage<T: ParseableModel>(
        data: Data,
        fileName: String,
        as type: T.Type
    ) async throws -> T {
        // TODO: Implement OpenAI image parsing
        throw LLMKitError.unsupportedFileType("OpenAI image parsing not yet implemented")
    }

    func parsePDF<T: ParseableModel>(
        data: Data,
        fileName: String,
        as type: T.Type
    ) async throws -> T {
        // TODO: Implement OpenAI PDF parsing
        throw LLMKitError.unsupportedFileType("OpenAI PDF parsing not yet implemented")
    }

    func parsePDF<T: ParseableModel>(
        from url: URL,
        as type: T.Type
    ) async throws -> T {
        // TODO: Implement OpenAI PDF parsing
        throw LLMKitError.unsupportedFileType("OpenAI PDF parsing not yet implemented")
    }

    func isImageFile(fileName: String) -> Bool {
        return FileTypeUtils.isImageFile(fileName: fileName)
    }

    func isPDFFile(fileName: String) -> Bool {
        return FileTypeUtils.isPDFFile(fileName: fileName)
    }
}

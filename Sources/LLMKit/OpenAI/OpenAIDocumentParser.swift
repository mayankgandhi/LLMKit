//
//  OpenAIDocumentParser.swift
//  LLMKit
//
//  Created by Mayank Gandhi on 05/08/25.
//  Copyright © 2025 m. All rights reserved.
//

import Foundation

/// OpenAI-specific implementation of document parsing
final class OpenAIDocumentParser: OpenAIDocumentParserProtocol {

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

    func parseImage<T: OpenAIParseableModel>(
        data: Data,
        fileName: String,
        as type: T.Type
    ) async throws -> T {
        // TODO: Implement OpenAI image parsing
        throw LLMKitError.unsupportedFileType("OpenAI image parsing not yet implemented")
    }

    func parsePDF<T: OpenAIParseableModel>(
        data: Data,
        fileName: String,
        as type: T.Type
    ) async throws -> T {
        // TODO: Implement OpenAI PDF parsing
        throw LLMKitError.unsupportedFileType("OpenAI PDF parsing not yet implemented")
    }

    func parsePDF<T: OpenAIParseableModel>(
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

    func query<T: OpenAIParseableModel>(prompt: String, as type: T.Type) async throws -> T {
        let systemPrompt = """
        Extract the requested information from the user's query and return it in the following JSON structure.
        Return ONLY JSON and nothing else. Ensure that the values are properly cased as per the data: upper cased, lower cased, etc.
        Make sure the data is grammatically correct.
        \(T.parseDefinition)
        The response is directly decoded by the same model shared.
        """

        let messages = [
            OpenAIMessage(
                role: "system",
                content: [
                    .text(OpenAITextContent(text: systemPrompt))
                ]
            ),
            OpenAIMessage(
                role: "user",
                content: [
                    .text(OpenAITextContent(text: prompt))
                ]
            )
        ]

        let responseRequest = OpenAIResponseRequest(
            model: "gpt-4.1-mini",
            input: messages,
            temperature: 0,
            maxOutputTokens: 1024,
            text: OpenAITextResponseOptions(
                format: "json_schema",
                jsonSchema: OpenAIJSONSchemaWrapper(
                    name: String(describing: T.self),
                    schema: T.jsonSchema
                )
            )
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let requestData = try encoder.encode(responseRequest)
        let request = try openAIClient.createChatRequest(endpoint: "responses", body: requestData)
        let (data, httpResponse) = try await openAIClient.executeRequest(request)

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw LLMKitError.parsingError(errorMessage)
        }

        let response = try jsonDecoder.decode(OpenAIResponse.self, from: data)
        guard let jsonString = OpenAIResponseExtractor.extractStructuredJSON(from: response) else {
            throw LLMKitError.parsingError("OpenAI response did not contain structured JSON output")
        }

        return try jsonParser.parseJSONString(jsonString, as: type)
    }
}

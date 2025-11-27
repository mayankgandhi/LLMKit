//
//  Protocols.swift
//  LLMKit
//
//  Created by Mayank Gandhi on 05/08/25.
//  Copyright © 2025 m. All rights reserved.
//

import Foundation

// MARK: - Core Protocols

/// Base protocol for all parseable models
public protocol ParseableModel: Codable {
    static var parseDefinition: String { get }
}

/// Protocol for OpenAI-specific parseable models
public protocol OpenAIParseableModel: ParseableModel {
    static var jsonSchema: OpenAIJSONSchema { get }
}

/// Protocol for Claude-specific parseable models
public protocol ClaudeParseableModel: ParseableModel {
    static var tool: ClaudeTool { get }
    static var toolChoice: ToolChoice { get }
}

/// Base protocol for AI document parsing services
public protocol DocumentParsingService {
    /// Check if a file type is supported
    func isFileTypeSupported(_ url: URL) -> Bool

    /// Get the parsing method for a file
    func getParsingMethod(for url: URL) -> ParsingMethod?
}

/// Protocol for OpenAI document parsing services
public protocol OpenAIDocumentParsingService: DocumentParsingService {
    /// Parse a document using direct data and filename
    func parseDocument<T: OpenAIParseableModel>(data: Data, fileName: String, as type: T.Type) async throws -> T

    /// Parse a document from file URL
    func parseDocument<T: OpenAIParseableModel>(from url: URL, as type: T.Type) async throws -> T

    /// Query the AI with a prompt and get a structured response
    func query<T: OpenAIParseableModel>(prompt: String, as type: T.Type) async throws -> T
}

/// Protocol for Claude document parsing services
public protocol ClaudeDocumentParsingService: DocumentParsingService {
    /// Parse a document using direct data and filename
    func parseDocument<T: ClaudeParseableModel>(data: Data, fileName: String, as type: T.Type) async throws -> T

    /// Parse a document from file URL
    func parseDocument<T: ClaudeParseableModel>(from url: URL, as type: T.Type) async throws -> T

    /// Query the AI with a prompt and get a structured response
    func query<T: ClaudeParseableModel>(prompt: String, as type: T.Type) async throws -> T
}

// MARK: - Internal Service Protocols

/// Protocol for network clients that handle HTTP communication
protocol NetworkClientProtocol {
    var apiKey: String { get }
    func executeRequest(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
    func performNetworkRequest(for request: URLRequest) async throws -> Data
}

/// Protocol for Claude-specific network operations
protocol ClaudeNetworkClientProtocol: NetworkClientProtocol {
    func createFileUploadRequest(endpoint: String, body: Data, contentType: String) throws -> URLRequest
    func createMessageRequest(endpoint: String, body: Data) throws -> URLRequest
    func createDeleteRequest(endpoint: String) throws -> URLRequest
}

/// Protocol for OpenAI-specific network operations
protocol OpenAINetworkClientProtocol: NetworkClientProtocol {
    func createChatRequest(endpoint: String, body: Data) throws -> URLRequest
}

/// Protocol for file management operations
protocol FileManagerProtocol {
    func uploadFile(data: Data, fileName: String) async throws -> ClaudeFileUploadResponse
    func uploadDocument(at url: URL) async throws -> ClaudeFileUploadResponse
    func deleteDocument(fileId: String) async throws
}

/// Protocol for document parsing operations
public protocol DocumentParserProtocol {
    var providerName: String { get }
    func isImageFile(fileName: String) -> Bool
    func isPDFFile(fileName: String) -> Bool
}

/// Protocol for OpenAI document parsing operations
protocol OpenAIDocumentParserProtocol: DocumentParserProtocol {
    func parseImage<T: OpenAIParseableModel>(data: Data, fileName: String, as type: T.Type) async throws -> T
    func parsePDF<T: OpenAIParseableModel>(data: Data, fileName: String, as type: T.Type) async throws -> T
    func parsePDF<T: OpenAIParseableModel>(from url: URL, as type: T.Type) async throws -> T
    func query<T: OpenAIParseableModel>(prompt: String, as type: T.Type) async throws -> T
}

/// Protocol for Claude document parsing operations
protocol ClaudeDocumentParserProtocol: DocumentParserProtocol {
    func parseImage<T: ClaudeParseableModel>(data: Data, fileName: String, as type: T.Type) async throws -> T
    func parsePDF<T: ClaudeParseableModel>(data: Data, fileName: String, as type: T.Type) async throws -> T
    func parsePDF<T: ClaudeParseableModel>(from url: URL, as type: T.Type) async throws -> T
    func query<T: ClaudeParseableModel>(prompt: String, as type: T.Type) async throws -> T
}

/// Protocol for creating document parsers
protocol DocumentParserFactoryProtocol {
    func createClaudeParser(apiKey: String) -> DocumentParserProtocol
    func createOpenAIParser(apiKey: String) -> DocumentParserProtocol
}

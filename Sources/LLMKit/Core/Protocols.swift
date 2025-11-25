//
//  Protocols.swift
//  LLMKit
//
//  Created by Mayank Gandhi on 05/08/25.
//  Copyright © 2025 m. All rights reserved.
//

import Foundation

// MARK: - Core Protocols

public protocol ParseableModel: Codable {
    static var parseDefinition: String { get }
    static var jsonSchema: OpenAIJSONSchema { get }
    static var tool: ClaudeTool { get }
    static var toolChoice: ToolChoice { get }
}

/// Simple protocol for AI document parsing services
public protocol DocumentParsingService {
    /// Parse a document using direct data and filename
    func parseDocument<T: ParseableModel>(data: Data, fileName: String, as type: T.Type) async throws -> T
    
    /// Parse a document from file URL
    func parseDocument<T: ParseableModel>(from url: URL, as type: T.Type) async throws -> T
    
    /// Check if a file type is supported
    func isFileTypeSupported(_ url: URL) -> Bool
    
    /// Get the parsing method for a file
    func getParsingMethod(for url: URL) -> ParsingMethod?
}

//
//  ClaudeFileUploadResponse.swift
//  Walnut
//
//  Created by Mayank Gandhi on 08/07/25.
//  Copyright © 2025 m. All rights reserved.
//


import Foundation

// MARK: - Models

struct ClaudeFileUploadResponse: Codable {
    let id: String
}

// MARK: - Tool
public struct ClaudeTool: Codable {
    let name, description: String
    let inputSchema: ClaudeInputSchema
    
    public init(name: String, description: String, inputSchema: ClaudeInputSchema) {
        self.name = name
        self.description = description
        self.inputSchema = inputSchema
    }

    enum CodingKeys: String, CodingKey {
        case name, description
        case inputSchema = "input_schema"
    }
}

// MARK: - ToolChoice
public struct ToolChoice: Codable {
    let type, name: String
    
    public init(type: String, name: String) {
        self.type = type
        self.name = name
    }
}


// MARK: - InputSchema
public struct ClaudeInputSchema: Codable {
    let type: String
    let properties: [String: Any]
    let required: [String]
    
    public init(
        type: String,
        properties: [String: Any],
        required: [String]
    ) {
        self.type = type
        self.properties = properties
        self.required = required
    }

    enum CodingKeys: String, CodingKey {
        case type, properties
        case required = "required"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(required, forKey: .required)
        
        let jsonData = try JSONSerialization.data(withJSONObject: properties)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        try container.encode(AnyCodable(jsonObject), forKey: .properties)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        required = try container.decode([String].self, forKey: .required)
        let anyCodable = try container.decode(AnyCodable.self, forKey: .properties)
        properties = anyCodable.value as? [String: AnyCodable] ?? [:]
    }
}

struct ClaudeMessageRequest: Codable {
    let model: String
    let maxTokens: Int
    let tools: [ClaudeTool]
    let toolChoice: ToolChoice
    let messages: [ClaudeMessage]

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case tools
        case toolChoice = "tool_choice"
        case messages
    }
}


struct ClaudeMessage: Codable {
    let role: String
    let content: [ClaudeContent]
}

enum ClaudeContent: Codable {
    case text(ClaudeTextContent)
    case document(ClaudeDocumentContent)
    case image(ClaudeImageContent)

    private enum CodingKeys: String, CodingKey {
        case type
    }

    private enum ContentType: String, Codable {
        case text, document, image
    }
    
    func encode(to encoder: Encoder) throws {
        switch self {
        case .text(let content):
            try content.encode(to: encoder)
        case .document(let content):
            try content.encode(to: encoder)
        case .image(let content):
            try content.encode(to: encoder)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ContentType.self, forKey: .type)
        
        switch type {
        case .text:
            let content = try ClaudeTextContent(from: decoder)
            self = .text(content)
        case .document:
            let content = try ClaudeDocumentContent(from: decoder)
            self = .document(content)
        case .image:
            let content = try ClaudeImageContent(from: decoder)
            self = .image(content)
        }
    }
}

struct ClaudeTextContent: Codable {
    let type: String
    let text: String

    init(text: String) {
        self.type = "text"
        self.text = text
    }
}

struct ClaudeDocumentContent: Codable {
    let type: String
    let source: ClaudeFileSource
    let title: String?
    let context: String?
    let citations: ClaudeCitations?

    init(fileId: String, title: String? = nil, context: String? = nil, citations: ClaudeCitations? = nil) {
        self.type = "document"
        self.source = ClaudeFileSource(fileId: fileId)
        self.title = title
        self.context = context
        self.citations = citations
    }
}

struct ClaudeFileSource: Codable {
    let type: String
    let fileId: String

    init(fileId: String) {
        self.type = "file"
        self.fileId = fileId
    }

    enum CodingKeys: String, CodingKey {
        case type
        case fileId = "file_id"
    }
}

struct ClaudeCitations: Codable {
    let enabled: Bool
}

struct ClaudeImageContent: Codable {
    let type: String
    let source: ClaudeImageSource

    init(mediaType: String, data: String) {
        self.type = "image"
        self.source = ClaudeImageSource(mediaType: mediaType, data: data)
    }
}

struct ClaudeImageSource: Codable {
    let type: String
    let mediaType: String
    let data: String

    init(mediaType: String, data: String) {
        self.type = "base64"
        self.mediaType = mediaType
        self.data = data
    }

    enum CodingKeys: String, CodingKey {
        case type
        case mediaType = "media_type"
        case data
    }
}

struct ClaudeMessageResponse<T: Codable>: Codable {
    let id: String
    let type: String
    let role: String
    let model: String
    let content: [ClaudeResponseContent<T>]
    
    enum CodingKeys: String, CodingKey {
        case id, type, role, model, content
    }
}

struct ClaudeResponseContent<T: Codable>: Codable {
    let type: String
    let text: String?
    let input: T?
}

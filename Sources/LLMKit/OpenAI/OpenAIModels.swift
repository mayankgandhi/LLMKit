//
//  OpenAIModels.swift
//  LLMKit
//
//  Created by Mayank Gandhi on 05/08/25.
//  Copyright © 2025 m. All rights reserved.
//

import Foundation

// MARK: - OpenAI-specific Protocol Extension
// MARK: - File Upload Models

public struct OpenAIFileUploadResponse: Codable {
    public let id: String
    public let object: String
    public let bytes: Int
    public let createdAt: Int
    public let filename: String
    public let purpose: String
    
    enum CodingKeys: String, CodingKey {
        case id, object, bytes, filename, purpose
        case createdAt = "created_at"
    }
}

// MARK: - Chat API Models

public struct OpenAIChatRequest: Codable {
    public let model: String
    public let messages: [OpenAIMessage]
    public let maxTokens: Int?
    public let temperature: Double?
    public let responseFormat: OpenAIResponseFormat?
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
        case responseFormat = "response_format"
    }
    
    public init(model: String, messages: [OpenAIMessage], maxTokens: Int? = nil, temperature: Double? = nil, responseFormat: OpenAIResponseFormat? = nil) {
        self.model = model
        self.messages = messages
        self.maxTokens = maxTokens
        self.temperature = temperature
        self.responseFormat = responseFormat
    }
}

public struct OpenAIMessage: Codable {
    public let role: String
    public let content: [OpenAIMessageContent]
    
    public init(role: String, content: [OpenAIMessageContent]) {
        self.role = role
        self.content = content
    }
}

public enum OpenAIMessageContent: Codable {
    case text(OpenAITextContent)
    case imageUrl(OpenAIImageContent)
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    private enum ContentType: String, Codable {
        case text
        case imageUrl = "image_url"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ContentType.self, forKey: .type)
        
        switch type {
        case .text:
            let textContent = try OpenAITextContent(from: decoder)
            self = .text(textContent)
        case .imageUrl:
            let imageContent = try OpenAIImageContent(from: decoder)
            self = .imageUrl(imageContent)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .text(let textContent):
            try textContent.encode(to: encoder)
        case .imageUrl(let imageContent):
            try imageContent.encode(to: encoder)
        }
    }
}

public struct OpenAITextContent: Codable {
    public let type: String
    public let text: String

    public init(text: String) {
        self.type = "input_text"
        self.text = text
    }
}

public struct OpenAIImageContent: Codable {
    public let type: String
    public let imageUrl: OpenAIImageUrl
    
    enum CodingKeys: String, CodingKey {
        case type
        case imageUrl = "image_url"
    }
    
    public init(imageUrl: OpenAIImageUrl) {
        self.type = "image_url"
        self.imageUrl = imageUrl
    }
}

public struct OpenAIImageUrl: Codable {
    public let url: String
    public let detail: String?
    
    public init(url: String, detail: String? = "high") {
        self.url = url
        self.detail = detail
    }
}

public struct OpenAIResponseFormat: Codable {
    public let type: String

    public init(type: String = "json_object") {
        self.type = type
    }
}

public struct OpenAITextResponseOptions: Codable {
    public let format: OpenAITextFormat

    public init(format: OpenAITextFormat) {
        self.format = format
    }
}

public struct OpenAITextFormat: Codable {
    public let type: String
    public let name: String
    public let schema: OpenAIJSONSchema
    public let strict: Bool

    public init(type: String = "json_schema", name: String, schema: OpenAIJSONSchema, strict: Bool = true) {
        self.type = type
        self.name = name
        self.schema = schema
        self.strict = strict
    }
}

// MARK: - Responses API Models

public struct OpenAIResponseRequest: Codable {
    public let model: String
    public let input: [OpenAIMessage]
    public let temperature: Double?
    public let maxOutputTokens: Int?
    public let text: OpenAITextResponseOptions?

    enum CodingKeys: String, CodingKey {
        case model, input, temperature, text
        case maxOutputTokens = "max_output_tokens"
    }

    public init(
        model: String,
        input: [OpenAIMessage],
        temperature: Double? = nil,
        maxOutputTokens: Int? = nil,
        text: OpenAITextResponseOptions? = nil
    ) {
        self.model = model
        self.input = input
        self.temperature = temperature
        self.maxOutputTokens = maxOutputTokens
        self.text = text
    }
}

public struct OpenAIResponse: Codable {
    public let id: String
    public let object: String
    public let created: Int
    public let model: String
    public let status: String
    public let output: [OpenAIResponseOutput]?
    public let outputText: [String]?
    public let usage: OpenAIResponseUsage?
    public let metadata: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case id, object, created, model, status, output, usage, metadata
        case outputText = "output_text"
    }
}

public struct OpenAIResponseOutput: Codable {
    public let id: String
    public let type: String
    public let status: String?
    public let role: String?
    public let content: [OpenAIResponseOutputContent]
    public let stopReason: String?

    enum CodingKeys: String, CodingKey {
        case id, type, status, role, content
        case stopReason = "stop_reason"
    }
}

public struct OpenAIResponseOutputContent: Codable {
    public let type: String
    public let text: String?
    public let annotations: [String: AnyCodable]?
}

public struct OpenAIResponseUsage: Codable {
    public let inputTokens: Int?
    public let outputTokens: Int?
    public let totalTokens: Int?

    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case totalTokens = "total_tokens"
    }
}

enum OpenAIResponseExtractor {
    static func extractStructuredJSON(from response: OpenAIResponse) -> String? {
        if let outputText = response.outputText?.first,
           outputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            return outputText
        }

        guard let outputs = response.output else {
            return nil
        }

        for output in outputs {
            for content in output.content {
                if let text = content.text,
                   text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                    return text
                }
            }
        }

        return nil
    }
}


// MARK: - JSON Schema Property Type

public indirect enum JSONSchemaProperty {
    case primitive(type: String, description: String? = nil, pattern: String? = nil, format: String? = nil, minimum: Int? = nil, maximum: Int? = nil)
    case object(type: String, description: String? = nil, properties: [String: JSONSchemaProperty], required: [String]? = nil, additionalProperties: Bool? = nil)
    case array(type: String, description: String? = nil, items: JSONSchemaProperty)

    public var type: String {
        switch self {
        case .primitive(let type, _, _, _, _, _),
             .object(let type, _, _, _, _),
             .array(let type, _, _):
            return type
        }
    }

    public var description: String? {
        switch self {
        case .primitive(_, let description, _, _, _, _),
             .object(_, let description, _, _, _),
             .array(_, let description, _):
            return description
        }
    }

    public static func string(description: String? = nil, pattern: String? = nil, format: String? = nil) -> JSONSchemaProperty {
        .primitive(type: "string", description: description, pattern: pattern, format: format)
    }

    public static func integer(description: String? = nil, minimum: Int? = nil, maximum: Int? = nil) -> JSONSchemaProperty {
        .primitive(type: "integer", description: description, minimum: minimum, maximum: maximum)
    }

    public static func number(description: String? = nil, minimum: Int? = nil, maximum: Int? = nil) -> JSONSchemaProperty {
        .primitive(type: "number", description: description, minimum: minimum, maximum: maximum)
    }

    public static func boolean(description: String? = nil) -> JSONSchemaProperty {
        .primitive(type: "boolean", description: description)
    }

    public static func object(description: String? = nil, properties: [String: JSONSchemaProperty], required: [String]? = nil, additionalProperties: Bool? = nil) -> JSONSchemaProperty {
        .object(type: "object", description: description, properties: properties, required: required, additionalProperties: additionalProperties)
    }

    public static func array(description: String? = nil, items: JSONSchemaProperty) -> JSONSchemaProperty {
        .array(type: "array", description: description, items: items)
    }

    public var asDictionary: [String: Any] {
        var dict: [String: Any] = ["type": type]
        if let description = description { dict["description"] = description }

        switch self {
        case .primitive(_, _, let pattern, let format, let minimum, let maximum):
            if let pattern = pattern { dict["pattern"] = pattern }
            if let format = format { dict["format"] = format }
            if let minimum = minimum { dict["minimum"] = minimum }
            if let maximum = maximum { dict["maximum"] = maximum }

        case .object(_, _, let properties, let required, let additionalProperties):
            dict["properties"] = properties.mapValues { $0.asDictionary }
            if let required = required { dict["required"] = required }
            dict["additionalProperties"] = additionalProperties ?? false

        case .array(_, _, let items):
            dict["items"] = items.asDictionary
        }

        return dict
    }
}

public struct OpenAIJSONSchema: Codable {

    public let type: String = "object"
    public let properties: [String: Any]
    public let required: [String]
    public let additionalProperties: Bool

    enum CodingKeys: String, CodingKey {
        case type, properties, required
        case additionalProperties = "additionalProperties"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(required, forKey: .required)
        try container.encode(additionalProperties, forKey: .additionalProperties)

        let jsonData = try JSONSerialization.data(withJSONObject: properties)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        try container.encode(AnyCodable(jsonObject), forKey: .properties)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        required = try container.decode([String].self, forKey: .required)
        additionalProperties = try container.decode(Bool.self, forKey: .additionalProperties)
        let anyCodable = try container.decode(AnyCodable.self, forKey: .properties)
        properties = anyCodable.value as? [String: AnyCodable] ?? [:]
    }

    public init(
        properties: [String: JSONSchemaProperty],
        required: [String],
        additionalProperties: Bool = false
    ) {
        self.properties = properties.mapValues { $0.asDictionary }
        self.required = required
        self.additionalProperties = additionalProperties
    }

}

public struct AnyCodable: Codable {
    public let value: Any
    
    public init<T>(_ value: T?) {
        self.value = value ?? ()
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            value = ()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            value = ()
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case is Void:
            try container.encodeNil()
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}

public struct OpenAIChatResponse: Codable {
    public let id: String
    public let object: String
    public let created: Int
    public let model: String
    public let choices: [OpenAIChoice]
    public let usage: OpenAIUsage
    public let systemFingerprint: String?
    
    enum CodingKeys: String, CodingKey {
        case id, object, created, model, choices, usage
        case systemFingerprint = "system_fingerprint"
    }
}

public struct OpenAIChoice: Codable {
    public let index: Int
    public let message: OpenAIResponseMessage
    public let logprobs: String?
    public let finishReason: String
    
    enum CodingKeys: String, CodingKey {
        case index, message, logprobs
        case finishReason = "finish_reason"
    }
}

public struct OpenAIResponseMessage: Codable {
    public let role: String
    public let content: String
    public let refusal: String?
}

public struct OpenAIUsage: Codable {
    public let promptTokens: Int
    public let completionTokens: Int
    public let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

// MARK: - Responses API Models

public struct OpenAIResponsePayload: Codable {
    public let id: String
    public let object: String
    public let created: Int
    public let model: String
    public let systemFingerprint: String?
    public let output: [OpenAIResponseOutput]?
    public let outputText: [String]?
    public let usage: OpenAIUsage?
    
    enum CodingKeys: String, CodingKey {
        case id, object, created, model, output, usage
        case systemFingerprint = "system_fingerprint"
        case outputText = "output_text"
    }
}

public struct OpenAIResponseContent: Codable {
    public let type: String
    public let text: String?
}


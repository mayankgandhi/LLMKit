//
//  LLMKitPublic.swift
//  LLMKit
//
//  Created by Mayank Gandhi on 05/08/25.
//  Copyright © 2025 m. All rights reserved.
//

import Foundation

// MARK: - Convenience Factory
/// Factory for creating LLMKit services
public struct LLMKitFactory {

    /// Create a Claude document parsing service
    public static func createClaudeService(apiKey: String) -> ClaudeDocumentParsingServiceImpl {
        return ClaudeDocumentParsingServiceImpl(apiKey: apiKey)
    }

    /// Create an OpenAI document parsing service
    public static func createOpenAIService(apiKey: String) -> OpenAIDocumentParsingServiceImpl {
        return OpenAIDocumentParsingServiceImpl(apiKey: apiKey)
    }

    // MARK: - Deprecated

    /// Create a unified document parsing service configured for Claude
    @available(*, deprecated, renamed: "createClaudeService", message: "Use createClaudeService instead")
    public static func createUnifiedService(claudeKey: String) -> ClaudeDocumentParsingServiceImpl {
        return createClaudeService(apiKey: claudeKey)
    }

    /// Create a unified document parsing service configured for OpenAI
    @available(*, deprecated, renamed: "createOpenAIService", message: "Use createOpenAIService instead")
    public static func createUnifiedService(openAIKey: String) -> OpenAIDocumentParsingServiceImpl {
        return createOpenAIService(apiKey: openAIKey)
    }

}

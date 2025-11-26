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
    
    /// Create a unified document parsing service configured for Claude
    public static func createUnifiedService(claudeKey: String) -> UnifiedDocumentParsingService {
        return UnifiedDocumentParsingService(
            apiKey: claudeKey,
            serviceType: .claude
        )
    }
    
    /// Create a unified document parsing service configured for OpenAI
    public static func createUnifiedService(openAIKey: String) -> UnifiedDocumentParsingService {
        return UnifiedDocumentParsingService(
            apiKey: openAIKey,
            serviceType: .openAI
        )
    }
    
}

//
//  LLMKit.swift
//  LLMKit
//
//  Created by Mayank Gandhi on 05/08/25.
//  Copyright © 2025 m. All rights reserved.
//

import Foundation

/// LLMKit: A unified framework for AI-powered document processing
/// 
/// This framework provides a clean interface for:
/// - OpenAI GPT-4o Vision document parsing
/// - Claude document parsing
/// - Unified document processing across multiple AI providers
/// - File upload and management
/// - Document type detection and routing
///
/// ## Public API
///
/// ### Main Service
/// - `UnifiedDocumentParsingService`: Primary service for parsing documents
/// - `DocumentParsingService`: Protocol for document parsing services
/// - `LLMKitFactory`: Factory for creating services
///
/// ### Protocols
/// - `ParseableModel`: Protocol for models that can be parsed from documents
///
/// ### Models & Types
/// - `LLMKitError`: Error type for framework errors
/// - `ParsingMethod`: Enum describing parsing methods
/// - `ClaudeTool`, `ToolChoice`, `ClaudeInputSchema`: Types required for `ParseableModel`
/// - `OpenAIJSONSchema`: Schema type required for `ParseableModel`
///
/// ## Usage Example
///
/// ```swift
/// import LLMKit
///
/// // Create a service
/// let service = LLMKitFactory.createUnifiedService(
///     claudeKey: "your-claude-key",
///     openAIKey: "your-openai-key"
/// )
///
/// // Parse a document
/// let result = try await service.parseDocument(
///     from: documentURL,
///     as: YourModel.self
/// )
/// ```


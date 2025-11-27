//
//  DocumentParserFactory.swift
//  LLMKit
//
//  Created by Mayank Gandhi on 05/08/25.
//  Copyright © 2025 m. All rights reserved.
//

import Foundation

/// Factory for creating document parsers
class DocumentParserFactory: DocumentParserFactoryProtocol {

    func createClaudeParser(apiKey: String) -> DocumentParserProtocol {
        return ClaudeDocumentParser(apiKey: apiKey)
    }

    func createOpenAIParser(apiKey: String) -> DocumentParserProtocol {
        return OpenAIDocumentParser(apiKey: apiKey)
    }
}


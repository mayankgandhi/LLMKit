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
    
    func createParser(claudeKey: String) -> DocumentParserProtocol {
        return DocumentParser(claudeKey: claudeKey)
    }
    
    func createParser(openAIKey: String) -> DocumentParserProtocol {
        return DocumentParser(openAIKey: openAIKey)
    }
}


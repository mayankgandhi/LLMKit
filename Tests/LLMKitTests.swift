//
//  LLMKitTests.swift
//  LLMKitTests
//
//  Created by Mayank Gandhi on 05/08/25.
//  Copyright © 2025 m. All rights reserved.
//

import XCTest
@testable import LLMKit

final class LLMKitTests: XCTestCase {

    
    func testMimeTypeResolver() {
        XCTAssertEqual(MimeTypeResolver.mimeType(for: "test.pdf"), "application/pdf")
        XCTAssertEqual(MimeTypeResolver.mimeType(for: "test.jpg"), "image/jpeg")
        XCTAssertEqual(MimeTypeResolver.mimeType(for: "test.png"), "image/png")
    }
    
    // MARK: - DocumentParser Integration Tests
    
    func testDocumentParser_FileTypeDetection() {
        let documentParser = DocumentParser(openAIKey: "test", claudeKey: "test")
        
        XCTAssertTrue(documentParser.isImageFile(fileName: "test.jpg"))
        XCTAssertTrue(documentParser.isImageFile(fileName: "test.png"))
        XCTAssertTrue(documentParser.isImageFile(fileName: "test.gif"))
        XCTAssertTrue(documentParser.isImageFile(fileName: "test.webp"))
        XCTAssertTrue(documentParser.isImageFile(fileName: "test.heic"))
        
        XCTAssertTrue(documentParser.isPDFFile(fileName: "document.pdf"))
        XCTAssertTrue(documentParser.isPDFFile(fileName: "DOCUMENT.PDF"))
        
        XCTAssertFalse(documentParser.isImageFile(fileName: "document.pdf"))
        XCTAssertFalse(documentParser.isPDFFile(fileName: "image.jpg"))
        XCTAssertFalse(documentParser.isImageFile(fileName: "text.txt"))
    }
    
    func testDocumentParser_Initialization() {
        let openAIKey = "test-openai-key"
        let claudeKey = "test-claude-key"
        
        XCTAssertNoThrow(DocumentParser(openAIKey: openAIKey, claudeKey: claudeKey))
    }
}

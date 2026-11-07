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

    // The single `DocumentParser` that took a `claudeKey`/`openAIKey` was replaced by
    // per-provider parsers behind `DocumentParserProtocol` (commit 0b1bfbf). File-type
    // detection still lives there, so these assertions carry over unchanged.
    func testDocumentParser_FileTypeDetection() {
        let documentParser: DocumentParserProtocol = ClaudeDocumentParser(apiKey: "test")

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

        XCTAssertEqual(ClaudeDocumentParser(apiKey: claudeKey).providerName, "Claude")
        XCTAssertEqual(OpenAIDocumentParser(apiKey: openAIKey).providerName, "OpenAI")
    }

    // MARK: - Service Factory Tests

    func testFactory_CreatesProviderSpecificServices() {
        let claudeService = LLMKitFactory.createClaudeService(apiKey: "test-claude-key")
        let openAIService = LLMKitFactory.createOpenAIService(apiKey: "test-openai-key")

        XCTAssertEqual(claudeService.providerName, "Claude")
        XCTAssertEqual(openAIService.providerName, "OpenAI")
    }

    func testService_FileTypeSupport() {
        let service = LLMKitFactory.createClaudeService(apiKey: "test-claude-key")

        XCTAssertTrue(service.isFileTypeSupported(URL(fileURLWithPath: "/tmp/receipt.pdf")))
        XCTAssertTrue(service.isFileTypeSupported(URL(fileURLWithPath: "/tmp/receipt.HEIC")))
        XCTAssertFalse(service.isFileTypeSupported(URL(fileURLWithPath: "/tmp/notes.txt")))

        guard case .pdfFileUpload? = service.getParsingMethod(for: URL(fileURLWithPath: "/tmp/receipt.pdf")) else {
            return XCTFail("PDFs should be parsed by file upload")
        }
        guard case .directVision? = service.getParsingMethod(for: URL(fileURLWithPath: "/tmp/receipt.jpg")) else {
            return XCTFail("Images should be parsed by direct vision")
        }
        XCTAssertNil(service.getParsingMethod(for: URL(fileURLWithPath: "/tmp/notes.txt")))
    }
}

//
//  JSONResponseParserTests.swift
//  LLMKitTests
//
//  Created by Mayank Gandhi on 11/08/25.
//  Copyright © 2025 m. All rights reserved.
//

import XCTest
@testable import LLMKit

final class JSONResponseParserTests: XCTestCase {

    private let jsonParser = JSONResponseParser(jsonDecoder: JSONDecoder())
    
    // MARK: - Test Models
    
    private struct TestModel: Codable, Equatable {
        let id: String
        let name: String
        let count: Int
        let isActive: Bool
        let tags: [String]?
        
        init(id: String = "test-123", name: String = "Test Item", count: Int = 42, isActive: Bool = true, tags: [String]? = ["tag1", "tag2"]) {
            self.id = id
            self.name = name
            self.count = count
            self.isActive = isActive
            self.tags = tags
        }
    }
    
    private struct ComplexTestModel: Codable, Equatable {
        let patient: PatientInfo
        let medications: [MedicationInfo]
        let lastUpdated: Date
        
        struct PatientInfo: Codable, Equatable {
            let id: String
            let name: String
            let age: Int
        }
        
        struct MedicationInfo: Codable, Equatable {
            let name: String
            let dosage: String
            let frequency: String
        }
    }
    
    // MARK: - Mock Data
    
    private func createMockOpenAIResponse(withContent content: String) -> OpenAIChatResponse {
        return OpenAIChatResponse(
            id: "chatcmpl-test123",
            object: "chat.completion",
            created: 1234567890,
            model: "gpt-4o",
            choices: [
                OpenAIChoice(
                    index: 0,
                    message: OpenAIResponseMessage(
                        role: "assistant",
                        content: content,
                        refusal: nil
                    ),
                    logprobs: nil,
                    finishReason: "stop"
                )
            ],
            usage: OpenAIUsage(
                promptTokens: 100,
                completionTokens: 50,
                totalTokens: 150
            ),
            systemFingerprint: "fp_test"
        )
    }
    
    private func createMockClaudeResponse(withContent content: String) -> ClaudeMessageResponse<String> {
        return ClaudeMessageResponse(
            id: "msg_test123",
            type: "message",
            role: "assistant",
            model: "claude-sonnet-4-20250514",
            content: [
                ClaudeResponseContent(type: "text", text: content, input: "")
            ]
        )
    }
    
    // MARK: - OpenAI Response Parsing Tests
    
    func testParseOpenAIResponse_ValidJSON_Success() throws {
        let testModel = TestModel()
        let jsonString = try encodeToJSONString(testModel)
        let mockResponse = createMockOpenAIResponse(withContent: jsonString)
        
        let result = try jsonParser.parseOpenAIResponse(mockResponse, as: TestModel.self)
        
        XCTAssertEqual(result, testModel)
    }
    
    func testParseOpenAIResponse_EmptyContent_ThrowsError() {
        let mockResponse = createMockOpenAIResponse(withContent: "")
        
        XCTAssertThrowsError(try jsonParser.parseOpenAIResponse(mockResponse, as: TestModel.self)) { error in
            if case let LLMKitError.parsingError(message) = error {
                XCTAssertTrue(message.contains("No content in OpenAI response"))
            } else {
                XCTFail("Expected LLMKitError.parsingError, got \(error)")
            }
        }
    }
    
    func testParseOpenAIResponse_InvalidJSON_ThrowsError() {
        let mockResponse = createMockOpenAIResponse(withContent: "invalid json content")
        
        XCTAssertThrowsError(try jsonParser.parseOpenAIResponse(mockResponse, as: TestModel.self)) { error in
            if case let LLMKitError.parsingError(message) = error {
                XCTAssertTrue(message.contains("Failed to decode JSON"))
            } else {
                XCTFail("Expected LLMKitError.parsingError, got \(error)")
            }
        }
    }
    
    // MARK: - Claude Response Parsing Tests
    
    func testParseClaudeResponse_ValidJSON_Success() throws {
        let testModel = String()
        let jsonString = try encodeToJSONString(testModel)
        let mockResponse = createMockClaudeResponse(withContent: jsonString)
        
        let result = try jsonParser.parseClaudeResponse(mockResponse, as: String.self)
        
        XCTAssertEqual(result, testModel)
    }
    
    func testParseClaudeResponse_JSONWithMarkdownBlocks_Success() throws {
        let testModel = String()
        let jsonString = try encodeToJSONString(testModel)
        let contentWithMarkdown = "```json\n\(jsonString)\n```"
        let mockResponse = createMockClaudeResponse(withContent: contentWithMarkdown)
        
        let result = try jsonParser.parseClaudeResponse(mockResponse, as: String.self)
        
        XCTAssertEqual(result, testModel)
    }
    
    func testParseClaudeResponse_JSONWithMixedContent_Success() throws {
        let testModel = String()
        let jsonString = try encodeToJSONString(testModel)
        let contentWithText = "Here's the extracted information:\n\n\(jsonString)\n\nThat's all I found."
        let mockResponse = createMockClaudeResponse(withContent: contentWithText)
        
        let result = try jsonParser.parseClaudeResponse(mockResponse, as: String.self)
        
        XCTAssertEqual(result, testModel)
    }
    
    func testParseClaudeResponse_EmptyContent_ThrowsError() {
        let mockResponse = ClaudeMessageResponse<TestModel>(
            id: "msg_test123",
            type: "message",
            role: "assistant",
            model: "claude-sonnet-4-20250514",
            content: []
        )
        
        XCTAssertThrowsError(try jsonParser.parseClaudeResponse(mockResponse, as: TestModel.self)) { error in
            if case let LLMKitError.parsingError(message) = error {
                XCTAssertTrue(message.contains("No content in Claude response"))
            } else {
                XCTFail("Expected LLMKitError.parsingError, got \(error)")
            }
        }
    }
    
    // MARK: - JSON String Parsing Tests
    
    func testParseJSONString_ValidJSON_Success() throws {
        let testModel = TestModel()
        let jsonString = try encodeToJSONString(testModel)
        
        let result = try jsonParser.parseJSONString(jsonString, as: TestModel.self)
        
        XCTAssertEqual(result, testModel)
    }
    
    func testParseJSONString_ComplexModel_Success() throws {
        let complexModel = ComplexTestModel(
            patient: ComplexTestModel.PatientInfo(id: "p123", name: "John Doe", age: 45),
            medications: [
                ComplexTestModel.MedicationInfo(name: "Aspirin", dosage: "81mg", frequency: "Daily"),
                ComplexTestModel.MedicationInfo(name: "Lisinopril", dosage: "10mg", frequency: "Once daily")
            ],
            lastUpdated: Date(timeIntervalSince1970: 1640995200) // 2022-01-01 00:00:00 UTC
        )
        let jsonString = try encodeToJSONString(complexModel)
        
        let result = try jsonParser.parseJSONString(jsonString, as: ComplexTestModel.self)
        
        XCTAssertEqual(result, complexModel)
    }
    
    func testParseJSONString_InvalidJSON_ThrowsError() {
        let invalidJSON = "{invalid json structure"
        
        XCTAssertThrowsError(try jsonParser.parseJSONString(invalidJSON, as: TestModel.self)) { error in
            if case let LLMKitError.parsingError(message) = error {
                XCTAssertTrue(message.contains("Failed to decode JSON"))
            } else {
                XCTFail("Expected LLMKitError.parsingError, got \(error)")
            }
        }
    }
    
    // MARK: - Claude Response Cleaning Tests
    
    func testCleanClaudeJSONResponse_BasicJSON_NoChange() {
        let jsonString = "{\"id\":\"test\",\"name\":\"Test Item\"}"
        let result = jsonParser.cleanClaudeJSONResponse(jsonString)
        XCTAssertEqual(result, jsonString)
    }
    
    func testCleanClaudeJSONResponse_WithMarkdownBlocks_Cleaned() {
        let jsonString = "{\"id\":\"test\",\"name\":\"Test Item\"}"
        let contentWithMarkdown = "```json\n\(jsonString)\n```"
        
        let result = jsonParser.cleanClaudeJSONResponse(contentWithMarkdown)
        
        XCTAssertEqual(result, jsonString)
    }
    
    func testCleanClaudeJSONResponse_WithSurroundingText_ExtractsJSON() {
        let jsonString = "{\"id\":\"test\",\"name\":\"Test Item\"}"
        let contentWithText = "Here is the analysis:\\n\\n\(jsonString)\\n\\nEnd of analysis."
        
        let result = jsonParser.cleanClaudeJSONResponse(contentWithText)
        
        XCTAssertEqual(result, jsonString)
    }
    
    func testCleanClaudeJSONResponse_WithWhitespace_Trimmed() {
        let jsonString = "{\"id\":\"test\",\"name\":\"Test Item\"}"
        let contentWithWhitespace = "   \\n\\n\(jsonString)\\n\\n   "
        
        let result = jsonParser.cleanClaudeJSONResponse(contentWithWhitespace)
        
        XCTAssertEqual(result, jsonString)
    }
    
    func testCleanClaudeJSONResponse_ArrayJSON_Cleaned() {
        let jsonString = "[{\"name\":\"Item1\"},{\"name\":\"Item2\"}]"
        let contentWithMarkdown = "```json\n\(jsonString)\n```"
        
        let result = jsonParser.cleanClaudeJSONResponse(contentWithMarkdown)
        
        XCTAssertEqual(result, jsonString)
    }
    
    // MARK: - JSON Structure Validation Tests
    
    func testIsValidJSONStructure_ValidObject_ReturnsTrue() {
        let validJSON = "{\"key\":\"value\"}"
        XCTAssertTrue(jsonParser.isValidJSONStructure(validJSON))
    }
    
    func testIsValidJSONStructure_ValidArray_ReturnsTrue() {
        let validJSON = "[{\"key\":\"value\"},{\"key2\":\"value2\"}]"
        XCTAssertTrue(jsonParser.isValidJSONStructure(validJSON))
    }
    
    func testIsValidJSONStructure_InvalidStructure_ReturnsFalse() {
        let invalidJSON = "not json at all"
        XCTAssertFalse(jsonParser.isValidJSONStructure(invalidJSON))
    }
    
    func testIsValidJSONStructure_IncompleteObject_ReturnsFalse() {
        let incompleteJSON = "{\"key\":\"value\""
        XCTAssertFalse(jsonParser.isValidJSONStructure(incompleteJSON))
    }
    
    func testIsValidJSONStructure_WithWhitespace_ReturnsTrue() {
        let validJSON = "  \\n{\\n  \"key\": \"value\"\\n}\\n  "
        XCTAssertTrue(jsonParser.isValidJSONStructure(validJSON))
    }
    
    // MARK: - Mixed Content Extraction Tests
    
    func testExtractJSONFromMixedContent_ValidJSON_ExtractsJSON() {
        let jsonString = "{\"id\":\"test\",\"name\":\"Test Item\"}"
        let mixedContent = "Here's your data: \(jsonString) - that's all!"
        
        let result = jsonParser.extractJSONFromMixedContent(mixedContent)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result, jsonString)
    }
    
    func testExtractJSONFromMixedContent_NoValidJSON_ReturnsNil() {
        let mixedContent = "This is just text with no JSON structure"
        
        let result = jsonParser.extractJSONFromMixedContent(mixedContent)
        
        XCTAssertNil(result)
    }
    
    func testExtractJSONFromMixedContent_WithMarkdown_ExtractsJSON() {
        let jsonString = "{\"id\":\"test\",\"name\":\"Test Item\"}"
        let mixedContent = "```json\\n\(jsonString)\\n```"
        
        let result = jsonParser.extractJSONFromMixedContent(mixedContent)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result, jsonString)
    }
    
    // MARK: - Edge Cases and Error Handling
    
    func testParseJSON_EmptyData_ThrowsError() {
        let emptyData = Data()
        
        XCTAssertThrowsError(try jsonParser.parseJSON(emptyData, as: TestModel.self)) { error in
            if case let LLMKitError.parsingError(message) = error {
                XCTAssertTrue(message.contains("Failed to decode JSON"))
            } else {
                XCTFail("Expected LLMKitError.parsingError, got \(error)")
            }
        }
    }
    
    func testParseJSON_MalformedJSON_IncludesJSONInError() {
        let malformedJSON = "{\"key\": invalid_value}"
        let jsonData = malformedJSON.data(using: .utf8)!
        
        XCTAssertThrowsError(try jsonParser.parseJSON(jsonData, as: TestModel.self)) { error in
            if case let LLMKitError.parsingError(message) = error {
                XCTAssertTrue(message.contains("Failed to decode JSON"))
                XCTAssertTrue(message.contains(malformedJSON))
            } else {
                XCTFail("Expected LLMKitError.parsingError, got \(error)")
            }
        }
    }
    
    func testParseJSON_NonUTF8Data_ThrowsError() {
        let invalidUTF8Data = Data([0xFF, 0xFE, 0xFD])
        
        XCTAssertThrowsError(try jsonParser.parseJSON(invalidUTF8Data, as: TestModel.self)) { error in
            if case let LLMKitError.parsingError(message) = error {
                XCTAssertTrue(message.contains("Failed to decode JSON"))
                XCTAssertTrue(message.contains("Invalid UTF-8 data"))
            } else {
                XCTFail("Expected LLMKitError.parsingError, got \(error)")
            }
        }
    }
    
    // MARK: - Custom Test Cases for Manual Testing
    
    /// Use this test method to manually test any custom model and response string
    /// Replace the model and responseString with your own values
//    func testCustomModelAndResponse() throws {
//        // MARK: - CUSTOMIZE THIS SECTION
//       
//        // You can also test with Claude-style responses with markdown
//        let claudeStyleResponse = """
//        ```json\n{\n  \"dateIssued\": \"2025-05-27T15:18:00Z\",\n  \"doctorName\": \"Dr. Ravi Sankar Erukulapati\",\n  \"facilityName\": \"Apollo Hospitals Jubilee Hills\",\n  \"followUpDate\": \"2025-06-10T00:00:00Z\",\n  \"followUpTests\": [\n    \"SODIUM\",\n    \"POTASSIUM\", \n    \"CREATININE\",\n    \"TESTOSTERONE TROUGH LEVELS\",\n    \"FREE T4\",\n    \"FREE T3\",\n    \"LFTs\"\n  ],\n  \"notes\": \"see 17-5-2025 physical consult prescription, please. note- on att as per pulmonologist for uveitis- tb test positive. plan: counselled. sick day rules.\",\n  \"medications\": [\n    {\n      \"id\": \"550e8400-e29b-41d4-a716-446655440001\",\n      \"name\": \"TAB HISONE\",\n      \"frequency\": [\n        {\n          \"daily\": {\n            \"times\": [\n              {\"hour\": 7, \"minute\": 0},\n              {\"hour\": 12, \"minute\": 0},\n              {\"hour\": 17, \"minute\": 0}\n            ]\n          }\n        }\n      ],\n      \"duration\": \"ongoing\",\n      \"dosage\": \"10 MG AT 7 AM, 5 MG AT 12 NOON AND 5 MG AT 5 PM\",\n      \"instructions\": \"Increase dosage as prescribed\"\n    },\n    {\n      \"id\": \"550e8400-e29b-41d4-a716-446655440002\", \n      \"name\": \"SUSTANON INJECTION\",\n      \"frequency\": [],\n      \"duration\": \"ongoing\",\n      \"dosage\": null,\n      \"instructions\": \"AS PER MY 17-5-2025 physical PRESCRIPTION\"\n    },\n    {\n      \"id\": \"550e8400-e29b-41d4-a716-446655440003\",\n      \"name\": \"TAB THYRONORM\",\n      \"frequency\": [\n        {\n          \"daily\": {\n            \"times\": [\n              {\"hour\": 8, \"minute\": 0}\n            ]\n          }\n        }\n      ],\n      \"duration\": \"ongoing\",\n      \"dosage\": \"125 MICROGRAMS\",\n      \"instructions\": \"CONTINUE DAILY EMPTY STOMACH\"\n    }\n  ]\n}\n```
//        """
//        
//        
//        do {
//            let cleanedResponse = createMockClaudeResponse(withContent: claudeStyleResponse)
//            let result2 = try jsonParser.parseClaudeResponse(
//                cleanedResponse,
//                as: ParsedPrescription.self
//            )
//            print("\\n✅ Claude-style response parsing successful:")
//          
//        } catch {
//            print("\\n❌ Claude-style response parsing failed: \(error)")
//            XCTFail("Claude-style response parsing should succeed")
//        }
//        
//        print("\\n=== Custom Model Testing Complete ===\\n")
//    }
    
    /// Generic test helper that you can call with any model and response
    func testGenericModelParsing<T: Codable & Equatable>(
        model: T.Type,
        jsonResponse: String,
        expectedResult: T? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        do {
            let result = try jsonParser.parseJSONString(jsonResponse, as: model)
            print("✅ Successfully parsed \(String(describing: model))")
            print("   Result: \(result)")
            
            if let expected = expectedResult {
                XCTAssertEqual(result, expected, "Parsed result should match expected", file: file, line: line)
            }
        } catch {
            print("❌ Failed to parse \(String(describing: model)): \\(error)")
            XCTFail("Should successfully parse \(String(describing: model))", file: file, line: line)
        }
    }

    // MARK: - Helper Methods
    
    private func encodeToJSONString<T: Codable>(_ object: T) throws -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(object)
        return String(data: data, encoding: .utf8)!
    }
}

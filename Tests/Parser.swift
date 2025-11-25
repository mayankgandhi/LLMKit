//
//  Parser.swift
//  LLMKit
//
//  Created by Mayank Gandhi on 08/09/25.
//  Copyright © 2025 m. All rights reserved.
//

import Foundation
@testable import LLMKit
import XCTest

final class JSONParser: XCTestCase {
    
    /// Test JSON decodability of LLMKit models
    func testDecodability<T: Codable>(
        jsonString: String,
        modelType: T.Type,
        printResult: Bool = true
    ) -> Result<T, Error> {
        guard let jsonData = jsonString.data(using: .utf8) else {
            let error = NSError(domain: "JSONParser", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid UTF-8 string"])
            if printResult {
                print("❌ Failed to convert string to data: \(error.localizedDescription)")
            }
            return .failure(error)
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decoded = try decoder.decode(modelType, from: jsonData)
            
            if printResult {
                print("✅ Successfully decoded \(String(describing: modelType))")
                print("📝 Result: \(decoded)")
            }
            
            return .success(decoded)
        } catch {
            if printResult {
                print("❌ Failed to decode \(String(describing: modelType)): \(error)")
                if let decodingError = error as? DecodingError {
                    print("🔍 Decoding error details: \(decodingError.localizedDescription)")
                }
            }
            return .failure(error)
        }
    }
    
    /// Test JSON encodability of LLMKit models
    func testEncodability<T: Codable>(
        model: T,
        printResult: Bool = true
    ) -> Result<String, Error> {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(model)
            
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                let error = NSError(domain: "JSONParser", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to convert data to UTF-8 string"])
                if printResult {
                    print("❌ Failed to convert data to string: \(error.localizedDescription)")
                }
                return .failure(error)
            }
            
            if printResult {
                print("✅ Successfully encoded \(String(describing: type(of: model)))")
                print("📝 JSON Output:")
                print(jsonString)
            }
            
            return .success(jsonString)
        } catch {
            if printResult {
                print("❌ Failed to encode \(String(describing: type(of: model))): \(error)")
            }
            return .failure(error)
        }
    }
    
    /// Round-trip test: encode model to JSON, then decode back
    func testRoundTrip<T: Codable & Equatable>(
        model: T,
        printResult: Bool = true
    ) -> Bool {
        // First encode
        let encodeResult = testEncodability(model: model, printResult: false)
        guard case .success(let jsonString) = encodeResult else {
            if printResult {
                print("❌ Round-trip failed at encoding step")
            }
            return false
        }
        
        // Then decode
        let decodeResult = testDecodability(jsonString: jsonString, modelType: T.self, printResult: false)
        guard case .success(let decodedModel) = decodeResult else {
            if printResult {
                print("❌ Round-trip failed at decoding step")
            }
            return false
        }
        
        // Compare
        let isEqual = model == decodedModel
        if printResult {
            if isEqual {
                print("✅ Round-trip test passed for \(String(describing: T.self))")
            } else {
                print("❌ Round-trip test failed: models are not equal")
                print("Original: \(model)")
                print("Decoded: \(decodedModel)")
            }
        }
        
        return isEqual
    }
    
    /// Example method showing how to test prescription parsing
    func testPrescriptionParsing() {
        let sampleJSON = """
        {
        "id": "msg_01LXEMxd2jWPuqEo8NRkd6xg",
        "type": "message",
        "role": "assistant",
        "model": "claude-sonnet-4-20250514",
        "content": [
        {
        "type": "tool_use",
        "id": "toolu_015ouWR99U7RKJZwQnbS7woh",
        "name": "parse_prescription",
        "input": {
        "dateIssued": "2025-05-27T15:18:00Z",
        "doctorName": "Dr. Ravi Sankar Erukulapati",
        "facilityName": "Apollo Hospitals Jubilee Hills",
        "followUpDate": "2025-06-10T00:00:00Z",
        "followUpTests": [
          "Sodium",
          "Potassium",
          "Creatinine",
          "Testosterone Trough Levels",
          "free t4",
          "free t3",
          "LFTs"
        ],
        "medications": [
          {
            "id": "550e8400-e29b-41d4-a716-446655440001",
            "name": "TAB HISONE",
            "dosage": "10 mg at 7 AM, 5 mg at 12 noon, 5 mg at 5 PM",
            "frequency": [
              {
                "type": "daily",
                "times": [
                  {
                    "hour": 7,
                    "minute": 0
                  },
                  {
                    "hour": 12,
                    "minute": 0
                  },
                  {
                    "hour": 17,
                    "minute": 0
                  }
                ]
              }
            ],
            "duration": {
              "type": "ongoing"
            },
            "instructions": "Increase dosage as prescribed. Follow sick day rules."
          },
          {
            "id": "550e8400-e29b-41d4-a716-446655440002",
            "name": "SUSTANON INJECTION",
            "duration": {
              "type": "ongoing"
            },
            "instructions": "As per 17-5-2025 physical prescription"
          },
          {
            "id": "550e8400-e29b-41d4-a716-446655440003",
            "name": "TAB THYRONORM",
            "dosage": "125 micrograms",
            "frequency": [
              {
                "type": "daily",
                "times": [
                  {
                    "hour": 8,
                    "minute": 0
                  }
                ]
              }
            ],
            "duration": {
              "type": "ongoing"
            },
            "instructions": "Take daily on empty stomach"
          }
        ],
        "notes": "Patient being treated for uveitis with positive TB test as per pulmonologist. This is a telemedicine consultation with limitations. Physical consultation strongly advised. Emergency services should be sought for urgent medical needs."
        }
        }
        ],
        "stop_reason": "tool_use",
        "stop_sequence": null,
        "usage": {
        "input_tokens": 8205,
        "cache_creation_input_tokens": 0,
        "cache_read_input_tokens": 0,
        "cache_creation": {
        "ephemeral_5m_input_tokens": 0,
        "ephemeral_1h_input_tokens": 0
        },
        "output_tokens": 654,
        "service_tier": "standard"
        }
        }
        """
        
        print("🧪 Testing Prescription JSON Parsing...")
        let result = testDecodability(
            jsonString: sampleJSON,
            modelType: ClaudeMessageResponse<ParsedPrescription>.self
        )
        
        switch result {
            case .success(let prescription):
                print("✅ Prescription parsed successfully")
                XCTAssert(true)
            case .failure(let error):
                print("❌ Failed to parse prescription: \(error)")
                XCTAssert(false)
        }
    }
}

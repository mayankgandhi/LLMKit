//
//  MultipartFormBuilder.swift
//  LLMKit
//
//  Created by Mayank Gandhi on 05/08/25.
//  Copyright © 2025 m. All rights reserved.
//

import Foundation

/// Utility for creating multipart form data
public struct MultipartFormBuilder {
    
    public static func createMultipartBody(
        boundary: String, 
        filename: String, 
        data: Data, 
        mimeType: String
    ) -> Data {
        var body = Data()
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        return body
    }
    
    public static func generateBoundary() -> String {
        return UUID().uuidString
    }
    
    public static func contentType(with boundary: String) -> String {
        return "multipart/form-data; boundary=\(boundary)"
    }
}
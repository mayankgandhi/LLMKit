//
//  ClaudeFileManager.swift
//  Walnut
//
//  Created by Mayank Gandhi on 08/07/25.
//  Copyright © 2025 m. All rights reserved.
//

import Foundation

/// Handles file upload and deletion operations with Claude API
final class ClaudeFileManager {
    
    // MARK: - Type Aliases
    
    typealias UploadResponse = ClaudeFileUploadResponse
    
    // MARK: - Dependencies
    
    private let networkClient: ClaudeNetworkClient
    private let jsonDecoder: JSONDecoder
    
    // MARK: - Initialization
    
    init(networkClient: ClaudeNetworkClient) {
        self.networkClient = networkClient
        self.jsonDecoder = JSONDecoder()
    }
    
    // MARK: - File Upload
    
    func uploadFile(data: Data, fileName: String) async throws -> ClaudeFileUploadResponse {
        let mimeType = MimeTypeResolver.mimeType(for: fileName)
        
        // Create multipart form data
        let boundary = MultipartFormBuilder.generateBoundary()
        let body = MultipartFormBuilder.createMultipartBody(
            boundary: boundary,
            filename: fileName,
            data: data,
            mimeType: mimeType
        )
        let contentType = MultipartFormBuilder.contentType(with: boundary)
        
        let request = try networkClient.createFileUploadRequest(
            endpoint: "files",
            body: body,
            contentType: contentType
        )
        
        let (data, httpResponse) = try await networkClient.executeRequest(request)
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw LLMKitError.uploadError(errorMessage)
        }
        
        do {
            let uploadResponse = try jsonDecoder.decode(
                ClaudeFileUploadResponse.self,
                from: data
            )
            return uploadResponse
        } catch let error as DecodingError {
            throw LLMKitError.decodingError(error)
        }
    }
    
    func uploadDocument(at url: URL) async throws -> ClaudeFileUploadResponse {
        // Read file data
        let fileData = try Data(contentsOf: url)
        let filename = url.lastPathComponent
        
        return try await uploadFile(data: fileData, fileName: filename)
    }
    
    // MARK: - File Deletion
    
    func deleteDocument(fileId: String) async throws {
        let request = try networkClient.createDeleteRequest(endpoint: "files/\(fileId)")
        let (data, httpResponse) = try await networkClient.executeRequest(request)
        
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 204 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw LLMKitError.deleteError(errorMessage)
        }
        
        // Success - file deleted
    }
}

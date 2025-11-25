//
//  ClaudeNetworkClient.swift
//  Walnut
//
//  Created by Mayank Gandhi on 08/07/25.
//  Copyright © 2025 m. All rights reserved.
//

import Foundation

/// Handles HTTP communication with Claude API
final class ClaudeNetworkClient: BaseNetworkClient {
    
    // MARK: - Initialization
    
    init(apiKey: String) {
        super.init(apiKey: apiKey, baseURL: "https://api.anthropic.com/v1")
    }
    
    // MARK: - Claude-specific Methods
    
    func createFileUploadRequest(endpoint: String, body: Data, contentType: String) throws -> URLRequest {
        var request = try createBaseRequest(endpoint: endpoint, method: "POST")
        addClaudeHeaders(to: &request)
        addMultipartHeaders(to: &request, contentType: contentType)
        request.httpBody = body
        return request
    }
    
    func createMessageRequest(endpoint: String, body: Data) throws -> URLRequest {
        var request = try createBaseRequest(endpoint: endpoint, method: "POST")
        addClaudeHeaders(to: &request)
        addJSONHeaders(to: &request)
        request.httpBody = body
        return request
    }
    
    func createDeleteRequest(endpoint: String) throws -> URLRequest {
        var request = try createBaseRequest(endpoint: endpoint, method: "DELETE")
        addClaudeHeaders(to: &request)
        return request
    }
    
    // MARK: - Private Helpers
    
    private func addClaudeHeaders(to request: inout URLRequest) {
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("files-api-2025-04-14", forHTTPHeaderField: "anthropic-beta")
    }
}

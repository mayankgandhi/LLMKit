//
//  OpenAINetworkClient.swift
//  LLMKit
//
//  Created by Mayank Gandhi on 05/08/25.
//  Copyright © 2025 m. All rights reserved.
//

import Foundation

/// Handles HTTP communication with OpenAI API
public final class OpenAINetworkClient: BaseNetworkClient {
    
    // MARK: - Initialization
    
    public init(apiKey: String) {
        super.init(apiKey: apiKey, baseURL: "https://api.openai.com/v1")
    }
    
    // MARK: - OpenAI-specific Methods
    
    public func createChatRequest(endpoint: String, body: Data) throws -> URLRequest {
        var request = try createBaseRequest(endpoint: endpoint, method: "POST")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        addJSONHeaders(to: &request)
        request.httpBody = body
        return request
    }
}
//
//  MimeTypeResolver.swift
//  LLMKit
//
//  Created by Mayank Gandhi on 05/08/25.
//  Copyright © 2025 m. All rights reserved.
//

import Foundation

/// Utility for determining MIME types from file extensions
public struct MimeTypeResolver {
    
    public static func mimeType(for url: URL) -> String {
        let pathExtension = url.pathExtension.lowercased()
        return mimeType(for: pathExtension)
    }
    
    public static func mimeType(for fileName: String) -> String {
        let pathExtension = (fileName as NSString).pathExtension.lowercased()
        return mimeType(pathExtension: pathExtension)
    }
    
    private static func mimeType(pathExtension: String) -> String {
        switch pathExtension {
        case "pdf":
            return "application/pdf"
        case "txt":
            return "text/plain"
        case "json":
            return "application/json"
        case "csv":
            return "text/csv"
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        case "webp":
            return "image/webp"
        case "heic":
            return "image/heic"
        case "heif":
            return "image/heif"
        default:
            return "application/pdf"
        }
    }
}
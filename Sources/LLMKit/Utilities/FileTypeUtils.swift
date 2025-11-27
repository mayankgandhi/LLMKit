//
//  FileTypeUtils.swift
//  LLMKit
//
//  Created by Mayank Gandhi on 05/08/25.
//  Copyright © 2025 m. All rights reserved.
//

import Foundation

/// Utility for file type detection
struct FileTypeUtils {

    /// Checks if a file is an image based on its extension
    /// - Parameter fileName: The name of the file
    /// - Returns: True if the file is a supported image type
    static func isImageFile(fileName: String) -> Bool {
        let pathExtension = (fileName as NSString).pathExtension.lowercased()
        let supportedImageTypes = ["jpg", "jpeg", "png", "gif", "webp", "heic", "heif"]
        return supportedImageTypes.contains(pathExtension)
    }

    /// Checks if a file is a PDF based on its extension
    /// - Parameter fileName: The name of the file
    /// - Returns: True if the file is a PDF
    static func isPDFFile(fileName: String) -> Bool {
        let pathExtension = (fileName as NSString).pathExtension.lowercased()
        return pathExtension == "pdf"
    }
}

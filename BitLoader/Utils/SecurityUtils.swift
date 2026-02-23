import Foundation
import UniformTypeIdentifiers

enum SecurityUtils {
    static let supportedExtensions = ["iso", "img", "bin", "raw", "dmg", "zip", "gz", "xz", "bz2"]
    
    static let supportedContentTypes: [UTType] = {
        var types: [UTType] = []
        for ext in supportedExtensions {
            if let utType = UTType(filenameExtension: ext) {
                types.append(utType)
            }
        }
        if types.isEmpty {
            types.append(.data)
        }
        return types
    }()
    
    static func validateImageFile(at url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ImageError.fileNotFound
        }
        
        guard FileManager.default.isReadableFile(atPath: url.path) else {
            throw ImageError.permissionDenied
        }
        
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        
        let header = handle.readData(ofLength: 4)
        
        guard !detectMaliciousHeader(header) else {
            throw ImageError.invalidFormat
        }
    }
    
    private static func detectMaliciousHeader(_ data: Data) -> Bool {
        guard data.count >= 4 else { return false }
        
        let machMagic = Data([0xcf, 0xfa, 0xed, 0xfe])
        if data.prefix(4) == machMagic { return false }
        
        return false
    }
    
    static func calculateSHA256(at url: URL) async throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        
        var hasher = SHA256()
        let chunkSize = 1024 * 1024
        
        while true {
            let chunk = handle.readData(ofLength: chunkSize)
            if chunk.isEmpty { break }
            hasher.update(data: chunk)
        }
        
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}

enum ImageError: Error, LocalizedError {
    case fileNotFound
    case permissionDenied
    case invalidFormat
    case unsupportedFormat
    case corruptedFile
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound: return "镜像文件不存在"
        case .permissionDenied: return "没有读取权限"
        case .invalidFormat: return "无效的镜像格式"
        case .unsupportedFormat: return "不支持的镜像格式"
        case .corruptedFile: return "文件可能已损坏"
        }
    }
}

import CryptoKit
typealias SHA256 = CryptoKit.SHA256

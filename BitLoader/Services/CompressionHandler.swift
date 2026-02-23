import Foundation

enum CompressionType {
    case none
    case gzip
    case xz
    case zip
    case bzip2
    case zstd
}

enum CompressionHandler {
    static func detectCompression(url: URL) -> CompressionType {
        let ext = url.pathExtension.lowercased()
        
        switch ext {
        case "gz", "gzip":
            return .gzip
        case "xz":
            return .xz
        case "zip":
            return .zip
        case "bz2", "bzip2":
            return .bzip2
        case "zst", "zstd":
            return .zstd
        default:
            return .none
        }
    }
    
    static func decompressCommand(for url: URL) -> String {
        switch detectCompression(url: url) {
        case .gzip:
            return "gzip -dc '\(url.path)'"
        case .xz:
            return "xz -dc '\(url.path)'"
        case .zip:
            return "unzip -p '\(url.path)'"
        case .bzip2:
            return "bzip2 -dc '\(url.path)'"
        case .zstd:
            return "zstd -dc '\(url.path)'"
        case .none:
            return "cat '\(url.path)'"
        }
    }
    
    static func uncompressedSize(of url: URL) async -> UInt64? {
        let type = detectCompression(url: url)
        
        guard type != .none else {
            if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
               let size = attrs[.size] as? UInt64 {
                return size
            }
            return nil
        }
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/sh")
        task.arguments = ["-c", "\(decompressCommand(for: url)) | wc -c"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            task.waitUntilExit()
            
            if let output = String(data: data, encoding: .utf8),
               let size = UInt64(output.trimmingCharacters(in: .whitespacesAndNewlines)) {
                return size
            }
        } catch {
            print("Failed to get uncompressed size: \(error)")
        }
        
        return nil
    }
    
    static func isCompressed(url: URL) -> Bool {
        return detectCompression(url: url) != .none
    }
}

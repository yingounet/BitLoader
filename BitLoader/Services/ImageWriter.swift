import Foundation

enum ImageWriterError: Error, LocalizedError {
    case permissionDenied
    case deviceNotFound
    case imageNotFound
    case writeFailed(errno: Int32, message: String)
    case verificationFailed
    case userCancelled
    case insufficientSpace(required: UInt64, available: UInt64)
    case unmountFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "需要管理员权限来写入磁盘"
        case .deviceNotFound:
            return "目标设备未找到"
        case .imageNotFound:
            return "镜像文件不存在"
        case .writeFailed(let errno, let message):
            return "写入失败 (错误码: \(errno)): \(message)"
        case .verificationFailed:
            return "数据验证失败"
        case .userCancelled:
            return "操作已取消"
        case .insufficientSpace(let required, let available):
            return "空间不足 (需要 \(FormatUtils.formatBytes(required)), 可用 \(FormatUtils.formatBytes(available)))"
        case .unmountFailed(let message):
            return "无法卸载设备: \(message)"
        }
    }
}

@MainActor
@Observable
class ImageWriter {
    var progress: Double = 0
    var bytesWritten: UInt64 = 0
    var totalBytes: UInt64 = 0
    var isWriting: Bool = false
    var currentPhase: String = ""
    
    private var process: Process?
    private var isCancelled: Bool = false
    
    nonisolated func write(
        imageURL: URL,
        to device: USBDevice,
        verify: Bool = true,
        progressHandler: @escaping @MainActor (Double, UInt64, UInt64) -> Void,
        completionHandler: @escaping @MainActor (Result<Void, ImageWriterError>) -> Void
    ) {
        Task { @MainActor in
            isWriting = true
            isCancelled = false
            progress = 0
            bytesWritten = 0
            currentPhase = "准备中..."
        }
        
        Task.detached {
            do {
                try await self.performWrite(
                    imageURL: imageURL,
                    to: device,
                    verify: verify,
                    progressHandler: progressHandler
                )
                
                await MainActor.run {
                    completionHandler(.success(()))
                }
            } catch let error as ImageWriterError {
                await MainActor.run {
                    completionHandler(.failure(error))
                }
            } catch {
                await MainActor.run {
                    completionHandler(.failure(.writeFailed(errno: -1, message: error.localizedDescription)))
                }
            }
            
            await MainActor.run {
                self.isWriting = false
            }
        }
    }
    
    private func performWrite(
        imageURL: URL,
        to device: USBDevice,
        verify: Bool,
        progressHandler: @escaping @MainActor (Double, UInt64, UInt64) -> Void
    ) async throws {
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw ImageWriterError.imageNotFound
        }
        
        let isCompressed = CompressionHandler.isCompressed(url: imageURL)
        let imageSize: UInt64
        
        if isCompressed {
            await MainActor.run { self.currentPhase = "计算镜像大小..." }
            guard let size = await CompressionHandler.uncompressedSize(of: imageURL) else {
                throw ImageWriterError.imageNotFound
            }
            imageSize = size
        } else {
            let attrs = try FileManager.default.attributesOfItem(atPath: imageURL.path)
            imageSize = attrs[.size] as? UInt64 ?? 0
        }
        
        guard device.size >= imageSize else {
            throw ImageWriterError.insufficientSpace(required: imageSize, available: device.size)
        }
        
        await MainActor.run {
            self.totalBytes = imageSize
            self.currentPhase = "卸载设备..."
        }
        
        try await unmountDevice(device)
        
        await MainActor.run { self.currentPhase = "写入中..." }
        
        try await writeImageData(
            imageURL: imageURL,
            to: device,
            totalSize: imageSize,
            isCompressed: isCompressed,
            progressHandler: progressHandler
        )
        
        if verify && !isCancelled {
            await MainActor.run { self.currentPhase = "验证中..." }
            try await verifyWrite(imageURL: imageURL, device: device, totalSize: imageSize)
        }
    }
    
    private func unmountDevice(_ device: USBDevice) async throws {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/diskutil")
        task.arguments = ["unmountDisk", "force", device.bsdName]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        try task.run()
        task.waitUntilExit()
        
        if task.terminationStatus != 0 {
            let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "Unknown error"
            throw ImageWriterError.unmountFailed(output)
        }
    }
    
    private func writeImageData(
        imageURL: URL,
        to device: USBDevice,
        totalSize: UInt64,
        isCompressed: Bool,
        progressHandler: @escaping @MainActor (Double, UInt64, UInt64) -> Void
    ) async throws {
        let sourceCommand: String
        if isCompressed {
            sourceCommand = CompressionHandler.decompressCommand(for: imageURL)
        } else {
            sourceCommand = "cat '\(imageURL.path)'"
        }
        
        let script = """
        do shell script "\(sourceCommand) | dd of='\(device.rawDevicePath)' bs=4m status=progress" with administrator privileges
        """
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = ["-e", script]
        
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = outputPipe
        
        await MainActor.run { self.process = task }
        
        try task.run()
        
        let progressMonitor = Task {
            var lastBytes: UInt64 = 0
            var lastTime = Date()
            
            while task.isRunning {
                try? await Task.sleep(nanoseconds: 500_000_000)
                
                if self.isCancelled { break }
                
                let elapsed = Date().timeIntervalSince(lastTime)
                if elapsed > 0.5 {
                    let expectedProgress = min(lastBytes + UInt64(elapsed * 50_000_000), totalSize)
                    lastBytes = expectedProgress
                    lastTime = Date()
                    
                    let progress = Double(expectedProgress) / Double(totalSize)
                    
                    await MainActor.run {
                        self.progress = progress
                        self.bytesWritten = expectedProgress
                        progressHandler(progress, expectedProgress, totalSize)
                    }
                }
            }
        }
        
        task.waitUntilExit()
        progressMonitor.cancel()
        
        await MainActor.run { self.process = nil }
        
        if isCancelled {
            throw ImageWriterError.userCancelled
        }
        
        guard task.terminationStatus == 0 else {
            let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "Unknown error"
            throw ImageWriterError.writeFailed(errno: task.terminationStatus, message: output)
        }
        
        await MainActor.run {
            self.progress = 1.0
            self.bytesWritten = totalSize
            progressHandler(1.0, totalSize, totalSize)
        }
    }
    
    private func verifyWrite(imageURL: URL, device: USBDevice, totalSize: UInt64) async throws {
        await MainActor.run { self.currentPhase = "验证中..." }
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/sh")
        task.arguments = ["-c", "head -c 1048576 '\(device.rawDevicePath)' | shasum -a 256"]
        
        try task.run()
        task.waitUntilExit()
        
        if isCancelled {
            throw ImageWriterError.userCancelled
        }
    }
    
    func cancel() {
        isCancelled = true
        process?.terminate()
    }
}

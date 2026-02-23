import Foundation
import SwiftUI
import UniformTypeIdentifiers
import UserNotifications

@MainActor
@Observable
class FlasherViewModel {
    var appState = AppState()
    var deviceEnumerator = DeviceEnumerator()
    var imageWriter = ImageWriter()
    
    var selectedImageURL: URL? {
        didSet { updateImageSize() }
    }
    var imageSize: UInt64 = 0
    var selectedDevice: USBDevice?
    var devices: [USBDevice] { deviceEnumerator.devices }
    
    var isWriting: Bool = false
    var progress: Double = 0
    var bytesWritten: UInt64 = 0
    var totalBytes: UInt64 = 0
    var statusText: String = ""
    var estimatedTimeRemaining: TimeInterval?
    
    var showError: Bool = false
    var errorMessage: String = ""
    
    private var writeStartTime: Date?
    
    var canStartWrite: Bool {
        selectedImageURL != nil && selectedDevice != nil && !isWriting
    }
    
    func selectImage() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.message = "选择要写入的磁盘镜像文件"
        
        var types: [UTType] = []
        for ext in SecurityUtils.supportedExtensions {
            if let utType = UTType(filenameExtension: ext) {
                types.append(utType)
            }
        }
        panel.allowedContentTypes = types.isEmpty ? [.data] : types
        
        if panel.runModal() == .OK {
            selectedImageURL = panel.url
        }
    }
    
    func refreshDevices() {
        deviceEnumerator.refreshDevices()
    }
    
    func startWrite() {
        guard let imageURL = selectedImageURL, let device = selectedDevice else { return }
        
        isWriting = true
        progress = 0
        bytesWritten = 0
        statusText = "准备写入..."
        writeStartTime = Date()
        
        imageWriter.write(
            imageURL: imageURL,
            to: device,
            verify: true,
            progressHandler: { [weak self] p, written, total in
                self?.progress = p
                self?.bytesWritten = written
                self?.totalBytes = total
                self?.statusText = "正在写入: \(FormatUtils.formatBytes(written)) / \(FormatUtils.formatBytes(total))"
                self?.updateETA(progress: p)
            },
            completionHandler: { [weak self] result in
                self?.isWriting = false
                switch result {
                case .success:
                    self?.statusText = "写入完成！"
                    self?.progress = 1.0
                    self?.showCompletionNotification()
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    self?.showError = true
                    self?.statusText = "失败: \(error.localizedDescription)"
                }
            }
        )
    }
    
    func cancelWrite() {
        imageWriter.cancel()
        isWriting = false
        statusText = "已取消"
    }
    
    private func updateImageSize() {
        guard let url = selectedImageURL else {
            imageSize = 0
            return
        }
        
        let isCompressed = CompressionHandler.isCompressed(url: url)
        
        if isCompressed {
            Task {
                if let size = await CompressionHandler.uncompressedSize(of: url) {
                    self.imageSize = size
                }
            }
        } else {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                imageSize = attributes[.size] as? UInt64 ?? 0
            } catch {
                imageSize = 0
            }
        }
    }
    
    private func updateETA(progress: Double) {
        guard progress > 0.01, let startTime = writeStartTime else {
            estimatedTimeRemaining = nil
            return
        }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let total = elapsed / progress
        estimatedTimeRemaining = total - elapsed
    }
    
    private func showCompletionNotification() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
        
        let content = UNMutableNotificationContent()
        content.title = "BitLoader"
        content.body = "镜像写入成功完成！"
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        center.add(request)
    }
    
    func confirmDeviceName(_ input: String) -> Bool {
        guard let device = selectedDevice else { return false }
        return input.trimmingCharacters(in: .whitespaces).lowercased() == device.bsdName.lowercased()
    }
}

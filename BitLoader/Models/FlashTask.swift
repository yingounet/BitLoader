import Foundation

enum FlashState: Equatable {
    case idle
    case preparing
    case writing(progress: Double, bytesWritten: UInt64, totalBytes: UInt64)
    case verifying(progress: Double)
    case completed
    case failed(String)
    
    static func == (lhs: FlashState, rhs: FlashState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.preparing, .preparing): return true
        case let (.writing(l1, l2, l3), .writing(r1, r2, r3)):
            return l1 == r1 && l2 == r2 && l3 == r3
        case let (.verifying(l), .verifying(r)): return l == r
        case (.completed, .completed): return true
        case let (.failed(l), .failed(r)): return l == r
        default: return false
        }
    }
    
    var progress: Double {
        switch self {
        case .idle: return 0
        case .preparing: return 0
        case .writing(let p, _, _): return p
        case .verifying(let p): return p
        case .completed: return 1.0
        case .failed: return 0
        }
    }
    
    var statusText: String {
        switch self {
        case .idle: return "就绪"
        case .preparing: return "准备中..."
        case .writing(_, let bytes, let total):
            return "正在写入: \(FormatUtils.formatBytes(bytes)) / \(FormatUtils.formatBytes(total))"
        case .verifying: return "正在验证..."
        case .completed: return "完成！"
        case .failed(let msg): return "失败: \(msg)"
        }
    }
}

@Observable
class FlashTask: Identifiable {
    let id = UUID()
    let imageURL: URL
    let targetDevice: USBDevice
    let createdAt: Date
    
    var state: FlashState = .idle
    var estimatedTimeRemaining: TimeInterval?
    
    init(imageURL: URL, targetDevice: USBDevice) {
        self.imageURL = imageURL
        self.targetDevice = targetDevice
        self.createdAt = Date()
    }
}

import Foundation

enum FormatUtils {
    static func formatBytes(_ bytes: UInt64) -> String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var value = Double(bytes)
        var unitIndex = 0
        
        while value >= 1024 && unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }
        
        if unitIndex == 0 {
            return String(format: "%.0f %@", value, units[unitIndex])
        } else {
            return String(format: "%.2f %@", value, units[unitIndex])
        }
    }
    
    static func formatDuration(_ seconds: TimeInterval) -> String {
        guard seconds > 0 else { return "--" }
        
        if seconds < 60 {
            return String(format: "%d 秒", Int(seconds))
        } else if seconds < 3600 {
            let minutes = Int(seconds) / 60
            let secs = Int(seconds) % 60
            return "\(minutes) 分 \(secs) 秒"
        } else {
            let hours = Int(seconds) / 3600
            let minutes = (Int(seconds) % 3600) / 60
            return "\(hours) 小时 \(minutes) 分"
        }
    }
    
    static func formatSpeed(_ bytesPerSecond: Double) -> String {
        let units = ["B/s", "KB/s", "MB/s", "GB/s"]
        var value = bytesPerSecond
        var unitIndex = 0
        
        while value >= 1024 && unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }
        
        return String(format: "%.2f %@", value, units[unitIndex])
    }
}

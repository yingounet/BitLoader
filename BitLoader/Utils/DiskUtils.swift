import Foundation

enum DiskUtils {
    static func getMountPoints(for bsdName: String) async -> [String] {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/diskutil")
        task.arguments = ["info", "-plist", bsdName]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            task.waitUntilExit()
            
            guard let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
                return []
            }
            
            var mountPoints: [String] = []
            if let mountPoint = plist["MountPoint"] as? String, !mountPoint.isEmpty {
                mountPoints.append(mountPoint)
            }
            if let apfsVolumes = plist["APFSVolumes"] as? [[String: Any]] {
                for volume in apfsVolumes {
                    if let mount = volume["MountPoint"] as? String, !mount.isEmpty {
                        mountPoints.append(mount)
                    }
                }
            }
            return mountPoints
        } catch {
            return []
        }
    }
    
    static func unmount(device bsdName: String) async throws {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/diskutil")
        task.arguments = ["unmountDisk", "force", bsdName]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        try task.run()
        task.waitUntilExit()
        
        if task.terminationStatus != 0 {
            let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "Unknown error"
            throw DiskError.unmountFailed(output)
        }
    }
    
    static func eject(device bsdName: String) async throws {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/diskutil")
        task.arguments = ["eject", bsdName]
        
        try task.run()
        task.waitUntilExit()
    }
}

enum DiskError: Error, LocalizedError {
    case unmountFailed(String)
    case deviceNotFound(String)
    case mountPointInUse(String)
    
    var errorDescription: String? {
        switch self {
        case .unmountFailed(let msg):
            return "无法卸载设备: \(msg)"
        case .deviceNotFound(let name):
            return "设备未找到: \(name)"
        case .mountPointInUse(let path):
            return "挂载点正在使用: \(path)"
        }
    }
}

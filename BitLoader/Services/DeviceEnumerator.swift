import Foundation
import Combine

@MainActor
@Observable
class DeviceEnumerator {
    var devices: [USBDevice] = []
    var isRefreshing = false
    
    private var timer: AnyCancellable?
    
    init() {
        refreshDevices()
        startMonitoring()
    }
    
    func startMonitoring() {
        timer = Timer.publish(every: 2.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshDevices()
            }
    }
    
    func refreshDevices() {
        guard !isRefreshing else { return }
        isRefreshing = true
        
        Task {
            let newDevices = await Self.enumerateDevices()
            devices = newDevices.sorted { $0.displayName < $1.displayName }
            isRefreshing = false
        }
    }
    
    private static func enumerateDevices() async -> [USBDevice] {
        var devices: [USBDevice] = []
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/diskutil")
        task.arguments = ["list", "-plist"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            task.waitUntilExit()
            
            guard let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
                  let allDisks = plist["AllDisksAndPartitions"] as? [[String: Any]] else {
                return devices
            }
            
            for diskInfo in allDisks {
                if let bsdName = diskInfo["DeviceIdentifier"] as? String {
                    if let device = getDeviceInfo(bsdName: bsdName) {
                        devices.append(device)
                    }
                }
            }
        } catch {
            print("Failed to enumerate devices: \(error)")
        }
        
        return devices
    }
    
    private static func getDeviceInfo(bsdName: String) -> USBDevice? {
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
                return nil
            }
            
            let isRemovable = plist["RemovableMedia"] as? Bool ?? false
            let isInternal = plist["Internal"] as? Bool ?? true
            let isWhole = plist["WholeDisk"] as? Bool ?? false
            
            guard isWhole else { return nil }
            guard isRemovable || !isInternal else { return nil }
            
            let size = plist["TotalSize"] as? UInt64 ?? 0
            let vendor = plist["VendorIdentifier"] as? String ?? ""
            let model = plist["DeviceModel"] as? String ?? plist["MediaName"] as? String ?? "USB Device"
            let mountPoint = plist["MountPoint"] as? String
            
            return USBDevice(
                bsdName: bsdName,
                devicePath: "/dev/\(bsdName)",
                rawDevicePath: "/dev/r\(bsdName)",
                vendor: vendor,
                model: model,
                size: size,
                isRemovable: isRemovable,
                isInternal: isInternal,
                mountPoint: mountPoint
            )
        } catch {
            return nil
        }
    }
}

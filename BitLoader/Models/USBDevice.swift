import Foundation

struct USBDevice: Identifiable, Equatable, Hashable {
    let id = UUID()
    let bsdName: String
    let devicePath: String
    let rawDevicePath: String
    let vendor: String
    let model: String
    let size: UInt64
    let isRemovable: Bool
    let isInternal: Bool
    let mountPoint: String?
    
    var displayName: String {
        if !vendor.isEmpty && !model.isEmpty {
            return "\(vendor) \(model) (\(FormatUtils.formatBytes(size)))"
        } else if !model.isEmpty {
            return "\(model) (\(FormatUtils.formatBytes(size)))"
        } else {
            return "\(bsdName) (\(FormatUtils.formatBytes(size)))"
        }
    }
    
    var isSafeToWrite: Bool {
        isRemovable && !isInternal
    }
    
    static func == (lhs: USBDevice, rhs: USBDevice) -> Bool {
        lhs.bsdName == rhs.bsdName &&
        lhs.devicePath == rhs.devicePath &&
        lhs.size == rhs.size
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(bsdName)
    }
}

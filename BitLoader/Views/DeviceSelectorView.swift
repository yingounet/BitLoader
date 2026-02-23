import SwiftUI

struct DeviceSelectorView: View {
    let devices: [USBDevice]
    @Binding var selectedDevice: USBDevice?
    let isWriting: Bool
    let onRefresh: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("步骤 2: 选择目标设备", systemImage: "2.circle.fill")
                    .font(.headline)
                
                Spacer()
                
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("刷新设备列表")
                .disabled(isWriting)
            }
            
            if devices.isEmpty {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("正在搜索 USB 设备...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.leading, 28)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("设备", selection: $selectedDevice) {
                        Text("请选择 USB 设备").tag(nil as USBDevice?)
                        ForEach(safeDevices) { device in
                            HStack {
                                Text(device.displayName)
                                if !device.isSafeToWrite {
                                    Text("⚠️")
                                }
                            }
                            .tag(device as USBDevice?)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .disabled(isWriting)
                    
                    if let device = selectedDevice {
                        DeviceInfoBadge(device: device)
                            .padding(.leading, 28)
                    }
                }
                .padding(.leading, 28)
            }
        }
    }
    
    private var safeDevices: [USBDevice] {
        devices
    }
}

struct DeviceInfoBadge: View {
    let device: USBDevice
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: device.isSafeToWrite ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(device.isSafeToWrite ? .green : .orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(device.isSafeToWrite ? "可安全写入" : "请谨慎选择")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(device.isSafeToWrite ? .green : .orange)
                
                Text(device.bsdName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if let mountPoint = device.mountPoint {
                HStack(spacing: 4) {
                    Image(systemName: "folder")
                        .font(.caption)
                    Text(mountPoint)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .background(device.isSafeToWrite ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
        .cornerRadius(6)
    }
}

#Preview {
    DeviceSelectorView(
        devices: [
            USBDevice(
                bsdName: "disk2",
                devicePath: "/dev/disk2",
                rawDevicePath: "/dev/rdisk2",
                vendor: "SanDisk",
                model: "Ultra",
                size: 16_000_000_000,
                isRemovable: true,
                isInternal: false,
                mountPoint: "/Volumes/USB"
            )
        ],
        selectedDevice: .constant(nil),
        isWriting: false,
        onRefresh: {}
    )
    .padding()
    .frame(width: 500)
}

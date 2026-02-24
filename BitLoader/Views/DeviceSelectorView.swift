import SwiftUI

struct DeviceSelectorView: View {
    @Environment(\.locale) private var locale
    let devices: [USBDevice]
    @Binding var selectedDevice: USBDevice?
    let isWriting: Bool
    let onRefresh: () -> Void

    @State private var isRefreshHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                iconView
                
                VStack(alignment: .leading, spacing: 6) {
                    if devices.isEmpty {
                        Text("searchingDevices")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Theme.Colors.textTertiary)
                        
                        HStack(spacing: 6) {
                            ProgressView()
                                .scaleEffect(0.6)
                                .frame(width: 16, height: 16)
                            Text("insertUSB")
                                .font(.subheadline)
                                .foregroundColor(Theme.Colors.textTertiary)
                        }
                    } else if let device = selectedDevice {
                        Text(device.displayName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Theme.Colors.textPrimary)
                            .lineLimit(1)
                        
                        HStack(spacing: 8) {
                            Text(device.bsdName)
                                .font(.subheadline)
                                .foregroundColor(Theme.Colors.textSecondary)
                            
                            if device.isSafeToWrite {
                                Label("safeToWrite", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(Theme.Colors.success)
                            } else {
                                Label("proceedWithCaution", systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundColor(Theme.Colors.warning)
                            }
                        }
                    } else {
                        devicePicker
                    }
                }
                
                Spacer()
                
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isRefreshHovered ? Theme.Colors.accent : Theme.Colors.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(isRefreshHovered ? Theme.Colors.accent.opacity(0.15) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .disabled(isWriting)
                .opacity(isWriting ? 0.4 : 1.0)
                .onHover { hovering in
                    isRefreshHovered = hovering
                }
                .help(localizedString("refreshDeviceList", locale: locale))
            }
            
            if !devices.isEmpty && selectedDevice == nil {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.textTertiary)
                    
                    Text("selectFromDropdown")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.textTertiary)
                }
            }
        }
        .cardStyle()
    }
    
    @ViewBuilder
    private var iconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.Colors.accent.opacity(0.15))
                .frame(width: Theme.Dimensions.iconSizeLarge, height: Theme.Dimensions.iconSizeLarge)
            
            Image(systemName: "externaldrive.fill")
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(Theme.Colors.accent)
        }
    }
    
    @ViewBuilder
    private var devicePicker: some View {
        Picker("device", selection: $selectedDevice) {
            Text("selectUSBDevice").tag(nil as USBDevice?)
            ForEach(safeDevices) { device in
                HStack {
                    Text(device.displayName)
                    if !device.isSafeToWrite {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Theme.Colors.warning)
                    }
                }
                .tag(device as USBDevice?)
            }
        }
        .pickerStyle(.menu)
        .tint(Theme.Colors.accent)
    }
    
    private var safeDevices: [USBDevice] {
        devices
    }
}

#Preview("有设备") {
    DeviceSelectorView(
        devices: [
            USBDevice(
                bsdName: "disk2",
                devicePath: "/dev/disk2",
                rawDevicePath: "/dev/rdisk2",
                vendor: "SanDisk",
                model: "Ultra",
                size: 32_000_000_000,
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
    .frame(width: 520)
    .background(Theme.Colors.background)
}

#Preview("无设备") {
    DeviceSelectorView(
        devices: [],
        selectedDevice: .constant(nil),
        isWriting: false,
        onRefresh: {}
    )
    .padding()
    .frame(width: 520)
    .background(Theme.Colors.background)
}

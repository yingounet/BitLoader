import SwiftUI

struct ConfirmationDialog: View {
    let device: USBDevice
    @Binding var isPresented: Bool
    @Binding var confirmationText: String
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    @FocusState private var isInputFocused: Bool
    
    var isConfirmed: Bool {
        confirmationText.trimmingCharacters(in: .whitespaces).lowercased() == device.bsdName.lowercased()
    }
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.orange)
                
                Text("确认写入操作")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            VStack(spacing: 16) {
                Text("此操作将**永久擦除**以下设备上的所有数据：")
                    .multilineTextAlignment(.center)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "externaldrive")
                            .foregroundStyle(.blue)
                        Text(device.displayName)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Image(systemName: "internaldrive")
                            .foregroundStyle(.secondary)
                        Text(device.bsdName)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("请输入设备名称以确认：")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    TextField(device.bsdName, text: $confirmationText)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .focused($isInputFocused)
                        .onAppear { isInputFocused = true }
                }
            }
            
            HStack(spacing: 16) {
                Button("取消") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.escape, modifiers: [])
                
                Button("确认写入") {
                    if isConfirmed {
                        onConfirm()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isConfirmed)
                .keyboardShortcut(.return, modifiers: [])
            }
        }
        .padding(24)
        .frame(width: 400)
    }
}

struct SimpleConfirmationDialog: View {
    let device: USBDevice
    @Binding var isPresented: Bool
    let onConfirm: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
            
            Text("确认擦除设备？")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("这将擦除「\(device.displayName)」上的所有数据。\n此操作无法撤销。")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 16) {
                Button("取消") {
                    isPresented = false
                }
                .keyboardShortcut(.escape, modifiers: [])
                
                Button("确认写入", role: .destructive) {
                    onConfirm()
                }
                .keyboardShortcut(.return, modifiers: [])
            }
        }
        .padding(24)
    }
}

#Preview {
    ConfirmationDialog(
        device: USBDevice(
            bsdName: "disk2",
            devicePath: "/dev/disk2",
            rawDevicePath: "/dev/rdisk2",
            vendor: "SanDisk",
            model: "Ultra",
            size: 16_000_000_000,
            isRemovable: true,
            isInternal: false,
            mountPoint: nil
        ),
        isPresented: .constant(true),
        confirmationText: .constant(""),
        onConfirm: {},
        onCancel: {}
    )
}

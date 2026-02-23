import SwiftUI

struct ContentView: View {
    @State private var viewModel = FlasherViewModel()
    @State private var showingConfirmation = false
    @State private var confirmationInput = ""
    
    var body: some View {
        VStack(spacing: 24) {
            headerView
            
            Divider()
            
            ImageSelectorView(
                selectedURL: $viewModel.selectedImageURL,
                imageSize: viewModel.imageSize,
                isWriting: viewModel.isWriting,
                onSelect: { viewModel.selectImage() }
            )
            
            Divider()
            
            DeviceSelectorView(
                devices: viewModel.devices,
                selectedDevice: $viewModel.selectedDevice,
                isWriting: viewModel.isWriting,
                onRefresh: { viewModel.refreshDevices() }
            )
            
            if viewModel.isWriting {
                Divider()
                WriteProgressView(
                    progress: viewModel.progress,
                    bytesWritten: viewModel.bytesWritten,
                    totalBytes: viewModel.totalBytes,
                    statusText: viewModel.statusText,
                    eta: viewModel.estimatedTimeRemaining,
                    onCancel: { viewModel.cancelWrite() }
                )
            }
            
            Spacer()
            
            actionButtonsSection
        }
        .padding(24)
        .frame(minWidth: 520, minHeight: 480)
        .alert("确认写入", isPresented: $showingConfirmation) {
            TextField("输入设备名称确认", text: $confirmationInput)
                .onAppear { confirmationInput = "" }
            Button("取消", role: .cancel) { }
            Button("确认写入", role: .destructive) {
                if viewModel.confirmDeviceName(confirmationInput) {
                    viewModel.startWrite()
                }
            }
            .disabled(!viewModel.confirmDeviceName(confirmationInput))
        } message: {
            if let device = viewModel.selectedDevice {
                Text("此操作将擦除 \(device.displayName) 上的所有数据。\n请输入设备名称「\(device.bsdName)」以确认。")
            }
        }
        .alert("错误", isPresented: $viewModel.showError) {
            Button("确定") { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    private var headerView: some View {
        HStack(spacing: 16) {
            Image(systemName: "externaldrive.fill")
                .font(.system(size: 40))
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("BitLoader")
                    .font(.system(size: 24, weight: .bold))
                Text("轻量级 USB 引导盘制作工具")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
    
    private var actionButtonsSection: some View {
        HStack {
            if viewModel.isWriting {
                Button("取消") {
                    viewModel.cancelWrite()
                }
                .keyboardShortcut(.escape, modifiers: [])
            }
            
            Spacer()
            
            Button(viewModel.isWriting ? "写入中..." : "开始写入") {
                if viewModel.canStartWrite {
                    showingConfirmation = true
                }
            }
            .keyboardShortcut(.return, modifiers: [])
            .disabled(!viewModel.canStartWrite || viewModel.isWriting)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
}

struct WriteProgressView: View {
    let progress: Double
    let bytesWritten: UInt64
    let totalBytes: UInt64
    let statusText: String
    let eta: TimeInterval?
    let onCancel: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("写入进度", systemImage: "3.circle.fill")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                SwiftUI.ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(.linear)
                    .scaleEffect(y: 1.5)
                
                HStack {
                    Text(statusText)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("\(Int(progress * 100))%")
                        .font(.system(.subheadline, design: .monospaced))
                        .fontWeight(.semibold)
                }
                
                if let eta = eta {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundStyle(.secondary)
                        Text("预计剩余时间: \(FormatUtils.formatDuration(eta))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.leading, 28)
        }
    }
}

#Preview {
    ContentView()
}

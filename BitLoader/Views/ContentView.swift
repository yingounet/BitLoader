import SwiftUI

struct ContentView: View {
    @Environment(\.locale) private var locale
    @State private var viewModel = FlasherViewModel()
    @State private var showingConfirmation = false
    @State private var confirmationInput = ""

    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            ScrollView {
                VStack(spacing: Theme.Dimensions.cardSpacing) {
                    HStack(spacing: Theme.Dimensions.cardSpacing) {
                        ImageSelectorView(
                            selectedURL: $viewModel.selectedImageURL,
                            imageSize: viewModel.imageSize,
                            isWriting: viewModel.isWriting,
                            onSelect: { viewModel.selectImage() }
                        )
                        
                        DeviceSelectorView(
                            devices: viewModel.devices,
                            selectedDevice: $viewModel.selectedDevice,
                            isWriting: viewModel.isWriting,
                            onRefresh: { viewModel.refreshDevices() }
                        )
                    }
                    
                    if viewModel.isWriting {
                        WriteProgressCard(
                            progress: viewModel.progress,
                            bytesWritten: viewModel.bytesWritten,
                            totalBytes: viewModel.totalBytes,
                            statusText: viewModel.statusText,
                            eta: viewModel.estimatedTimeRemaining,
                            onCancel: { viewModel.cancelWrite() }
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 24)
            }
            
            Spacer()
            
            actionButtonSection
        }
        .frame(minWidth: 780, minHeight: 520)
        .background(Theme.Colors.background)
        .preferredColorScheme(.dark)
        .alert(localizedString("confirmWriteTitle", locale: locale), isPresented: $showingConfirmation) {
            TextField(localizedString("enterDeviceName", locale: locale), text: $confirmationInput)
                .onAppear { confirmationInput = "" }
            Button("cancel", role: .cancel) { }
            Button("confirmWriteTitle", role: .destructive) {
                if viewModel.confirmDeviceName(confirmationInput) {
                    viewModel.startWrite()
                }
            }
            .disabled(!viewModel.confirmDeviceName(confirmationInput))
        } message: {
            if let device = viewModel.selectedDevice {
                Text("\(String(format: localizedString("confirmWriteMessage", locale: locale), device.displayName))\n\(String(format: localizedString("confirmWritePrompt", locale: locale), device.bsdName))")
            }
        }
        .alert(localizedString("error", locale: locale), isPresented: $viewModel.showError) {
            Button("confirm") { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    private var headerView: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.Colors.accent.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Image(systemName: "externaldrive.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(Theme.Colors.accent)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("app.name")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Text("app.tagline")
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 20)
        .background(
            Rectangle()
                .fill(Theme.Colors.backgroundSecondary)
                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
        )
    }
    
    private var actionButtonSection: some View {
        HStack {
            Spacer()
            
            if viewModel.isWriting {
                Button("cancelWrite") {
                    viewModel.cancelWrite()
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Theme.Colors.textSecondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Theme.Colors.cardBackground)
                .cornerRadius(12)
                .keyboardShortcut(.escape, modifiers: [])
            }
            
            Button {
                if viewModel.canStartWrite {
                    showingConfirmation = true
                }
            } label: {
                if viewModel.isWriting {
                    Text("writing")
                } else {
                    Text("startWrite")
                }
            }
            .buttonStyle(PrimaryButtonStyle(isEnabled: viewModel.canStartWrite && !viewModel.isWriting))
            .disabled(!viewModel.canStartWrite || viewModel.isWriting)
            .keyboardShortcut(.return, modifiers: [])
            
            Spacer()
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 24)
        .background(
            Rectangle()
                .fill(Theme.Colors.backgroundSecondary)
        )
    }
}

struct WriteProgressCard: View {
    let progress: Double
    let bytesWritten: UInt64
    let totalBytes: UInt64
    let statusText: String
    let eta: TimeInterval?
    let onCancel: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.Colors.accent.opacity(0.15))
                        .frame(width: Theme.Dimensions.iconSizeLarge, height: Theme.Dimensions.iconSizeLarge)
                    
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(Theme.Colors.accent)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("writingProgress")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    Text(statusText)
                        .font(.subheadline)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.Colors.accentLight)
                    
                    if let eta = eta {
                        Text(FormatUtils.formatDuration(eta))
                            .font(.caption)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Theme.Colors.cardBorder)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [Theme.Colors.accent, Theme.Colors.accentLight],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geometry.size.width * progress))
                }
            }
            .frame(height: 10)
            
            HStack {
                Text("\(FormatUtils.formatBytes(bytesWritten)) / \(FormatUtils.formatBytes(totalBytes))")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.textTertiary)
                
                Spacer()
            }
        }
        .padding(Theme.Dimensions.cardPadding)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.Dimensions.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadius)
                .stroke(Theme.Colors.accent.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Theme.Colors.accent.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

#Preview("主界面") {
    ContentView()
}

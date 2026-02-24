import SwiftUI

struct ImageSelectorView: View {
    @Binding var selectedURL: URL?
    let imageSize: UInt64
    let isWriting: Bool
    let onSelect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                iconView
                
                VStack(alignment: .leading, spacing: 6) {
                    if let url = selectedURL {
                        Text(url.lastPathComponent)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Theme.Colors.accentLight)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        
                        HStack(spacing: 8) {
                            Text(FormatUtils.formatBytes(imageSize))
                                .font(.subheadline)
                                .foregroundColor(Theme.Colors.textSecondary)
                            
                            if CompressionHandler.isCompressed(url: url) {
                                Text("compressedFile")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Theme.Colors.warning.opacity(0.2))
                                    .foregroundColor(Theme.Colors.warning)
                                    .cornerRadius(4)
                            }
                        }
                    } else {
                        Text("noFileSelected")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Theme.Colors.textTertiary)
                        
                        Text("clickToSelect")
                            .font(.subheadline)
                            .foregroundColor(Theme.Colors.textTertiary)
                    }
                }
                
                Spacer()
                
                Button(action: onSelect) {
                    Text("selectFile")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(isWriting ? Theme.Colors.disabled : Theme.Colors.accent)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .disabled(isWriting)
                .opacity(isWriting ? 0.6 : 1.0)
            }
            
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.textTertiary)
                
                Text("supportedFormats")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.textTertiary)
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
            
            Image(systemName: iconForFile)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(Theme.Colors.accent)
        }
    }
    
    private var iconForFile: String {
        guard let url = selectedURL else { return "opticaldisc" }
        return fileIcon(for: url)
    }
    
    private func fileIcon(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "iso", "img", "bin", "raw":
            return "opticaldisc"
        case "dmg":
            return "externaldrive"
        case "zip", "gz", "xz", "bz2":
            return "doc.zipper"
        default:
            return "doc"
        }
    }
}

#Preview("未选择") {
    ImageSelectorView(
        selectedURL: .constant(nil),
        imageSize: 0,
        isWriting: false,
        onSelect: {}
    )
    .padding()
    .frame(width: 520)
    .background(Theme.Colors.background)
}

#Preview("已选择") {
    ImageSelectorView(
        selectedURL: .constant(URL(fileURLWithPath: "/path/to/ubuntu-24.04-desktop-amd64.iso")),
        imageSize: 4_700_000_000,
        isWriting: false,
        onSelect: {}
    )
    .padding()
    .frame(width: 520)
    .background(Theme.Colors.background)
}

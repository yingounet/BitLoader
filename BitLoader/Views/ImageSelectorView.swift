import SwiftUI

struct ImageSelectorView: View {
    @Binding var selectedURL: URL?
    let imageSize: UInt64
    let isWriting: Bool
    let onSelect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("步骤 1: 选择镜像文件", systemImage: "1.circle.fill")
                .font(.headline)
            
            HStack(spacing: 12) {
                TextField("未选择文件", text: .constant(selectedURL?.path ?? ""))
                    .textFieldStyle(.roundedBorder)
                    .disabled(true)
                
                Button("选择...") {
                    onSelect()
                }
                .disabled(isWriting)
                .buttonStyle(.bordered)
            }
            
            if let url = selectedURL {
                HStack(spacing: 8) {
                    Image(systemName: fileIcon(for: url))
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(url.lastPathComponent)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack(spacing: 8) {
                            Text(FormatUtils.formatBytes(imageSize))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            if CompressionHandler.isCompressed(url: url) {
                                Text("压缩文件")
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.2))
                                    .foregroundColor(.orange)
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                .padding(.leading, 28)
            } else {
                HStack {
                    Image(systemName: "doc.badge.plus")
                        .foregroundStyle(.tertiary)
                    Text("支持 ISO, IMG, DMG, ZIP, GZ, XZ 等格式")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.leading, 28)
            }
        }
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

#Preview {
    ImageSelectorView(
        selectedURL: .constant(nil),
        imageSize: 0,
        isWriting: false,
        onSelect: {}
    )
    .padding()
    .frame(width: 500)
}

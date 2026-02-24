import SwiftUI

struct ProgressPanelView: View {
    let progress: Double
    let bytesWritten: UInt64
    let totalBytes: UInt64
    let statusText: String
    let phase: String
    let eta: TimeInterval?
    let speed: Double?
    let onCancel: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(phase, systemImage: "3.circle.fill")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.2))
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress)
                    }
                }
                .frame(height: 8)
                
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(statusText)
                            .font(.subheadline)
                        
                        if let speed = speed {
                            HStack(spacing: 4) {
                                Text("speed")
                                Text(": \(FormatUtils.formatSpeed(speed))")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(Int(progress * 100))%")
                            .font(.system(.title2, design: .monospaced))
                            .fontWeight(.bold)
                        
                        if let eta = eta {
                            Text(FormatUtils.formatDuration(eta))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.leading, 28)
            
            HStack {
                Spacer()
                
                Button("cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(nsColor: .windowBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}

struct CompactProgressView: View {
    let progress: Double
    let statusText: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(statusText)
                    .font(.subheadline)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.system(.subheadline, design: .monospaced))
                    .fontWeight(.semibold)
            }
            
            SwiftUI.ProgressView(value: progress, total: 1.0)
                .progressViewStyle(.linear)
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        ProgressPanelView(
            progress: 0.65,
            bytesWritten: 6_500_000_000,
            totalBytes: 10_000_000_000,
            statusText: "正在写入...",
            phase: "写入中",
            eta: 180,
            speed: 45_000_000,
            onCancel: {}
        )
        .frame(width: 400)
        
        CompactProgressView(progress: 0.35, statusText: "正在写入...")
            .frame(width: 400)
    }
    .padding()
}

import SwiftUI

@main
struct BitLoaderApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 520, minHeight: 480)
        }
        .windowStyle(.automatic)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
            
            CommandGroup(after: .appInfo) {
                Button("检查更新...") {
                    checkForUpdates()
                }
                .keyboardShortcut("U", modifiers: .command)
            }
            
            CommandMenu("工具") {
                Button("刷新设备列表") {
                    NotificationCenter.default.post(name: .refreshDevices, object: nil)
                }
                .keyboardShortcut("R", modifiers: .command)
                
                Divider()
                
                Button("校验镜像文件...") {
                    NotificationCenter.default.post(name: .verifyImage, object: nil)
                }
                .keyboardShortcut("V", modifiers: .command)
            }
        }
        
        Settings {
            SettingsView()
        }
    }
    
    private func checkForUpdates() {
        if let url = URL(string: "https://github.com/yingouqlj/bitloader/releases") {
            NSWorkspace.shared.open(url)
        }
    }
}

extension Notification.Name {
    static let refreshDevices = Notification.Name("refreshDevices")
    static let verifyImage = Notification.Name("verifyImage")
}

struct SettingsView: View {
    @AppStorage("verifyAfterWrite") private var verifyAfterWrite = true
    @AppStorage("showConfirmation") private var showConfirmation = true
    @AppStorage("autoEject") private var autoEject = false
    
    var body: some View {
        TabView {
            GeneralSettingsView(
                verifyAfterWrite: $verifyAfterWrite,
                showConfirmation: $showConfirmation,
                autoEject: $autoEject
            )
            .tabItem {
                Label("通用", systemImage: "gear")
            }
            
            AboutSettingsView()
                .tabItem {
                    Label("关于", systemImage: "info.circle")
                }
        }
        .frame(width: 400, height: 300)
    }
}

struct GeneralSettingsView: View {
    @Binding var verifyAfterWrite: Bool
    @Binding var showConfirmation: Bool
    @Binding var autoEject: Bool
    
    var body: some View {
        Form {
            Section("写入选项") {
                Toggle("写入后验证数据", isOn: $verifyAfterWrite)
                Toggle("写入前显示确认对话框", isOn: $showConfirmation)
                Toggle("写入完成后自动弹出设备", isOn: $autoEject)
            }
            
            Section("安全") {
                Text("此应用需要管理员权限才能写入磁盘。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "externaldrive.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)
            
            Text("BitLoader")
                .font(.title)
                .fontWeight(.bold)
            
            Text("版本 1.0.0")
                .foregroundStyle(.secondary)
            
            Text("轻量级 USB 引导盘制作工具")
                .font(.subheadline)
            
            Divider()
            
            VStack(spacing: 8) {
                Link("GitHub", destination: URL(string: "https://github.com/yingouqlj/bitloader")!)
                Link("报告问题", destination: URL(string: "https://github.com/yingouqlj/bitloader/issues")!)
            }
            
            Spacer()
            
            Text("© 2026 BitLoader")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
    }
}

#Preview {
    SettingsView()
}

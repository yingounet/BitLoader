import SwiftUI

@main
struct BitLoaderApp: App {
    var body: some Scene {
        WindowGroup {
            MainWindowContent()
                .frame(minWidth: 780, minHeight: 520)
        }
        .windowStyle(.automatic)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
            
            CommandGroup(after: .appInfo) {
                Button(localizedString("checkUpdates", locale: LocalizationManager.shared.locale)) {
                    checkForUpdates()
                }
                .keyboardShortcut("U", modifiers: .command)
            }
            
            CommandMenu(localizedString("menu.tools", locale: LocalizationManager.shared.locale)) {
                Button(localizedString("refreshDeviceList", locale: LocalizationManager.shared.locale)) {
                    NotificationCenter.default.post(name: .refreshDevices, object: nil)
                }
                .keyboardShortcut("R", modifiers: .command)
                
                Divider()
                
                Button(localizedString("verifyImage", locale: LocalizationManager.shared.locale)) {
                    NotificationCenter.default.post(name: .verifyImage, object: nil)
                }
                .keyboardShortcut("V", modifiers: .command)
            }
        }
        
        Settings {
            SettingsWindowContent()
        }
    }
}

/// 主窗口内容：观察 LocalizationManager，切换语言时自动刷新界面。
private struct MainWindowContent: View {
    private var localization = LocalizationManager.shared

    var body: some View {
        ContentView()
            .environment(\.locale, localization.locale)
            .id(localization.currentLanguage.rawValue)
    }
}

/// 设置窗口内容：注入当前语言，使设置页内的 Text("key") 等随语言切换。
private struct SettingsWindowContent: View {
    private var localization = LocalizationManager.shared

    var body: some View {
        SettingsView()
            .environment(\.locale, localization.locale)
            .id(localization.currentLanguage.rawValue)
    }
}

extension BitLoaderApp {
    private func checkForUpdates() {
        if let url = URL(string: "https://github.com/yingounet/BitLoader/releases") {
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
                Label("settings.general", systemImage: "gear")
            }
            
            AboutSettingsView()
                .tabItem {
                    Label("settings.about", systemImage: "info.circle")
                }
        }
        .frame(width: 400, height: 300)
        .preferredColorScheme(.dark)
    }
}

struct GeneralSettingsView: View {
    @Binding var verifyAfterWrite: Bool
    @Binding var showConfirmation: Bool
    @Binding var autoEject: Bool
    @Bindable private var localization = LocalizationManager.shared

    var body: some View {
        Form {
            Section("writeOptions") {
                Toggle("verifyAfterWrite", isOn: $verifyAfterWrite)
                Toggle("showConfirmation", isOn: $showConfirmation)
                Toggle("autoEject", isOn: $autoEject)
            }
            
            Section("language.display") {
                Picker(selection: $localization.currentLanguage) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                } label: {
                    Label("language.display", systemImage: "globe")
                }
            }
            
            Section("security") {
                Text("adminRequired")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct AboutSettingsView: View {
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.Colors.accent.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "externaldrive.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(Theme.Colors.accent)
            }
            
            Text("app.name")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Theme.Colors.textPrimary)
            
            Text("\(localizedString("version", locale: locale)) 1.0.0")
                .foregroundColor(Theme.Colors.textSecondary)
            
            Text("app.tagline")
                .font(.subheadline)
                .foregroundColor(Theme.Colors.textSecondary)
            
            Divider()
                .background(Theme.Colors.cardBorder)
            
            VStack(spacing: 8) {
                Link(destination: URL(string: "https://github.com/yingounet/BitLoader")!) {
                    Text("github")
                }
                Link(destination: URL(string: "https://github.com/yingounet/BitLoader/issues")!) {
                    Text("reportIssue")
                }
            }
            
            Spacer()
            
            Text("app.copyright")
                .font(.caption)
                .foregroundColor(Theme.Colors.textTertiary)
        }
        .padding()
        .background(Theme.Colors.background)
    }
}

#Preview {
    SettingsView()
}

# BitLoader

轻量级 macOS USB 引导盘制作工具。

## 项目结构

```
bitloader/BitLoader/
├── BitLoaderApp.swift          # App 入口
├── Info.plist                  # 应用配置
├── Assets.xcassets/            # 资源文件
├── Models/                     # 数据模型
│   ├── USBDevice.swift
│   ├── FlashTask.swift
│   └── AppState.swift
├── ViewModels/                 # 视图模型
│   └── FlasherViewModel.swift
├── Services/                   # 核心服务
│   ├── DeviceEnumerator.swift
│   ├── ImageWriter.swift
│   └── CompressionHandler.swift
├── Views/                      # UI 视图
│   ├── ContentView.swift
│   ├── ImageSelectorView.swift
│   ├── DeviceSelectorView.swift
│   ├── ProgressPanelView.swift
│   └── ConfirmationDialog.swift
└── Utils/                      # 工具类
    ├── FormatUtils.swift
    ├── DiskUtils.swift
    └── SecurityUtils.swift
```

## 在 Xcode 中创建项目

1. 打开 Xcode，选择 **File → New → Project**
2. 选择 **macOS → App**
3. 配置项目：
   - **Product Name**: `BitLoader`
   - **Team**: 你的开发者账号
   - **Organization Identifier**: `net.yingou`
   - **Bundle Identifier**: `net.yingou.bitloader`
   - **Interface**: `SwiftUI`
   - **Language**: `Swift`
   - **Storage**: `None`
4. 选择保存位置为 `bitloader/` 目录（与现有源码同级的父目录）
5. 创建后，删除 Xcode 自动生成的文件：
   - `BitLoaderApp.swift`
   - `ContentView.swift`
   - `Assets.xcassets/`
   - `Info.plist`（如有）
6. 将现有源码文件拖入 Xcode 项目：
   - 右键点击项目导航中的 `BitLoader` 文件夹
   - 选择 **Add Files to "BitLoader"...**
   - 选择 `BitLoader/` 目录下的所有子文件夹
   - 确保勾选 **Copy items if needed** 和 **Create groups**
7. 设置 Info.plist：
   - 选择项目 → Target → Build Settings
   - 搜索 `Info.plist`
   - 将 `Info.plist File` 设置为 `BitLoader/Info.plist`

## 依赖

- macOS 13.0+
- Xcode 15.0+
- Swift 5.9+

## 功能

- USB 设备自动检测与枚举
- 支持 ISO/IMG/DMG 镜像
- 支持压缩镜像（GZ/XZ/ZIP）
- 写入进度实时显示
- 写入前安全确认
- 写入后数据验证

## 构建

```bash
# Debug
xcodebuild -project BitLoader.xcodeproj -scheme BitLoader -configuration Debug

# Release
xcodebuild -project BitLoader.xcodeproj -scheme BitLoader -configuration Release
```

## 许可证

MIT License
